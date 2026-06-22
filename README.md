<p align="center">
  <img src="docs/assets/banner.png" alt="mojogram, a Telegram Bot Framework for Mojo" width="760">
</p>

A Telegram Bot framework written in pure Mojo. No Python anywhere. It compiles
clean and passes its test suite on Mojo 1.0.0b2 (MAX).

It leans on what Mojo is good at. Static types and value semantics, and parallel
work that actually runs in parallel. It isn't a port of a dynamic-language
framework. A couple of times the language wouldn't let me build something the
way I first wanted, so I changed the approach instead of forcing it.

```mojo
from std.os import getenv
from mojogram import Bot, Poller, Command, Update, UpdateContext

def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("Hello from pure Mojo")
    else:
        _ = ctx.answer(msg.text())

def main() raises:
    var dp = Poller(Bot(getenv("BOT_TOKEN")))
    while True:
        var ups = dp.poll()
        for i in range(ups.len()):
            handle(dp.context(Update(ups.at(i))))
```

## Status

The package builds with no errors and no warnings under `pixi run build`. The
core logic has runtime unit tests (`pixi run test`) covering JSON parse and
escape, typed accessors, filters, `Params`, and the keyboard builders, each
asserted against exact expected output. Every example compiles and links.

The concurrency path is stress-tested (`tests/test_concurrency.mojo`): the
`Atomic` spinlock holds under 500 plus 1000 parallel writes. The JSON parser has
its own adversarial suite (`tests/test_json_edge.mojo`) with 17 cases including
emoji, surrogate pairs, large negative chat ids, scientific notation, deep
nesting, escapes, and unicode keys.

Webhooks were tested over a real ngrok HTTPS tunnel, with public TLS hitting the
Mojo socket server and a 200 coming back. They also ran behind an nginx
round-robin across two Docker processes. On benchmarks, JSON parse plus access
runs at about 2.4 µs/op, roughly 420K updates a second. The per-request
transport floor is about 2.3 ms from spawning curl, comfortably under Telegram's
~33 ms/msg budget.

Live long-polling and replies need a real `BOT_TOKEN`, since the transport is
just the system `curl`.

## Why these design choices

Mojo is static and has no Python runtime, so three pieces are built from scratch:

| Need | Approach | File |
| ---- | -------- | ---- |
| JSON parse and serialize | Hand-written arena DOM plus escaping | `json.mojo` |
| HTTPS, with no native TLS | The system `curl` via `subprocess.run` | `http.mojo` |
| Shared mutable FSM state | `ArcPointer[Dict]` | `fsm.mojo` |

There is no decorator-registered handler table, because Mojo cannot store
heterogeneous function values in a collection (`def(...)` is an existential
trait, not a concrete `Movable`). So you pull updates and call your own handler
in a plain loop. It's faster that way (nothing to box or dispatch through) and
the compiler still type-checks all of it. Routing is normal `if`/`elif` over the
data-only filters.

## Features

- Bot with around 60 typed API methods; everything else goes through
  `call(method, Params)`.
- Poller doing long-poll with offset management, `allowed_updates`, and a
  per-update FSM context.
- Typed updates over the JSON DOM: `Update`, `Message`, `CallbackQuery`, `Chat`,
  `User`, `InlineQuery`, `Poll`, `PreCheckoutQuery`, `ChatMemberUpdated`, and so on.
- Filters (`Command(s)`, `Text`, `StartsWith`, `EndsWith`, `Contains`,
  `ContentType(s)`, `ChatType`) composed with plain `if`/`elif` in your handler.
- FSM with per-chat state and data, shared via `ArcPointer`, made thread-safe
  with a spinlock.
- Inline and reply keyboard builders: `web_app`, the `style` colors from Bot API
  9.4, `icon_custom_emoji_id`, `request_contact`/`request_location`, `force_reply`.
- Polls and reactions: `send_poll`/quiz, `set_message_reaction`,
  `edit_message_media`.
- Payments and Telegram Stars: `send_invoice`, `create_invoice_link`,
  `refund_star_payment`, `get_my_star_balance`, `answer_shipping_query`.
