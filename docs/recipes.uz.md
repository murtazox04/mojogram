# Qanday qilaman?

Amalda kerak bo'ladigan narsalarga qisqa javoblar. Har biri to'liq handler tanasi;
uni [Tez boshlash](getting-started.md)dagi `handle` funksiyasiga joylashtiring.
Bu yerdagi har bir misol paketga qarshi kompilyatsiya qilingan, shuning uchun
yozilganidek ishlaydi.

## Buyruqqa javob berish

```mojo
if ctx.is_message() and Command("start").check(ctx.message()):
    _ = ctx.answer("Xush kelibsiz!")
```

`Command("start")` `/start`, `/start@botingiz` va `/start argument`'ga mos keladi.
Bir nechta buyruq uchun `Commands(["help", "about"])` ishlating.

## Foydalanuvchi terganini echo qilish

```mojo
if ctx.is_message():
    _ = ctx.answer(ctx.message().text())
```

## Rasm yoki fayl yuborish

```mojo
_ = ctx.bot.send_photo(chat_id, "https://example.com/cat.jpg", caption="mushuk")
# diskdan yuklash
_ = ctx.bot.send_photo_file(chat_id, "/tmp/chart.png")
_ = ctx.bot.send_document_file(chat_id, "/tmp/report.pdf")
```

URL yoki `file_id` orqali bir zumda; `*_file` variantlari baytlarni yuklaydi.
To'liq to'plamni [Yuborish](sending.md)dan ko'ring.

## Tugma ko'rsatish va bosilishiga javob berish

```mojo
if ctx.is_message() and Command("menu").check(ctx.message()):
    var kb = InlineKeyboard()
    kb.button("Ha", "ans:yes")
    kb.button("Yo'q", "ans:no")
    _ = ctx.answer("Birini tanlang", "", kb.as_markup())
elif ctx.is_callback():
    var cb = ctx.callback()
    # tugma aylanishini to'xtatadi
    ctx.ack()
    _ = ctx.answer("Siz tanladingiz: " + cb.data())
```

## Savol berib, javobni kutish

Har-chat holat mashinasi aynan shu uchun. Holat o'rnating, keyingi xabarda chat
qaysi holatda ekanini tekshiring:

```mojo
if ctx.is_message() and Command("name").check(ctx.message()):
    ctx.state.set_state("awaiting_name")
    _ = ctx.answer("Ismingiz nima?")
elif ctx.is_message() and ctx.state.get_state() == "awaiting_name":
    var name = ctx.message().text()
    ctx.state.set_data("name", name)
    # tugadi, holatni tashlaymiz
    ctx.state.clear()
    _ = ctx.answer("Tanishganimdan xursandman, " + name)
```

Holat va uning ma'lumoti har-chat, shuning uchun bot bilan gaplashayotgan ikki
foydalanuvchi bir-biriga xalaqit bermaydi. Ko'p bosqichli forma uchun yana
holatlar zanjirlang.

## Buyruqni faqat ayrim foydalanuvchilarga ochish

Filtrlar ma'lumot; "bu admin'mi" tekshiruvi shunchaki `if`:

```mojo
# sizning Telegram user id
comptime ADMIN_ID = 12345678

if ctx.is_message() and Command("shutdown").check(ctx.message()):
    if ctx.message().from_user().id() == ADMIN_ID:
        _ = ctx.answer("o'chirilmoqda")
    else:
        _ = ctx.answer("ruxsat yo'q")
```

## Menyuni bitta xabarda saqlash

Har bosishda yangi xabar yuborish o'rniga, tugma turgan xabarni tahrirlang:

```mojo
if ctx.is_callback():
    var cb = ctx.callback()
    ctx.ack()
    var m = cb.message()
    _ = ctx.bot.edit_message_text(
        m.chat_id(), m.message_id(), "Tanladingiz: " + cb.data()
    )
```

## Sekin javobdan oldin "yozyapti..." ko'rsatish

```mojo
_ = ctx.bot.send_chat_action(chat_id, "typing")
# ... sekin ishni bajaramiz (model chaqiruvi, fayl qurish) ...
_ = ctx.answer(result)
```

## Bir xil xabarni ko'p chatga yuborish

Telegram'ning flood limitiga urilmaslik uchun tezlikni ushlang:

```mojo
from mojogram import RateLimiter

var limiter = RateLimiter(rate=25.0, burst=25.0)
for uid in subscriber_ids:
    # juda tez ketsak, kutadi
    limiter.acquire()
    _ = bot.send_message(uid, "E'lon")
```

## Telegram Stars to'lovini olish

```mojo
# 500 Stars
var prices = String('[{"label":"Pro tarif","amount":500}]')
_ = ctx.bot.send_invoice(chat_id, "Pro", "Bir oy", "sub_pro", "XTR", prices)
# keyin Telegram so'raganda checkout'ni tasdiqlang:
_ = ctx.bot.answer_pre_checkout_query(query_id, True)
```

Qolgan jarayonni [So'rovnoma, to'lov va admin](polls-payments.md)dan ko'ring.

## Matnni xavfsiz formatlash

Foydalanuvchi matni Markdown yoki HTML'ni buzadigan belgilar bo'lishi mumkin,
shuning uchun uni qochiring:

```mojo
from mojogram import escape_html

var name = ctx.message().from_user().first_name()
_ = ctx.answer("Salom <b>" + escape_html(name) + "</b>", "HTML")
```

## O'ralmagan metodni chaqirish

Taxminan 60 metodda typed o'ramlar bor. Qolgan 120 dan ortig'i uchun parametr
qurib, nomi bo'yicha chaqiring:

```mojo
from mojogram import Params

var p = Params()
p.put_int("chat_id", chat_id)
p.put_int("message_id", message_id)
_ = ctx.bot.call("unpinAllChatMessages", p)
```

## Ishlab chiqarishda yurgizish

Bir nechta foydalanuvchi uchun polling yetarli (Tez boshlashdagi sikl). Haqiqiy
trafik uchun nginx orqasidagi webhook'ga o'ting; [Joylashtirish](deployment.md)ni
ko'ring.
