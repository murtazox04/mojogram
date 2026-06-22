# Xabar va media yuborish

Yuboradigan hamma narsangiz `Bot` obyekti orqali ketadi. Handler ichida u
`ctx.bot`'da turadi; `Bot`'ni to'g'ridan ushlab, istalgan joydan ham chaqirsa
bo'ladi. Aksar yuborish metodlari `Message` qaytaradi, shuning uchun uning
`message_id`'sini saqlab, keyin tahrirlash yoki o'chirish mumkin.

## Matn

`send_message` asosiy ish quroli. Faqat `chat_id` va `text` majburiy, qolgani
standart qiymatli keyword argumentlar.

```mojo
_ = ctx.bot.send_message(chat_id, "oddiy matn")
_ = ctx.bot.send_message(chat_id, "*qalin* _kursiv_", "Markdown")
_ = ctx.bot.send_message(
    chat_id,
    "hujjatga qarang",
    parse_mode="HTML",
    reply_markup=kb.as_markup(),
    reply_to_message_id=msg.message_id(),
    disable_notification=True,
)
```

Handler ichida ikkita qisqartma `chat_id`'ni yozishdan qutqaradi:

```mojo
_ = ctx.answer("shu chatga boradi")
_ = ctx.reply("kelgan xabarni iqtibos qiladi")
```

Telegram matnli xabarni 4096 belgida cheklaydi. Uzun chiqish qursangiz, uni
o'zingiz bo'lib yuboring; framework siz uchun bo'lib bermaydi.

## Parse rejimlari va qochirish

Parse rejimi Telegram'ga matningizdagi belgilanishni qanday o'qishni aytadi.
mojogram satrni o'zgartirmay uzatadi, shuning uchun qochirish (escaping) sizning
zimmangizda. `format` yordamchilari aynan shu uchun.

```mojo
from mojogram import escape_html, escape_markdown

var name = msg.from_user().first_name()        # ishonchsiz, < yoki * bo'lishi mumkin
_ = ctx.answer("Salom <b>" + escape_html(name) + "</b>", "HTML")
_ = ctx.answer("Salom *" + escape_markdown(name) + "*", "MarkdownV2")
```

`escape_html` `&`, `<`, `>` ni qoplaydi. `escape_markdown` MarkdownV2 band deb
biladigan har bir belgini backslash bilan qochiradi. Buni tashlab ketsangiz,
ismida `_` yoki `[` bo'lgan foydalanuvchi butun xabarni Telegram 400 bilan rad
etishiga sabab bo'ladi.

## Rasm, video, audio, hujjat

Faylni yuborishning ikki yo'li: Telegram allaqachon biladigan havola orqali
(oldingi xabardan `file_id`, yoki ochiq URL), yoki diskdan baytlarni yuklab.

Havola orqali, yuklashsiz:

```mojo
_ = ctx.bot.send_photo(chat_id, "https://example.com/cat.jpg", caption="mushuk")
_ = ctx.bot.send_video(chat_id, file_id)            # saqlagan id'ingizni qayta ishlatish
_ = ctx.bot.send_document(chat_id, file_id, caption="hisobot.pdf")
_ = ctx.bot.send_audio(chat_id, file_id)
_ = ctx.bot.send_voice(chat_id, file_id)
_ = ctx.bot.send_sticker(chat_id, sticker_file_id)
```

Diskdan, haqiqiy multipart yuklash (yo'l siz uchun shell-escape qilinadi):

```mojo
_ = ctx.bot.send_photo_file(chat_id, "/tmp/chart.png", caption="bugun")
_ = ctx.bot.send_document_file(chat_id, "/tmp/report.pdf")
_ = ctx.bot.send_video_file(chat_id, "/tmp/clip.mp4", caption="demo")
```

`*_file` variantlari yuklashni curl'ning multipart imkoniyati orqali bajaradi va
JSON chaqiruvlari bilan bir xil retry yo'lidan foydalanadi, shuning uchun
yuklash o'rtasidagi vaqtinchalik 5xx to'g'ridan sizga otilmasdan qayta uriniladi.

## Albomlar

`send_media_group` bir nechta elementni bitta albom qilib joylaydi. Media
massivini JSON satr sifatida berasiz; uni `Params`/`put_raw` bilan quring yoki
o'zingiz yozing:

```mojo
var media = String(
    '[{"type":"photo","media":"' + url1 + '","caption":"bir"},'
    '{"type":"photo","media":"' + url2 + '"}]'
)
_ = ctx.bot.send_media_group(chat_id, media)
```

## Joylashuv, zar, chat harakati

```mojo
_ = ctx.bot.send_location(chat_id, 41.311, 69.240)   # Toshkent
_ = ctx.bot.send_dice(chat_id, "🎯")                  # zar, dart, basketbol, ...
_ = ctx.bot.send_chat_action(chat_id, "typing")      # "yozyapti..." ko'rsatkichi
```

`send_chat_action`'ni har qanday sekin javobdan oldin chaqirish foydali (model
javobi, hali yaratayotgan faylingiz). U "yozyapti" yoki "rasm yuklayapti" deb
ko'rsatadi, shunda chat muzlab qolgandek ko'rinmaydi.

## Yo'naltirish va nusxalash

```mojo
_ = ctx.bot.forward_message(chat_id, from_chat_id, message_id)   # "kimdan yo'naltirilgan" sarlavhasini saqlaydi
_ = ctx.bot.copy_message(chat_id, from_chat_id, message_id)      # toza nusxa, sarlavhasiz
```

## Tahrirlash va o'chirish

Qaytgan `Message`'ni ushlab tursangiz, uni joyida o'zgartirsangiz bo'ladi. Jonli
yangilanadigan xabar yoki tugma bosilganda o'zini qayta yozadigan menyu shunday
quriladi.

```mojo
var sent = ctx.answer("ishlayapman...")
# ... ishni bajaramiz ...
_ = ctx.bot.edit_message_text(chat_id, sent.message_id(), "tayyor")
_ = ctx.bot.edit_message_caption(chat_id, sent.message_id(), "yangi izoh")
_ = ctx.bot.edit_message_reply_markup(chat_id, sent.message_id(), kb.as_markup())
_ = ctx.bot.edit_message_media(chat_id, sent.message_id(), media_json)
_ = ctx.bot.delete_message(chat_id, sent.message_id())
```

## Foydalanuvchi yuborganini yuklab olish

Foydalanuvchi yuklagan faylni olish uchun uning `file_id`'sidan lokal yo'lga
o'ting:

```mojo
_ = ctx.bot.download_file(photo_file_id, "/tmp/incoming.jpg")
```

`download_file` ikki bosqichni siz uchun bajaradi (`getFile`'ni chaqiradi, keyin
qaytgan yo'ldan yuklab oladi). Faqat metama'lumot kerak bo'lsa, `get_file` xom
JSON qaytaradi.

## O'ralmagan har narsa

Taxminan 60 metodda typed o'ramlar bor. Qolgan Bot API (120 dan ortiq metod)
`call` orqali yetib boriladi, u `Params` builderini oladi:

```mojo
from mojogram import Params

var p = Params()
p.put_int("chat_id", chat_id)
p.put_str("emoji", "🎲")
_ = ctx.bot.call("sendDice", p)
```

`Params`'da `put_str`, `put_int`, `put_bool` bor, hamda allaqachon JSON bo'lgan
qiymat (massiv yoki nested obyekt) uchun `put_raw`. Typed metodlarning to'liq
ro'yxatini [API ma'lumotnoma](api-reference.md)dan ko'ring.