- Inline mode: `inline_article`/`inline_photo`/`inline_results` builders.
- Files: multipart upload (`send_photo_file` and friends), `download_file`,
  `send_media_group`.
- Webhook server with secret-token validation; scale it behind nginx.
- i18n through an `I18n` translation catalog with locale fallback.
- Transport that retries with backoff on network and 5xx errors and honours the
  429 `retry_after`.
- Rate limiting via a `RateLimiter` token bucket, opt-in.
- Formatting helpers, `escape_html` and `escape_markdown` (MarkdownV2).
- Optional parallel batch processing via `parallelize`, with no GIL, and a
  thread-safe transport and FSM behind it.
- Works with pixi (`pixi.toml`) or uv (`pyproject.toml`).

## Install

Mojo 1.0 ships on Modular's nightly index. Either toolchain manager works.

Option A, pixi (uses `pixi.toml`):
```bash
curl -fsSL https://pixi.sh/install.sh | bash && source ~/.zshrc
pixi install                     # MAX/Mojo from conda.modular.com/max
```

Option B, uv (uses `pyproject.toml`, Python 3.11+):
```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync --python 3.11            # mojo 1.0 from whl.modular.com/nightly
uv run mojo --version
```

Don't use the stable PyPI index. It ships Mojo 0.26.x with the old `fn`/`alias`
syntax, which won't compile mojogram. `pyproject.toml` pins the nightly index for
you.

You need `curl` on `PATH`, which is the default on macOS and every mainstream
Linux. That is the HTTP transport.

## Run

```bash
export BOT_TOKEN="123456:your-token"
pixi run echo        # echo bot
pixi run form        # FSM form bot
pixi run keyboard    # inline keyboard + callbacks
pixi run parallel    # opt-in parallel batch processing
pixi run webhook     # webhook server (pair with ngrok/nginx)
pixi run test        # runtime self-checks (parser/filters/builders)
pixi run conc        # concurrency stress test (spinlock)
pixi run build       # precompile to mojogram.mojoc
```

With uv the same tasks are `uv run mojo run -I . examples/echo_bot.mojo` and so
on. To use mojogram in your own file, add the package to the import path:
`mojo run -I /path/to/mojogram yourbot.mojo`.

## Concurrency (optional)

Mojo 1.0 has no `threading` or `Lock` yet. The primitive you do get is
`parallelize`, a thread-pool parallel-for with no GIL, so it is real parallelism.
mojogram uses it for opt-in parallel batch processing: each poll batch fans out
so a slow handler doesn't block the others.

Measured on this machine with 8 I/O-bound calls: sequential 1735 ms, parallel
438 ms, about 4x.

```mojo
var ups = dp.poll()
var n = ups.len()

@parameter
def worker(i: Int):
    try:
        handle(dp.context(Update(ups.at(i)), i))   # slot = i
    except e:
        print(e)

parallelize[worker](n)
```

The default loop is sequential (`echo_bot.mojo`); parallel is opt-in
(`examples/parallel_bot.mojo`). Passing the worker index as `slot` gives each
worker its own HTTP temp files, so concurrent `curl` calls don't collide. On the
FSM side, `StateStore` guards its maps with an `Atomic` spinlock (`std.atomic`),
so parallel workers can touch shared state without corrupting it. It is
stress-tested at 500 concurrent distinct-key writes with nothing lost, plus 1000
contended read-modify-writes under one lock coming out exact. The lock is held
only for the microseconds of the Dict op, never across a handler's I/O, so
parallelism survives. It guarantees no torn state; a get-then-set sequence for
the same chat is still two ops, which is fine for one-set-per-update FSM flows.

### Webhooks

mojogram ships a pure-Mojo HTTP server (`WebhookServer`, libc sockets via FFI).
Terminate TLS at ngrok or nginx and forward to it:

```mojo
var srv = WebhookServer(Bot(token), 8080)
while True:
    handle(srv.context(srv.next()))   # replies 200 immediately, returns the Update
```

It was tested over a real ngrok HTTPS tunnel, public TLS into the tunnel into the
Mojo server, parsed update, 200 back, which is the exact path Telegram uses. It
handles one connection at a time, since Mojo has no threads, so for throughput
run N processes behind nginx. See `examples/webhook_bot.mojo`.

