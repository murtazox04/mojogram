"""Minimal echo bot.

Run:  BOT_TOKEN=123:abc pixi run mojo run examples/echo_bot.mojo
"""
from std.os import getenv
from mojogram import Bot, Poller, Command, Update, UpdateContext


def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("Hello! I'm a pure-Mojo bot. Send me anything and I'll echo it.")
    else:
        _ = ctx.answer(msg.text())


def main() raises:
    var token = getenv("BOT_TOKEN")
    if len(token.as_bytes()) == 0:
        raise Error("set BOT_TOKEN in the environment")

    var dp = Poller(Bot(token))
    print("echo bot polling…")
    while True:
        var ups = dp.poll()
        for i in range(ups.len()):
            handle(dp.context(Update(ups.at(i))))
