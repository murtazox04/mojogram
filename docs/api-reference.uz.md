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

Reply-markup argumentlari JSON satrlar (builderning `as_markup()`'idan), tashlab
ketish uchun `""`.

## Poller

`Poller(bot: Bot)`
| Metod | Qaytaradi | Izoh |
| ------ | ------- | ----- |
| `poll(timeout: Int = 30)` | `JSON` | Bitta to'plamni long-poll qiladi; offsetni suradi. `.len()`/`.at(i)` bilan aylaning. |
| `context(update: Update)` | `UpdateContext` | Yangilanishni bot va chatga bog'langan FSM bilan o'raydi. |

Odatdagi sikl:
```mojo
var dp = Poller(Bot(token))
while True:
    var ups = dp.poll()
    for i in range(ups.len()):
        handle(dp.context(Update(ups.at(i))))
```

## UpdateContext

Maydonlar: `.bot: Bot`, `.update: Update`, `.state: State`
| Metod | Qaytaradi |
| ------ | ------- |
| `is_message()` / `message()` | `Bool` / `Message` |
| `is_callback()` / `callback()` | `Bool` / `CallbackQuery` |
| `chat_id()` | `Int` |
| `answer(text, parse_mode="", reply_markup="")` | `Message` |
| `reply(text)` | `Message` (xabarni iqtibos qiladi) |
| `ack(text="")` | callback query'ga javob beradi |

## Bot

`Bot(token, api_base="https://api.telegram.org", timeout=60)`

Umumiy: `call(method, params: Params) -> JSON`, `call_raw(method, body_json) -> JSON`.

Akkaunt/yangilanishlar: `get_me()->User`, `log_out()->Bool`, `close_bot()->Bool`,
`get_updates(offset, timeout=30, limit=100)->JSON`,
`set_webhook(url, secret_token="")->Bool`, `delete_webhook(drop_pending=False)->Bool`,
`get_webhook_info()->JSON`.

Yuborish (aytilmagan bo'lsa `Message` qaytaradi):
`send_message(chat_id, text, parse_mode="", reply_markup="", reply_to_message_id=0, disable_notification=False)`,
`send_photo`, `send_document`, `send_video`, `send_audio`, `send_voice`,
`send_sticker`, `send_location(chat_id, lat, lon)`, `send_dice(chat_id, emoji="")`,
`send_chat_action(chat_id, action)->Bool`, `forward_message(chat_id, from_chat_id, message_id)`,
`copy_message(...)->JSON`.

Fayl yuklash (curl orqali multipart): `send_photo_file(chat_id, path, caption="")`,
`send_document_file(...)`, `send_video_file(...)`, hammasi `Message` qaytaradi.

Tahrir/o'chirish: `edit_message_text(chat_id, message_id, text, parse_mode="", reply_markup="")`,
`edit_message_caption(...)`, `edit_message_reply_markup(...)`,
`delete_message(chat_id, message_id)->Bool`.

Javob berish: `answer_callback_query(id, text="", show_alert=False)->Bool`,
`answer_inline_query(id, results_json)->Bool`,
`answer_pre_checkout_query(id, ok, error_message="")->Bool`.

Chat boshqaruvi: `get_chat(chat_id)->Chat`, `get_chat_member_count(chat_id)->Int`,
`get_chat_member(chat_id, user_id)->JSON`, `ban_chat_member`, `unban_chat_member`,
`leave_chat`, `pin_chat_message`, `unpin_chat_message`,
`approve_chat_join_request`, `decline_chat_join_request` (Bool).

Media/fayllar: `send_media_group(chat_id, media_json)->JSON`,
`get_file(file_id)->JSON`, `download_file(file_id, dest)->Bool` (getFile + yuklab olish),
`send_photo_file`/`send_document_file`/`send_video_file(chat_id, path, caption="")->Message`.

Buyruqlar: `set_my_commands(commands_json)->Bool`, `delete_my_commands()->Bool`,
`get_my_commands()->JSON`.

Transport tarmoq/5xx xatolarni avtomatik qayta uradi (linear backoff) va 429
`retry_after`'ni hurmat qiladi; doimiy 4xx xatolar darhol ko'tariladi.

## Filtrlar

Factorylar `Match` qaytaradi; `.check(msg) -> Bool` chaqiring:
`Command`, `Commands`, `Text`, `StartsWith`, `EndsWith`, `Contains`,
`ContentType`, `ContentTypes`, `ChatType`. Oddiy `if`/`elif` bilan tuzing.

## FSM

`StateStore()`. `State` (`ctx.state` orqali):
`get_state()->String`, `set_state(s)`, `clear()`, `set_data(k, v)`,
`get_data(k, default="")->String`. `group(group, state)->String`.

## Klaviaturalar

`InlineKeyboard()`: `button(text, callback_data="", url="")`, `next_row()`, `as_markup()->String`.
`ReplyKeyboard(resize=True, one_time=False)`: `button(text)`, `next_row()`, `as_markup()->String`.
`reply_keyboard_remove()->String`, `force_reply()->String`.

## JSON

`parse(text)->JSON`. `JSON` handle: `kind()`, `exists()`, `is_null()`,
`as_int()`, `as_float()`, `as_bool()`, `as_string()`, `has(key)`, `get(key)->JSON`,
`len()`, `at(i)->JSON`. `substr(s, start, end)->String`, `quote(s)`, `json_escape(s)`.

`Params` (so'rov builderi): `put_str(k,v)`, `put_int(k,v)`, `put_bool(k,v)`,
`put_raw(k, json)`, `build()->String`.

## Yordamchilar

- `RateLimiter` `RateLimiter(rate=30.0, burst=30.0)`, `acquire()` `rate` msg/s
  ostida qolish uchun bloklaydi (token bucket, thread-xavfsiz). Yuborishdan oldin
  chaqiring.
- `escape_html(s) -> String`, `parse_mode="HTML"` uchun `& < >`'ni qochiradi.
- `escape_markdown(s) -> String`, MarkdownV2'ning band belgilarini backslash bilan qochiradi.
- `Spinlock` `Spinlock()`, `acquire()`/`release()`; Atomic test-and-set, ulashsa bo'ladi.
- `parallelize[worker](n)` (`std.algorithm`'dan): parallel to'plam. Thread-xavfsiz
  transport uchun `dp.context(update, i)`'da indeksni slot sifatida bering.

## Tiplar

| Tip | Accessorlar |
| ---- | --------- |
| `Update` | `update_id()`, `type()`, `has(k)`, `event(k)->JSON`, `has_message()`/`message()`, `edited_message()`, `channel_post()`, `callback_query()`, `inline_query()`, `poll()`, `poll_answer()`, `pre_checkout_query()`, `shipping_query()`, `my_chat_member()`, `chat_member()`, `chat_join_request()`, `chosen_inline_result()` |
| `Message` | `message_id()`, `date()`, `text()`, `caption()`, `chat()`, `chat_id()`, `from_user()`, `reply_to_message()`, `has(k)`, `content_type()` |
| `CallbackQuery` | `id()`, `data()`, `from_user()`, `message()`, `chat_id()`, `inline_message_id()` |
| `User` | `id()`, `is_bot()`, `first_name()`, `last_name()`, `username()`, `language_code()`, `is_premium()`, `full_name()` |
| `Chat` | `id()`, `type()`, `title()`, `username()`, `is_private()`, `is_group()` |

Parse qilinmagan har qanday maydon istalgan typed obyektda `.json.get("field")`
orqali yetib boriladi.
