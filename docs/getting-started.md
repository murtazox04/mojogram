# Quickstart

Install the toolchain first (see [Install](install.md)), then message
[@BotFather](https://t.me/BotFather) and run `/newbot` to get a token. It looks
like `123456789:AAExxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx`.

## Your first bot

Save this as `mybot.mojo`:

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

Run it:

```bash
export BOT_TOKEN="123456:your-token"
pixi run mojo run -I . mybot.mojo
# or, with uv:  uv run mojo run -I . mybot.mojo
```

Send `/start` to your bot and it answers. That's the whole shape of a mojogram
bot: a `handle` function, and a loop that feeds it updates.

## What the loop does

`Poller.poll()` long-polls Telegram and returns a batch of updates. You walk the
batch, wrap each update in an `UpdateContext`, and call your handler. There's no
hidden event loop and no decorator registry; the loop is yours to read and
change.

The `UpdateContext` is the one object your handler gets. It carries the bot, the
update, and the per-chat FSM state, plus shortcuts:

```mojo
_ = ctx.answer("text")                 # send to the same chat
# quote the incoming message
_ = ctx.reply("text")
_ = ctx.answer("*bold*", "Markdown")   # with a parse mode
# the full Bot is on ctx.bot
_ = ctx.bot.send_message(other_chat, "anywhere")
```

## Routing is plain control flow

Filters are data. You check them with `if` and `elif`, and anything they don't
cover is just ordinary code:

```mojo
from mojogram import Command, Text

def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("welcome")
    elif Text("ping").check(msg):
        _ = ctx.answer("pong")
    # your own admin check
    elif msg.from_user().id() == 12345678:
        _ = ctx.answer("hello admin")
    else:
        # echo everything else
        _ = ctx.answer(msg.text())
```

No decorators, no magic, no `await`.

## A button and its callback

Inline buttons send a callback query when tapped. Answer it (so the client stops
spinning) and react to its `data`:

```mojo
from mojogram import Command, InlineKeyboard

def handle(ctx: UpdateContext) raises:
    if ctx.is_message() and Command("start").check(ctx.message()):
        var kb = InlineKeyboard()
        kb.button("Press me", "pressed")
        _ = ctx.answer("Here's a button", "", kb.as_markup())
    elif ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack("got it")
        if cb.data() == "pressed":
            _ = ctx.answer("you pressed the button")
```

## Where to next

- [Sending messages and media](sending.md) for text, files, albums, and editing.
- [Filters, FSM and keyboards](filters-and-fsm.md) for routing and multi-step
  conversations.
- [Callbacks and inline mode](callbacks-inline.md) for interactive bots.
- [Reliability and concurrency](reliability.md) when you go to production.
- [API reference](api-reference.md) for the full method list.
