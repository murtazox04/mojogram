# Tez boshlash

Avval toolchain'ni o'rnating ([O'rnatish](install.md)), keyin
[@BotFather](https://t.me/BotFather)'ga yozib, `/newbot` buyrug'i bilan token
oling. U `123456789:AAExxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx` ko'rinishida bo'ladi.

## Birinchi botingiz

Buni `mybot.mojo` deb saqlang:

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

Ishga tushiring:

```bash
export BOT_TOKEN="123456:your-token"
pixi run mojo run -I . mybot.mojo
# yoki uv bilan:  uv run mojo run -I . mybot.mojo
```

Botingizga `/start` yuboring va u javob beradi. mojogram botining butun shakli
shu: bitta `handle` funksiya, va unga yangilanishlarni beradigan sikl.

## Sikl nima qiladi

`Poller.poll()` Telegram'ni long-poll qiladi va bir to'plam yangilanish
qaytaradi. Siz to'plamni aylanasiz, har yangilanishni `UpdateContext`'ga o'rab,
handleringizni chaqirasiz. Yashirin event sikl ham, dekorator registri ham yo'q;
sikl o'qish va o'zgartirish uchun sizniki.

`UpdateContext` handleringiz oladigan yagona obyekt. U bot, yangilanish va
har-chat FSM holatini, hamda qisqartmalarni olib yuradi:

```mojo
_ = ctx.answer("matn")                 # shu chatga yuborish
# kelgan xabarni iqtibos qilish
_ = ctx.reply("matn")
_ = ctx.answer("*qalin*", "Markdown")  # parse rejim bilan
# to'liq Bot ctx.bot'da
_ = ctx.bot.send_message(other_chat, "istalgan chatga")
```

## Yo'naltirish oddiy mantiq

Filtrlar ma'lumot. Ularni `if` va `elif` bilan tekshirasiz, ular qamramagan har
narsa esa oddiy kod:

```mojo
from mojogram import Command, Text

def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("xush kelibsiz")
    elif Text("ping").check(msg):
        _ = ctx.answer("pong")
    # o'zingizning admin tekshiruvi
    elif msg.from_user().id() == 12345678:
        _ = ctx.answer("salom admin")
    else:
        # qolgan hammasini echo
        _ = ctx.answer(msg.text())
```

Dekorator yo'q, sehr yo'q, `await` yo'q.

## Tugma va uning callback'i

Inline tugmalar bosilganda callback query yuboradi. Unga javob bering (shunda
mijoz aylanishni to'xtatadi) va uning `data`'siga qarab harakat qiling:

```mojo
from mojogram import Command, InlineKeyboard

def handle(ctx: UpdateContext) raises:
    if ctx.is_message() and Command("start").check(ctx.message()):
        var kb = InlineKeyboard()
        kb.button("Meni bos", "pressed")
        _ = ctx.answer("Mana tugma", "", kb.as_markup())
    elif ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack("qabul qilindi")
        if cb.data() == "pressed":
            _ = ctx.answer("tugmani bosdingiz")
```

## Keyin qayerga

- [Xabar va media yuborish](sending.md) — matn, fayl, albom, tahrirlash.
- [Filtrlar, FSM va klaviaturalar](filters-and-fsm.md) — yo'naltirish va ko'p
  bosqichli suhbatlar.
- [Callback va inline rejim](callbacks-inline.md) — interaktiv botlar.
- [Ishonchlilik va parallellik](reliability.md) — ishlab chiqarishga chiqqanda.
- [API ma'lumotnoma](api-reference.md) — to'liq metodlar ro'yxati.
