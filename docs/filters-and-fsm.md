# Guide

## Filters

A filter is plain data. You call `check(msg)` on it inside your handler, and the
conditions inside one filter are ANDed together. For OR, or anything more
involved, just use ordinary `if` and `elif`.

| Factory | Matches when |
| --- | --- |
| `Command("start")` | text is `/start`, including `/start@bot` and `/start arg` |
| `Commands(["a", "b"])` | text is `/a` or `/b` |
| `Text("hello")` | text equals `hello` |
| `StartsWith("/pay")` | text starts with `/pay` |
| `EndsWith("?")` | text ends with `?` |
| `Contains("http")` | text contains `http` |
| `ContentType("photo")` | the content type is a photo |
| `ChatType("private")` | the chat is private |

```mojo
from mojogram import Command, ContentType, ChatType
from mojogram.types import Message

def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("started")
    elif ContentType("photo").check(msg):
        _ = ctx.reply("nice photo")
    elif ChatType("private").check(msg) and msg.from_user().id() == 12345678:
        _ = ctx.answer("hello admin")
```

## Finite state machine

State and scratch data live per chat in a `StateStore`, shared across the whole
dispatcher. Every handler's `ctx.state` is bound to the current chat.

```mojo
ctx.state.set_state("awaiting_email")
var s = ctx.state.get_state()             # "" if none
ctx.state.set_data("email", "x@y.z")
var e = ctx.state.get_data("email")       # "" by default
# drop state and data for this chat
ctx.state.clear()
```

A two step form by hand:

```mojo
def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        ctx.state.set_state("name")
        _ = ctx.answer("What's your name?")
        return
    var st = ctx.state.get_state()
    if st == "name":
        ctx.state.set_data("name", msg.text())
        ctx.state.set_state("age")
        _ = ctx.answer("How old are you?")
    elif st == "age":
        var name = ctx.state.get_data("name")
        ctx.state.clear()
        _ = ctx.answer("Done, " + name + ".")
```

`StateStore` is in memory. To persist, write a struct with the same methods over
Redis or a database.

## Keyboards

```mojo
from mojogram import InlineKeyboard, ReplyKeyboard

var kb = InlineKeyboard()
kb.button("Open", url="https://example.com")        # url button
# callback button
kb.button("Vote", "vote:up")
# red (Bot API 9.4)
kb.button("Delete", "del", style="danger")
# opens a Mini App
kb.button("Mini app", web_app="https://example.com")
_ = ctx.answer("pick one", "", kb.as_markup())
```

Reply keyboards work the same way, and support `request_contact` and
`request_location`. Button colors come from the `style` argument: `danger` is
red, `primary` is blue, `success` is green. They render on Telegram clients on
Bot API 9.4 and later.

## Concurrency

Mojo 1.0 has no threads, but it does have `parallelize`, a parallel for over a
thread pool with no GIL. mojogram uses it for optional parallel processing of a
poll batch, so one slow handler doesn't hold up the rest.

```mojo
from std.algorithm import parallelize

var ups = dp.poll()
var n = ups.len()

@parameter
def worker(i: Int):
    try:
        # pass i as the slot
        handle(dp.context(Update(ups.at(i)), i))
    except e:
        print(e)

parallelize[worker](n)
```

Passing the index as the slot keeps each worker's HTTP temp files separate. FSM
state is safe to touch from parallel workers too, since the store is guarded by a
spinlock. For sending under Telegram's flood limits, wrap your sends with a
`RateLimiter`.

## Webhooks

For push instead of polling, run a `WebhookServer`. Terminate TLS at nginx or an
ngrok tunnel and point it at the server.

```mojo
var srv = WebhookServer(Bot(token), 8080, secret_token="my-secret")
while True:
    handle(srv.context(srv.next()))
```

The server validates Telegram's secret token header. It handles one connection
at a time, so for throughput run several processes behind nginx. See `deploy/`
for a ready compose file.
