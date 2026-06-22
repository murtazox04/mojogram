![mojogram, a Telegram Bot framework for Mojo](assets/banner.png){ width="640" }

# mojogram

mojogram is a Telegram Bot framework written entirely in Mojo. There is no Python
in it. The JSON parser is hand written, HTTPS goes through the system curl, and
the whole thing compiles to a native binary.

```mojo
from std.os import getenv
from mojogram import Bot, Poller, Command, Update, UpdateContext

def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("Hello from Mojo.")
    else:
        _ = ctx.answer(msg.text())

def main() raises:
    var dp = Poller(Bot(getenv("BOT_TOKEN")))
    while True:
        var ups = dp.poll()
        for i in range(ups.len()):
            handle(dp.context(Update(ups.at(i))))
```

## Why it looks like this

Mojo is a static, compiled language with no Python runtime, so a few things are
built from scratch and a few habits from dynamic frameworks are left behind.

You write the update loop yourself. There is no hidden event loop and no handler
registry, because Mojo can't store a list of mixed handler functions. You pull a
batch of updates and call your own handler on each one. Routing is plain `if` and
`elif` over data only filters, which is faster and fully type checked.

## What you get

- Around 60 typed Bot API methods, with `call()` for everything else.
- Inline and reply keyboards, including colored buttons, web app buttons, and
  contact and location requests.
- Polls, reactions, payments and Telegram Stars, inline mode, and file uploads.
- A per chat finite state machine that is safe to use from parallel workers.
- Optional parallel processing of an update batch, with no GIL.
- A webhook server, retry with rate limit handling, a rate limiter, and i18n.

In practice that covers command bots, multi-step forms, button menus, broadcasts,
paid bots with Telegram Stars, group admin tools, and inline-mode bots. If you
have a specific goal in mind, [How do I...?](recipes.md) maps common tasks to
working code.

## Status

mojogram builds with zero errors and zero warnings on both pixi and uv, passes
its test suites, and has been used live against the real Telegram API. It rides
on Mojo, which is still pre 1.0, so the language itself can shift under it. CI
runs on every change to catch that early.

Start with [Install](install.md), then the [Quickstart](getting-started.md).
