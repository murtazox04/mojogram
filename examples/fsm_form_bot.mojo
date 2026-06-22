"""Two-step form using the FSM: ask name, then age.

Run:  BOT_TOKEN=123:abc pixi run mojo run examples/fsm_form_bot.mojo
"""
from std.os import getenv
from mojogram import Bot, Poller, Command, Update, UpdateContext


def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()

    if Command("start").check(msg):
        ctx.state.set_state("name")
        _ = ctx.answer("What's your name?")
        return

    var state = ctx.state.get_state()
    if state == "name":
        ctx.state.set_data("name", msg.text())
        ctx.state.set_state("age")
        _ = ctx.answer("Great. How old are you?")
    elif state == "age":
        var name = ctx.state.get_data("name")
        ctx.state.clear()
        _ = ctx.answer("Got it, " + name + " (" + msg.text() + "). Send /start to go again.")
    else:
        _ = ctx.answer("Send /start to begin.")


def main() raises:
    var token = getenv("BOT_TOKEN")
    if len(token.as_bytes()) == 0:
        raise Error("set BOT_TOKEN in the environment")

    var dp = Poller(Bot(token))
    print("form bot polling…")
    while True:
        var ups = dp.poll()
        for i in range(ups.len()):
            handle(dp.context(Update(ups.at(i))))
