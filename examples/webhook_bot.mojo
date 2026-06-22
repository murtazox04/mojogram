"""A webhook bot that receives updates over HTTP instead of polling.

Terminate TLS with ngrok or nginx and forward to this server:
    ngrok http 8080
    # then: bot.set_webhook("https://<id>.ngrok.io")

Run:  BOT_TOKEN=123:abc pixi run mojo run -I . examples/webhook_bot.mojo
(A real token is only needed to *reply*; receiving works with any token.)
"""
from std.os import getenv
from mojogram import Bot, WebhookServer, Command, UpdateContext


def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    print("webhook: chat", msg.chat_id(), "text:", msg.text())
    if Command("start").check(msg):
        _ = ctx.answer("Webhook bot ready.")
    else:
        _ = ctx.answer(msg.text())


def main() raises:
    var token = getenv("BOT_TOKEN")
    if len(token.as_bytes()) == 0:
        token = "dummy-token"   # receive path works without a real token
    var srv = WebhookServer(Bot(token), 8080)
    while True:
        handle(srv.context(srv.next()))
