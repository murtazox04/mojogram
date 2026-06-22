# API reference

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

Reply-markup arguments are JSON strings (from a builder's `as_markup()`), `""` to omit.

## Poller

`Poller(bot: Bot)`
| Method | Returns | Notes |
| ------ | ------- | ----- |
| `poll(timeout: Int = 30)` | `JSON` | Long-poll one batch; advances the offset. Iterate with `.len()`/`.at(i)`. |
| `context(update: Update)` | `UpdateContext` | Wraps an update with the bot + chat-bound FSM. |

Typical loop:
```mojo
var dp = Poller(Bot(token))
while True:
    var ups = dp.poll()
    for i in range(ups.len()):
        handle(dp.context(Update(ups.at(i))))
```

## UpdateContext

Fields: `.bot: Bot`, `.update: Update`, `.state: State`
| Method | Returns |
| ------ | ------- |
| `is_message()` / `message()` | `Bool` / `Message` |
| `is_callback()` / `callback()` | `Bool` / `CallbackQuery` |
| `chat_id()` | `Int` |
| `answer(text, parse_mode="", reply_markup="")` | `Message` |
| `reply(text)` | `Message` (quotes the message) |
| `ack(text="")` | answers a callback query |

## Bot

`Bot(token, api_base="https://api.telegram.org", timeout=60)`

**Generic:** `call(method, params: Params) -> JSON`, `call_raw(method, body_json) -> JSON`.

**Account/updates:** `get_me()->User`, `log_out()->Bool`, `close_bot()->Bool`,
`get_updates(offset, timeout=30, limit=100)->JSON`,
`set_webhook(url, secret_token="")->Bool`, `delete_webhook(drop_pending=False)->Bool`,
`get_webhook_info()->JSON`.

**Sending** (all return `Message` unless noted):
`send_message(chat_id, text, parse_mode="", reply_markup="", reply_to_message_id=0, disable_notification=False)`,
`send_photo`, `send_document`, `send_video`, `send_audio`, `send_voice`,
`send_sticker`, `send_location(chat_id, lat, lon)`, `send_dice(chat_id, emoji="")`,
`send_chat_action(chat_id, action)->Bool`, `forward_message(chat_id, from_chat_id, message_id)`,
`copy_message(...)->JSON`.

**File uploads (multipart via curl):** `send_photo_file(chat_id, path, caption="")`,
`send_document_file(...)`, `send_video_file(...)`, all return `Message`.

**Editing/deleting:** `edit_message_text(chat_id, message_id, text, parse_mode="", reply_markup="")`,
`edit_message_caption(...)`, `edit_message_reply_markup(...)`,
`delete_message(chat_id, message_id)->Bool`.

**Answering:** `answer_callback_query(id, text="", show_alert=False)->Bool`,
`answer_inline_query(id, results_json)->Bool`,
`answer_pre_checkout_query(id, ok, error_message="")->Bool`.

**Chat mgmt:** `get_chat(chat_id)->Chat`, `get_chat_member_count(chat_id)->Int`,
`get_chat_member(chat_id, user_id)->JSON`, `ban_chat_member`, `unban_chat_member`,
`leave_chat`, `pin_chat_message`, `unpin_chat_message`,
`approve_chat_join_request`, `decline_chat_join_request` (Bool).

**Media/files:** `send_media_group(chat_id, media_json)->JSON`,
`get_file(file_id)->JSON`, `download_file(file_id, dest)->Bool` (getFile + download),
`send_photo_file`/`send_document_file`/`send_video_file(chat_id, path, caption="")->Message`.

**Commands:** `set_my_commands(commands_json)->Bool`, `delete_my_commands()->Bool`,
`get_my_commands()->JSON`.

Transport auto-retries network/5xx (linear backoff) and honours **429 `retry_after`**;
permanent 4xx errors raise immediately.

## Filters

Factories return `Match`; call `.check(msg) -> Bool`:
`Command`, `Commands`, `Text`, `StartsWith`, `EndsWith`, `Contains`,
`ContentType`, `ContentTypes`, `ChatType`. Compose with plain `if`/`elif`.

## FSM

`StateStore()`. `State` (via `ctx.state`):
`get_state()->String`, `set_state(s)`, `clear()`, `set_data(k, v)`,
`get_data(k, default="")->String`. `group(group, state)->String`.

## Keyboards

`InlineKeyboard()`: `button(text, callback_data="", url="")`, `next_row()`, `as_markup()->String`.
`ReplyKeyboard(resize=True, one_time=False)`: `button(text)`, `next_row()`, `as_markup()->String`.
`reply_keyboard_remove()->String`, `force_reply()->String`.

## JSON

`parse(text)->JSON`. **JSON** handle: `kind()`, `exists()`, `is_null()`,
`as_int()`, `as_float()`, `as_bool()`, `as_string()`, `has(key)`, `get(key)->JSON`,
`len()`, `at(i)->JSON`. `substr(s, start, end)->String`, `quote(s)`, `json_escape(s)`.

**Params** (request builder): `put_str(k,v)`, `put_int(k,v)`, `put_bool(k,v)`,
`put_raw(k, json)`, `build()->String`.

## Utilities

- **RateLimiter** `RateLimiter(rate=30.0, burst=30.0)`, `acquire()` blocks to stay
  under `rate` msg/s (token bucket, thread-safe). Call before a send.
- **escape_html(s) -> String**, escape `& < >` for `parse_mode="HTML"`.
- **escape_markdown(s) -> String**, backslash-escape MarkdownV2 reserved chars.
- **Spinlock** `Spinlock()`, `acquire()`/`release()`; Atomic test-and-set, shareable.
- `parallelize[worker](n)` (from `std.algorithm`): parallel batch. Pass the index as
  the slot in `dp.context(update, i)` for thread-safe transport.

## Types

| Type | Accessors |
| ---- | --------- |
| `Update` | `update_id()`, `type()`, `has(k)`, `event(k)->JSON`, `has_message()`/`message()`, `edited_message()`, `channel_post()`, `callback_query()`, `inline_query()`, `poll()`, `poll_answer()`, `pre_checkout_query()`, `shipping_query()`, `my_chat_member()`, `chat_member()`, `chat_join_request()`, `chosen_inline_result()` |
| `Message` | `message_id()`, `date()`, `text()`, `caption()`, `chat()`, `chat_id()`, `from_user()`, `reply_to_message()`, `has(k)`, `content_type()` |
| `CallbackQuery` | `id()`, `data()`, `from_user()`, `message()`, `chat_id()`, `inline_message_id()` |
| `User` | `id()`, `is_bot()`, `first_name()`, `last_name()`, `username()`, `language_code()`, `is_premium()`, `full_name()` |
| `Chat` | `id()`, `type()`, `title()`, `username()`, `is_private()`, `is_group()` |

Any unparsed field is reachable via `.json.get("field")` on any typed object.