## Not included (on purpose)

- Async dispatch. Mojo's async runtime isn't ready, so polling is synchronous and
  concurrency comes from `parallelize`.
- In-process webhook concurrency. The server is single-connection with no threads;
  scale out with N processes behind nginx.
- Decorator registry and stored custom-predicate filters. Neither is expressible
  in static Mojo (see above). Use the direct loop with `if`/`elif`.
- The newest exotic API families: gifts, checklists, rich messages, business
  accounts, stories, guest mode, managed bots (Bot API 9.x to 10.x) aren't typed.
  They're niche and still reachable through the generic `call()`:
  ```mojo
  var p = Params()
  p.put_int("chat_id", chat_id)
  p.put_raw("tasks", tasks_json)
  _ = bot.call("sendChecklist", p)   # any of the 120+ methods
  ```

## Layout

```
mojogram/
├── mojogram/
│   ├── __init__.mojo   # public exports
│   ├── json.mojo       # pure-Mojo JSON parser + serializer (arena DOM)
│   ├── http.mojo       # curl-via-subprocess transport
│   ├── client.mojo     # Session, request envelope + retry/429
│   ├── bot.mojo        # Bot, typed API methods + call()
│   ├── types.mojo      # Update/Message/CallbackQuery/... over JSON
│   ├── server.mojo     # WebhookServer (libc sockets via FFI)
│   ├── filters.mojo    # data filters (Match + factories)
│   ├── fsm.mojo        # Spinlock-guarded FSM
│   ├── sync.mojo       # Spinlock (Atomic-based)
│   ├── ratelimit.mojo  # RateLimiter (token bucket)
│   ├── format.mojo     # escape_html / escape_markdown
│   ├── inline.mojo     # inline-query result builders
│   ├── i18n.mojo       # translation catalog
│   ├── keyboards.mojo  # keyboard builders
│   ├── context.mojo    # UpdateContext
│   └── dispatcher.mojo # Poller, poll loop + context builder
├── examples/           # echo, fsm, keyboard, parallel, webhook
├── tests/              # test_core, test_concurrency, test_json_edge
├── deploy/             # Dockerfile + nginx.conf + docker-compose (scale-out)
└── pixi.toml
```

## Compatibility and production notes

Mojo is still pre-1.0. The language and stdlib change between nightlies (for
example the `MutAnyOrigin` deprecation from b2 to b3), and mojogram tracks that
moving target. CI (`.github/workflows/ci.yml`) builds and runs all the test
suites on every push, on pixi and uv, macOS and Linux, so any breakage from a
Mojo change shows up right away. It's been tested on Mojo 1.0.0b2 under pixi and
1.0.0b3 under uv. For reproducible deploys, commit your `pixi.lock` or `uv.lock`.

The HTTP transport needs `curl` on `PATH`. Call `curl_available()` at startup if
you want a clear error instead of a late failure. There is no persistent
connection pool: each request spawns curl, about 2.3 ms. That's negligible for
polling, where the long-poll wait dominates, and it stays inside Telegram's ~33
ms/msg budget. A native pool will have to wait for Mojo's own TLS and HTTP.

The webhook server is single-connection because Mojo has no threads. Scale out
with the tested `deploy/` stack (nginx plus N processes); see
`deploy/docker-compose.yml`.

On load, 500k sequential plus 200k parallel parses run without crashing
(`tests/test_load.mojo`), at roughly 450k parses a second sequential and 1.5M
parallel.

## Docs

The full documentation is a site built from `docs/` with MkDocs Material, in
English and Uzbek, and it deploys to GitHub Pages on every push (see
`.github/workflows/docs.yml`):

https://murtazox04.github.io/mojogram/

Build it locally with `pip install -r requirements-docs.txt` then `mkdocs serve`.
The pages: [Home](docs/index.md), [Install](docs/install.md),
[Quickstart](docs/getting-started.md), [Guide](docs/filters-and-fsm.md),
[API](docs/api-reference.md), [Architecture](docs/architecture.md).

## License

[MIT](LICENSE) © Murtazo Xurramov
