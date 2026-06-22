# mojogram

mojogram butunlay Mojo tilida yozilgan Telegram bot frameworki. Unda Python yo'q.
JSON parser qo'lda yozilgan, HTTPS tizimdagi curl orqali ketadi, va butun loyiha
native binary'ga kompilyatsiya bo'ladi.

```mojo
from std.os import getenv
from mojogram import Bot, Poller, Command, Update, UpdateContext

def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("Mojo'dan salom.")
    else:
        _ = ctx.answer(msg.text())

def main() raises:
    var dp = Poller(Bot(getenv("BOT_TOKEN")))
    while True:
        var ups = dp.poll()
        for i in range(ups.len()):
            handle(dp.context(Update(ups.at(i))))
```

## Nega aynan shunday

Mojo statik, kompilyatsiyalanadigan til, unda Python runtime yo'q. Shuning uchun
ba'zi narsalar noldan yozilgan, dinamik frameworklardan kelgan ba'zi odatlar esa
qoldirilgan.

Yangilanishlar siklini o'zingiz yozasiz. Yashirin sikl ham, handler registri ham
yo'q, chunki Mojo turli handler funksiyalarini bitta ro'yxatda saqlay olmaydi.
Siz bir to'plam yangilanishni olasiz va har biriga o'z handleringizni chaqirasiz.
Yo'naltirish oddiy `if` va `elif` orqali, faqat ma'lumotli filtrlar ustida. Bu
tezroq va to'liq tip tekshiruvidan o'tadi.

## Nimalar bor

- Taxminan 60 ta typed Bot API metod, qolgani uchun `call()`.
- Inline va reply klaviaturalar: rangli tugmalar, web app tugmalari, kontakt va
  joylashuv so'rovlari.
- So'rovnomalar, reaksiyalar, to'lovlar va Telegram Stars, inline rejim, fayl yuklash.
- Har chat uchun cheklangan holatlar mashinasi (FSM), parallel ishchilarda xavfsiz.
- Yangilanishlar to'plamini ixtiyoriy parallel qayta ishlash, GIL'siz.
- Webhook server, rate-limit bilan qayta urinish, rate limiter va i18n.

Amalda bu buyruq botlari, ko'p bosqichli formalar, tugma menyulari, ommaviy
yuborish, Telegram Stars bilan pullik botlar, guruh admin vositalari va inline
rejim botlarini qoplaydi. Aniq maqsadingiz bo'lsa, [Qanday qilaman?](recipes.md)
keng tarqalgan vazifalarni ishlaydigan kodga bog'laydi.

## Holat

mojogram pixi va uv'da nol xato, nol ogohlantirish bilan quriladi, test
to'plamlaridan o'tadi, va haqiqiy Telegram API'da jonli sinalgan. U Mojo ustida
turadi, Mojo esa hali 1.0'gacha, shuning uchun tilning o'zi o'zgarishi mumkin. CI
har o'zgarishda buni erta ushlaydi.

[O'rnatish](install.md)dan boshlang, keyin [Tez boshlash](getting-started.md).
