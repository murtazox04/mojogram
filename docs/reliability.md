# Reliability and concurrency

What keeps a bot alive in production: not falling over on a flaky network, not
tripping Telegram's flood limits, and using the cores you have when a batch of
updates piles up.

## Retries are automatic

Every API call goes through a retry layer. Network errors, HTTP 5xx, and 429
rate-limits are retried with a short backoff; a 429 honours the `retry_after`
value Telegram sends rather than guessing. Permanent client errors (400, 401,
403, 404) raise straight away, because retrying them never helps.

You don't wire any of this up. It's on by default for both JSON calls and file
uploads. A response that isn't even valid JSON (a curl hiccup, a truncated body)
is treated as a transient failure, so a single bad read doesn't crash the call.

## Handling errors

API calls raise on permanent failure, so wrap the ones that can fail and decide
what to do. In a poll loop, catch per update so one bad handler doesn't kill the
process:

```mojo
while True:
    var ups = dp.poll()
    for i in range(ups.len()):
        try:
            handle(dp.context(Update(ups.at(i))))
        except e:
            print("handler error:", e)     # log and keep serving
```

The error message carries Telegram's code and description, for example
`Telegram API error [400] on sendMessage: chat not found`, so a log line is
usually enough to see what went wrong.

## Rate limiting

Telegram caps you at roughly 30 messages a second overall, and about one a
second to a single chat. Burst past that and you get 429s. The retry layer
absorbs the occasional 429, but if you're sending in a tight loop, throttle on
your side with a `RateLimiter`. It's a token bucket: `acquire()` blocks just long
enough to stay under the rate.

```mojo
from mojogram import RateLimiter

var limiter = RateLimiter(rate=25.0, burst=25.0)   # 25 msg/s, a little under the cap

for chat_id in chat_ids:
    limiter.acquire()                               # waits if we're going too fast
    _ = bot.send_message(chat_id, "broadcast")
```

It's thread-safe (an `Atomic` spinlock inside), so you can share one limiter
across parallel workers.

## Parallel batches

Mojo 1.0 has no threads, but it has `parallelize`, a parallel-for over a thread
pool with no GIL. mojogram uses it to process a poll batch across cores, so one
slow handler doesn't hold up the rest. It's opt-in; the default loop is
sequential.

```mojo
from std.algorithm import parallelize

var ups = dp.poll()
var n = ups.len()

@parameter
def worker(i: Int):
    try:
        handle(dp.context(Update(ups.at(i)), i))   # pass i as the slot
    except e:
        print(e)

parallelize[worker](n)
```

Two things make this safe. Passing the worker index as the slot gives each
worker its own HTTP temp files, so concurrent `curl` calls don't clobber each
other. And the FSM store guards its maps with a spinlock, so workers touching
shared state can't corrupt it. The lock is held only for the microseconds of a
Dict op, never across a handler's network call, so the parallelism is real. It's
been stress-tested at 500 distinct-key writes (none lost) and 1000 contended
read-modify-writes (exact).

One caveat: the store protects against torn state, but a get-then-set for the
same chat is still two operations. That's fine for one-update-per-chat FSM flows,
which is the normal case.

## Speaking more than one language

`I18n` is a small translation catalog. Add your strings per locale, then look
them up with a fallback: the requested locale, then the default locale, then the
fallback text you pass in.

```mojo
from mojogram import I18n

var i18n = I18n(default_locale="en")
i18n.add("en", "hello", "Hello")
i18n.add("uz", "hello", "Salom")

var lang = msg.from_user().language_code()    # "uz", "en", ...
_ = ctx.answer(i18n.t(lang, "hello", "Hello"))
```

`language_code()` comes straight off the user, so you can pick a locale per
person without asking them.
