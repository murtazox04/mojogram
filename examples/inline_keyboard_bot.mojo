"""Inline keyboard + callback handling.

Run:  BOT_TOKEN=123:abc pixi run mojo run examples/inline_keyboard_bot.mojo
"""
from std.os import getenv
from mojogram import Bot, Poller, Command, Update, UpdateContext, InlineKeyboard


def handle(ctx: UpdateContext) raises:
    if ctx.is_message():
        var msg = ctx.message()
        if Command("start").check(msg):
            var kb = InlineKeyboard()
            kb.button("👍 Like", "vote:up")
            kb.button("👎 Dislike", "vote:down")
            _ = ctx.bot.send_message(msg.chat_id(), "How do you like mojogram?", "", kb.as_markup())
    elif ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack("Thanks for voting!")
        var verdict = "liked it 🎉" if cb.data() == "vote:up" else "disliked it 😢"
        var m = cb.message()
        _ = ctx.bot.edit_message_text(m.chat_id(), m.message_id(), "You " + verdict)


def main() raises:
    var token = getenv("BOT_TOKEN")
    if len(token.as_bytes()) == 0:
        raise Error("set BOT_TOKEN in the environment")

    var dp = Poller(Bot(token))
    print("keyboard bot polling…")
    while True:
        var ups = dp.poll()
        for i in range(ups.len()):
            handle(dp.context(Update(ups.at(i))))
