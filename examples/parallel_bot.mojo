"""Optional parallel update processing.

Each poll batch is spread across the thread pool with parallelize, so one slow
handler (a database call, an external API, a file upload) doesn't block the rest.
Mojo has no GIL, so this is real parallelism.

Each worker gets the parallelize index as its slot, which keeps every worker's
HTTP temp files separate. FSM state is also safe to touch from parallel workers,
because StateStore guards its maps with a spinlock.

Run:  BOT_TOKEN=123:abc pixi run mojo run -I . examples/parallel_bot.mojo
"""
from std.os import getenv
from std.algorithm import parallelize
from mojogram import Bot, Poller, Command, Update, UpdateContext


def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("Parallel bot ready.")
    else:
        _ = ctx.answer(msg.text())


def main() raises:
    var token = getenv("BOT_TOKEN")
    if len(token.as_bytes()) == 0:
        raise Error("set BOT_TOKEN in the environment")

    var dp = Poller(Bot(token))
    print("parallel bot polling…")
    while True:
        var ups = dp.poll()
        var n = ups.len()

        @parameter
        def worker(i: Int):
            try:
                handle(dp.context(Update(ups.at(i)), i))   # slot = i
            except e:
                print("handler error:", e)

        parallelize[worker](n)
