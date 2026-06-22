# Tez boshlash

Avval toolchain'ni o'rnating ([O'rnatish](install.md)), keyin
[@BotFather](https://t.me/BotFather)'dan bot token oling.

## Birinchi botingiz

```mojo
from std.os import getenv
from mojogram import Bot, Poller, Command, Update, UpdateContext

def handle(ctx: UpdateContext) raises:
    if ctx.is_message() and Command("start").check(ctx.message()):
        _ = ctx.answer("Salom, ishlayapman.")

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

## Qanday bog'lanib ketadi

1. Siklni o'zingiz boshqarasiz. Yashirin sikl ham, handler registri ham yo'q.
   `poll()` yoki `WebhookServer.next()`ni chaqirasiz va har yangilanishga o'z
   handleringizni ishlatasiz.
2. Bitta kontekst obyekti. Handleringiz bitta `UpdateContext` oladi. Unda bot,
   yangilanish va FSM holati, hamda `ctx.answer(...)` kabi qisqartmalar bor.
3. Yo'naltirish oddiy mantiq. Filtrlar ma'lumot, siz `if` va `elif` bilan
   `Command("start").check(msg)`, `Text("hi").check(msg)` orqali tarmoqlaysiz.

```mojo
def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("salom")
    else:
        _ = ctx.answer(msg.text())
```

Dekorator yo'q, sehr yo'q, await yo'q.

## Javob berish

```mojo
_ = ctx.answer("matn")                       # shu chatga javob
_ = ctx.reply("matn")                        # kelgan xabarni iqtibos qilib
_ = ctx.answer("*qalin*", "Markdown")        # parse rejim bilan
_ = ctx.bot.send_message(chat_id, "istalgan chatga")
```

## Callback'lar

```mojo
def handle(ctx: UpdateContext) raises:
    if ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack("qabul qilindi")
        # cb.data(), cb.message(), va hokazo
```

Keyin filtrlar, FSM, klaviaturalar va parallellik uchun
[Qo'llanma](filters-and-fsm.md)ni yoki [API ma'lumotnoma](api-reference.md)ni o'qing.
