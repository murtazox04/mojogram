# Quickstart

Install the toolchain first (see [Install](install.md)), then get a bot token
from [@BotFather](https://t.me/BotFather).

## Your first bot

```mojo
from std.os import getenv
from mojogram import Bot, Poller, Command, Update, UpdateContext

def handle(ctx: UpdateContext) raises:
    if ctx.is_message() and Command("start").check(ctx.message()):
        _ = ctx.answer("Hi, I'm alive.")

def main() raises:
    var dp = Poller(Bot(getenv("BOT_TOKEN")))
    while True:
        var ups = dp.poll()
        for i in range(ups.len()):
            handle(dp.context(Update(ups.at(i))))
```

```bash
export BOT_TOKEN="123456:your-token"
mojo run -I /path/to/mojogram mybot.mojo
```

## How it fits together

1. You own the loop. There is no hidden event loop or handler registry. You call
   `poll()`, or `WebhookServer.next()`, and run your own handler on each update.
2. One context object. Your handler takes a single `UpdateContext`. It carries the
   bot, the update, and the FSM state, plus shortcuts like `ctx.answer(...)`.
3. Routing is plain control flow. Filters are data; you branch with `if` and `elif`
   using `Command("start").check(msg)`, `Text("hi").check(msg)`, and so on.

```mojo
def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("hi")
    else:
        _ = ctx.answer(msg.text())
```

No decorators, no magic, no await.

## Replying

```mojo
_ = ctx.answer("text")                       # reply in the same chat
_ = ctx.reply("text")                        # quote the incoming message
_ = ctx.answer("*bold*", "Markdown")         # with a parse mode
_ = ctx.bot.send_message(chat_id, "anywhere")
```

## Callbacks

```mojo
def handle(ctx: UpdateContext) raises:
    if ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack("got it")
        # cb.data(), cb.message(), and so on
```

Next, read the [Guide](filters-and-fsm.md) for filters, FSM, keyboards and
concurrency, or the [API reference](api-reference.md).
