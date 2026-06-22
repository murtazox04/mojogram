# So'rovnoma, to'lov va admin

Bu yerdagi metodlar matn yuborishdan kamroq uchraydi, lekin hammasi typed va
hammasi `ctx.bot`'da turadi. O'ralmagan har narsa baribir bitta `call()` masofada.

## So'rovnoma va quiz

`send_poll` savol va variantlar ro'yxatini oladi. Quiz uchun `quiz=True` qo'yib,
`correct_option_id`'ni belgilang; oddiy so'rovnoma uchun standartlarni qoldiring.

```mojo
_ = ctx.bot.send_poll(chat_id, "Tab yoki bo'sh joy?", ["Tab", "Bo'sh joy"])

_ = ctx.bot.send_poll(
    chat_id,
    "Qaysi biri Mojo kalit so'zi?",
    ["def", "func", "method"],
    quiz=True,
    correct_option_id=0,        # variantlarga noldan boshlangan indeks
)

_ = ctx.bot.send_poll(chat_id, "Istalganini tanlang", ["a", "b", "c"], allows_multiple_answers=True)
```

Quiz'ga to'g'ri `correct_option_id` kerak; `quiz=True`'ni standart `-1` bilan
yuborsangiz, Telegram uni 400 bilan rad etadi. So'rovnoma javoblari `poll` va
`poll_answer` yangilanishlari sifatida keladi, agar ularni `allowed_updates`'da
yoqsangiz.

## Reaksiyalar

Xabarga emoji reaksiya qo'ying:

```mojo
_ = ctx.bot.set_message_reaction(chat_id, msg.message_id(), "👍")
_ = ctx.bot.set_message_reaction(chat_id, msg.message_id(), "🔥", is_big=True)
```

## To'lov va Telegram Stars

Telegram'da ikki to'lov yo'li bor: provayder orqali haqiqiy pul, va Telegram
Stars (`XTR` valyutasi, provayder token yo'q). Narxlar belgilangan summalarning
JSON massivi, valyutaning eng kichik birligida.

```mojo
# Telegram Stars: valyuta XTR, provider_token bo'sh qoldiriladi
var prices = String('[{"label":"Pro tarif","amount":500}]')   # 500 Stars
_ = ctx.bot.send_invoice(
    chat_id, "Pro", "Bir oylik Pro", "sub_pro", "XTR", prices
)

# Chat invoyisi o'rniga ulashsa bo'ladigan havola
var link = ctx.bot.create_invoice_link("Pro", "Bir oy", "sub_pro", "XTR", prices)
```

To'lov jarayoni sizga ikkita query yangilanishi yuboradi. Ikkalasiga ham tez
javob bering (Telegram taxminan o'n soniya beradi):

```mojo
# pre_checkout_query: to'lovdan oldin tasdiqlash yoki rad etish
_ = ctx.bot.answer_pre_checkout_query(query_id, True)
_ = ctx.bot.answer_pre_checkout_query(query_id, False, "Tugab qolgan")

# shipping_query, faqat yetkazib berish manzilini so'ragan bo'lsangiz
_ = ctx.bot.answer_shipping_query(query_id, True)
```

Stars uchun to'lovni qaytarish va balansni o'qish mumkin:

```mojo
_ = ctx.bot.refund_star_payment(user_id, charge_id)
var balance = ctx.bot.get_my_star_balance()
```

## Chat boshqaruvi

Botingiz admin bo'lgan guruhlarda:

```mojo
var chat = ctx.bot.get_chat(chat_id)
var count = ctx.bot.get_chat_member_count(chat_id)
var member = ctx.bot.get_chat_member(chat_id, user_id)   # xom JSON: status, ruxsatlar

_ = ctx.bot.ban_chat_member(chat_id, user_id)
_ = ctx.bot.unban_chat_member(chat_id, user_id)
_ = ctx.bot.leave_chat(chat_id)

_ = ctx.bot.pin_chat_message(chat_id, msg.message_id())
_ = ctx.bot.unpin_chat_message(chat_id)                  # message_id ixtiyoriy: oxirgisini yechadi
```

Qo'shilishni tasdiqlaydigan guruhlar uchun:

```mojo
_ = ctx.bot.approve_chat_join_request(chat_id, user_id)
_ = ctx.bot.decline_chat_join_request(chat_id, user_id)
```

Forum mavzulari, ular yoqilgan superguruhlarda:

```mojo
var topic = ctx.bot.create_forum_topic(chat_id, "Yordam")
_ = ctx.bot.delete_forum_topic(chat_id, thread_id)
```

## Buyruqlar menyusi

Telegram mijozi ko'rsatadigan slash-buyruqlar ro'yxatini ro'yxatdan o'tkazing,
shunda foydalanuvchilar `/` terganda buyruqlaringizni ko'radi:

```mojo
var cmds = String('[{"command":"start","description":"Boshlash"},'
                  '{"command":"help","description":"Yordam"}]')
_ = ctx.bot.set_my_commands(cmds)
var current = ctx.bot.get_my_commands()
_ = ctx.bot.delete_my_commands()
```

Buyruqlarni har yangilanishda emas, boshlanishida bir marta o'rnating.
