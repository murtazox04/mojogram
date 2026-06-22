# API ma'lumotnoma

```mojo
from mojogram import Bot, Poller, UpdateContext
from mojogram import Command, Commands, Text, StartsWith, EndsWith, Contains
from mojogram import ContentType, ContentTypes, ChatType
from mojogram import InlineKeyboard, ReplyKeyboard
from mojogram import reply_keyboard_remove, force_reply
from mojogram import StateStore, State, group
from mojogram import JSON, Params, parse, quote, json_escape, substr
from mojogram import Update, Message, CallbackQuery, User, Chat
```

Reply-markup argumentlari JSON satrlar, odatda builderning `as_markup()`'idan.
Tashlab ketish uchun `""` bering. Quyidagi ixtiyoriy argumentlarning standart
qiymati bor, shuning uchun faqat kerakligini o'rnatasiz.

## Poller

`Poller(bot, allowed_updates="")`

| Metod | Qaytaradi | Izoh |
| --- | --- | --- |
| `poll(timeout=30)` | `JSON` | Bitta to'plamni long-poll qiladi va offsetni suradi. `.len()` / `.at(i)` bilan aylaning. |
| `context(update, slot=0)` | `UpdateContext` | Yangilanishni bot va chatga bog'langan holat bilan o'raydi. `slot` parallel ishlar uchun ishchi id. |

## UpdateContext

Maydonlar: `.bot`, `.update`, `.state`.

| Metod | Qaytaradi | Izoh |
| --- | --- | --- |
| `is_message()` / `message()` | `Bool` / `Message` | |
| `is_callback()` / `callback()` | `Bool` / `CallbackQuery` | |
| `chat_id()` | `Int` | |
| `answer(text, parse_mode="", reply_markup="")` | `Message` | Shu chatga yuborish. |
| `reply(text)` | `Message` | Kelgan xabarni iqtibos qilish. |
| `ack(text="")` | | Callback query'ga javob berish. |

## Bot

`Bot(token, api_base="https://api.telegram.org", timeout=60)`

### Akkaunt va yangilanishlar

| Metod | Qaytaradi |
| --- | --- |
| `get_me()` | `User` |
| `log_out()` / `close_bot()` | `Bool` |
| `get_updates(offset, timeout=30, limit=100, allowed_updates="")` | `JSON` |
| `set_webhook(url, secret_token="", allowed_updates="")` | `Bool` |
| `delete_webhook(drop_pending=False)` | `Bool` |
| `get_webhook_info()` | `JSON` |

### Yuborish

Hammasi `Message` qaytaradi. Yuborish metodlari `reply_markup`,
`reply_to_message_id` va `disable_notification` ham oladi.

| Metod | Izoh |
| --- | --- |
| `send_message(chat_id, text, parse_mode="", ...)` | Asosiysi. |
| `send_photo(chat_id, photo, caption="")` | `photo` bu `file_id` yoki URL. |
| `send_video` / `send_audio` / `send_voice` | `send_photo` bilan bir xil shakl. |
| `send_document(chat_id, document, caption="")` | |
| `send_sticker(chat_id, sticker)` | |
| `send_location(chat_id, lat, lon)` | |
| `send_dice(chat_id, emoji="")` | |
| `send_chat_action(chat_id, action)` | `Bool` qaytaradi. "yozyapti" ko'rsatkichi. |
| `forward_message(chat_id, from_chat_id, message_id)` | Sarlavhani saqlaydi. |
| `copy_message(chat_id, from_chat_id, message_id)` | `JSON` qaytaradi. |

### Fayllar

| Metod | Qaytaradi | Izoh |
| --- | --- | --- |
| `send_photo_file(chat_id, path, caption="")` | `Message` | Diskdan multipart yuklash. |
| `send_document_file(chat_id, path, caption="")` | `Message` | |
| `send_video_file(chat_id, path, caption="")` | `Message` | |
| `send_media_group(chat_id, media_json)` | `JSON` | Albom. |
| `get_file(file_id)` | `JSON` | Metama'lumot. |
| `download_file(file_id, dest)` | `Bool` | getFile, keyin yuklab olish. |

### Tahrirlash va o'chirish

| Metod | Qaytaradi |
| --- | --- |
| `edit_message_text(chat_id, message_id, text, parse_mode="", reply_markup="")` | `Message` |
| `edit_message_caption(chat_id, message_id, caption, ...)` | `Message` |
| `edit_message_reply_markup(chat_id, message_id, reply_markup)` | `Message` |
| `edit_message_media(chat_id, message_id, media_json, reply_markup="")` | `Message` |
| `delete_message(chat_id, message_id)` | `Bool` |

### Query'larga javob

| Metod | Qaytaradi |
| --- | --- |
| `answer_callback_query(id, text="", show_alert=False)` | `Bool` |
| `answer_inline_query(id, results_json)` | `Bool` |
| `answer_pre_checkout_query(id, ok, error_message="")` | `Bool` |
| `answer_shipping_query(id, ok, error_message="")` | `Bool` |

### Chat boshqaruvi

| Metod | Qaytaradi |
| --- | --- |
| `get_chat(chat_id)` | `Chat` |
| `get_chat_member_count(chat_id)` | `Int` |
| `get_chat_member(chat_id, user_id)` | `JSON` |
| `ban_chat_member(chat_id, user_id)` | `Bool` |
| `unban_chat_member(chat_id, user_id)` | `Bool` |
| `leave_chat(chat_id)` | `Bool` |
| `pin_chat_message(chat_id, message_id)` | `Bool` |
| `unpin_chat_message(chat_id, message_id=0)` | `Bool` |
| `approve_chat_join_request(chat_id, user_id)` | `Bool` |
| `decline_chat_join_request(chat_id, user_id)` | `Bool` |
| `create_forum_topic(chat_id, name)` | `JSON` |
| `delete_forum_topic(chat_id, message_thread_id)` | `Bool` |

