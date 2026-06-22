# Callback'lar va inline rejim

Ikki turdagi yangilanish oddiy xabar ko'tarmaydi: inline tugma bosilishi
(callback query) va terilgan `@botingiz ...` so'rovi (inline rejim). Ikkalasi
ham xuddi shu poll sikli orqali keladi, va siz ularga ham boshqa hamma narsa
kabi tarmoqlanasiz.

## Callback query'lar

Foydalanuvchi inline tugmani bosganda, Telegram tugmaning `callback_data`'sini
olib kelgan callback query yuboradi. Unga doim javob bering, matnsiz bo'lsa ham,
aks holda mijoz tugmada timeout bo'lguncha aylanuvchi belgini ko'rsatadi.

```mojo
def handle(ctx: UpdateContext) raises:
    if ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack()                         # aylanma belgini tozalaydi, popup yo'q
        if cb.data() == "vote:up":
            ctx.ack("Ovoz uchun rahmat")     # kichik toast
        elif cb.data() == "danger":
            _ = ctx.bot.answer_callback_query(cb.id(), "Ishonchingiz komilmi?", show_alert=True)
```

`ctx.ack(text="")` qisqartma; `answer_callback_query` esa `show_alert=True`
kerak bo'lganda to'liq chaqiruv (toast emas, foydalanuvchi yopishi shart bo'lgan
modal).

`CallbackQuery` sizga `id()`, `data()`, `from_user()`, `message()`, `chat_id()`
va `inline_message_id()` beradi. `message()` tugma biriktirilgan xabar, ya'ni
menyuni joyida yangilash uchun tahrirlaydiganingiz:

```mojo
var cb = ctx.callback()
ctx.ack()
var m = cb.message()
_ = ctx.bot.edit_message_text(m.chat_id(), m.message_id(), "tanladingiz: " + cb.data())
_ = ctx.bot.edit_message_reply_markup(m.chat_id(), m.message_id(), new_kb.as_markup())
```

### O'zini qayta yozadigan menyu

Har bosishda o'sha xabarni tahrirlash, chatni to'ldirmaydigan menyu shunday
quriladi:

```mojo
def handle(ctx: UpdateContext) raises:
    if ctx.is_message() and Command("menu").check(ctx.message()):
        var kb = InlineKeyboard()
        kb.button("Ovoz yoniq", "set:sound:1")
        kb.button("Ovoz o'chiq", "set:sound:0")
        _ = ctx.answer("Sozlamalar", "", kb.as_markup())
        return
    if ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack("saqlandi")
        var m = cb.message()
        _ = ctx.bot.edit_message_text(m.chat_id(), m.message_id(), "Saqlandi " + cb.data())
```

`callback_data`'ni qisqa tuting. Telegram uni 64 baytda cheklaydi, shuning uchun
butun payload emas, harakat va id'ni joylang (`"del:42"`).

## Inline rejim

Inline rejim foydalanuvchilarga istalgan chatda `@botingiz nimadir` deb terib,
botingiz qaytargan natijalardan birini tanlash imkonini beradi. Avval uni
@BotFather'da yoqing (`/setinline`).

Inline query yangilanishi terilgan matnni olib keladi. Unga natija obyektlari
ro'yxati bilan javob berasiz, ularni `inline_*` yordamchilari bilan quriladi:

```mojo
from mojogram import inline_article, inline_photo, inline_results

def handle(ctx: UpdateContext) raises:
    if ctx.update.has("inline_query"):
        var q = ctx.update.inline_query()      # InlineQuery: id(), query(), from_user()
        var text = q.query()
        var results = inline_results([
            inline_article("1", "Echo: " + text, "Siz terdingiz: " + text),
            inline_article("2", "Baland", text.upper()),
        ])
        _ = ctx.bot.answer_inline_query(q.id(), results)
```

- `inline_article(id, title, message_text)` matnli natija. `id` javob ichida
  noyob bo'lishi kerak.
- `inline_photo(id, photo_url, thumbnail_url)` rasm natijasini ko'rsatadi.
- `inline_results([...])` elementlarni `answer_inline_query` kutadigan JSON
  massivga joylaydi.

Foydalanuvchi natijani tanlaganda, Telegram `chosen_inline_result` yangilanishi
yuborishi mumkin (uni `allowed_updates` orqali yoqing), shunda tanlovni log
qilish yoki unga javob berish mumkin.

## Nimani yoqish kerak

Reaksiyalar, `chat_member` va boshqa bir nechta yangilanish turlari standart
holatda o'chiq. Ularni `Poller`'ni qurganingizda `allowed_updates` JSON massivi
bilan so'rang:

```mojo
var dp = Poller(
    Bot(token),
    allowed_updates='["message","callback_query","inline_query","chosen_inline_result"]',
)
```

`Poller` o'sha ro'yxatni har `get_updates` chaqiruviga olib boradi. Bo'sh
qoldirsangiz, Telegram'ning standart to'plamini olasiz, unda xabarlar va
callback query'lar bor, lekin inline natijalar, reaksiyalar yoki a'zolik
o'zgarishlari yo'q.