### So'rovnoma, reaksiya, to'lov

| Metod | Qaytaradi |
| --- | --- |
| `send_poll(chat_id, question, options, quiz=False, correct_option_id=-1, ...)` | `Message` |
| `set_message_reaction(chat_id, message_id, emoji, is_big=False)` | `Bool` |
| `send_invoice(chat_id, title, description, payload, currency, prices_json, ...)` | `Message` |
| `create_invoice_link(title, description, payload, currency, prices_json, ...)` | `String` |
| `refund_star_payment(user_id, charge_id)` | `Bool` |
| `get_my_star_balance()` | `JSON` |

### Buyruqlar va stikerlar

| Metod | Qaytaradi |
| --- | --- |
| `set_my_commands(commands_json)` | `Bool` |
| `delete_my_commands()` | `Bool` |
| `get_my_commands()` | `JSON` |
| `get_sticker_set(name)` | `JSON` |

### Umumiy

| Metod | Qaytaradi | Izoh |
| --- | --- | --- |
| `call(method, params)` | `JSON` | `params` bu `Params` builder. Istalgan metodga yetadi. |
| `call_raw(method, body_json)` | `JSON` | JSON tana allaqachon tayyor bo'lganda. |

Transport tarmoq va 5xx xatolarni qayta uradi va 429 `retry_after`'ni hurmat
qiladi. Doimiy 4xx xatolar darhol ko'tariladi.

## Filtrlar

Har factory `Match` qaytaradi; `.check(msg) -> Bool` chaqiring. Ularni oddiy
`if` / `elif` bilan tuzing.

| Factory | Qachon mos keladi |
| --- | --- |
| `Command("start")` | matn `/start`, `/start@bot`, yoki `/start arg` |
| `Commands(["a", "b"])` | matn `/a` yoki `/b` |
| `Text("hi")` | matn aynan `hi` |
| `StartsWith("/pay")` | matn `/pay` bilan boshlanadi |
| `EndsWith("?")` | matn `?` bilan tugaydi |
| `Contains("http")` | matnda `http` bor |
| `ContentType("photo")` | kontent turi mos keladi |
| `ContentTypes([...])` | kontent turi shulardan biri |
| `ChatType("private")` | chat turi mos keladi |

## State (FSM)

`StateStore()` backend; `State` esa `ctx.state`'dagi har-chat handle.

| Metod | Qaytaradi |
| --- | --- |
| `get_state()` | `String` |
| `set_state(s)` | |
| `clear()` | |
| `set_data(key, value)` | |
| `get_data(key, default="")` | `String` |
| `group(name, state)` | `String` (holatni nomlaydi) |

## Klaviaturalar

| Tur / metod | Qaytaradi |
| --- | --- |
| `InlineKeyboard()` | |
| `.button(text, callback_data="", url="", web_app="", style="")` | |
| `ReplyKeyboard(resize=True, one_time=False)` | |
| `.button(text, request_contact=False, request_location=False)` | |
| `.next_row()` | yangi qator boshlash |
| `.as_markup()` | `String` (`reply_markup` sifatida bering) |
| `reply_keyboard_remove()` / `force_reply()` | `String` |

## JSON

| Funksiya / metod | Qaytaradi |
| --- | --- |
| `parse(text)` | `JSON` |
| `.kind()` / `.exists()` / `.is_null()` | tur tekshiruvlari |
| `.as_int()` / `.as_float()` / `.as_bool()` / `.as_string()` | qiymat |
| `.has(key)` / `.get(key)` | `Bool` / `JSON` |
| `.len()` / `.at(i)` | massivga kirish |
| `substr(s, start, end)` / `quote(s)` / `json_escape(s)` | `String` |

`Params` so'rov tanasini quradi: `put_str`, `put_int`, `put_bool`,
`put_raw` (allaqachon JSON bo'lgan qiymat), va `build() -> String`.

## Yordamchilar

| Nomi | Izoh |
| --- | --- |
| `RateLimiter(rate=30.0, burst=30.0)`, `.acquire()` | Token bucket; tezlik ostida qolish uchun bloklaydi. Thread-xavfsiz. |
| `escape_html(s)` | `parse_mode="HTML"` uchun `& < >` ni qochiradi. |
| `escape_markdown(s)` | MarkdownV2 band belgilarini qochiradi. |
| `Spinlock()`, `.acquire()` / `.release()` | Atomic test-and-set; ulashsa bo'ladi. |
| `parallelize[worker](n)` | `std.algorithm`'dan. Indeksni slot sifatida bering. |

## Tiplar

Har typed obyekt xom JSON'ini ham `.json.get("field")` orqali ochadi.

| Tip | Accessorlar |
| --- | --- |
| `Update` | `update_id()`, `type()`, `has(k)`, `event(k)`, `message()`, `edited_message()`, `channel_post()`, `callback_query()`, `inline_query()`, `poll()`, `pre_checkout_query()`, `shipping_query()`, `my_chat_member()`, `chat_member()`, `chat_join_request()` |
| `Message` | `message_id()`, `date()`, `text()`, `caption()`, `chat()`, `chat_id()`, `from_user()`, `reply_to_message()`, `content_type()` |
| `CallbackQuery` | `id()`, `data()`, `from_user()`, `message()`, `chat_id()`, `inline_message_id()` |
| `User` | `id()`, `is_bot()`, `first_name()`, `last_name()`, `username()`, `language_code()`, `is_premium()`, `full_name()` |
| `Chat` | `id()`, `type()`, `title()`, `username()`, `is_private()`, `is_group()` |
| `InlineQuery` | `id()`, `query()`, `offset()`, `from_user()` |
