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

Reply-markup arguments are JSON strings, usually from a builder's `as_markup()`.
Pass `""` to omit one. Optional arguments shown below have defaults, so you only
set what you need.

## Poller

`Poller(bot, allowed_updates="")`

| Method | Returns | Notes |
| --- | --- | --- |
| `poll(timeout=30)` | `JSON` | Long-polls one batch and advances the offset. Iterate with `.len()` / `.at(i)`. |
| `context(update, slot=0)` | `UpdateContext` | Wraps an update with the bot and chat-bound state. `slot` is the worker id for parallel runs. |

## UpdateContext

Fields: `.bot`, `.update`, `.state`.

| Method | Returns | Notes |
| --- | --- | --- |
| `is_message()` / `message()` | `Bool` / `Message` | |
| `is_callback()` / `callback()` | `Bool` / `CallbackQuery` | |
| `chat_id()` | `Int` | |
| `answer(text, parse_mode="", reply_markup="")` | `Message` | Send to the same chat. |
| `reply(text)` | `Message` | Quote the incoming message. |
| `ack(text="")` | | Answer a callback query. |

## Bot

`Bot(token, api_base="https://api.telegram.org", timeout=60)`

### Account and updates

| Method | Returns |
| --- | --- |
| `get_me()` | `User` |
| `log_out()` / `close_bot()` | `Bool` |
| `get_updates(offset, timeout=30, limit=100, allowed_updates="")` | `JSON` |
| `set_webhook(url, secret_token="", allowed_updates="")` | `Bool` |
| `delete_webhook(drop_pending=False)` | `Bool` |
| `get_webhook_info()` | `JSON` |

### Sending

All return `Message`. The send methods also take
`reply_markup`, `reply_to_message_id`, and `disable_notification`.

| Method | Notes |
| --- | --- |
| `send_message(chat_id, text, parse_mode="", ...)` | The main one. |
| `send_photo(chat_id, photo, caption="")` | `photo` is a `file_id` or URL. |
| `send_video` / `send_audio` / `send_voice` | Same shape as `send_photo`. |
| `send_document(chat_id, document, caption="")` | |
| `send_sticker(chat_id, sticker)` | |
| `send_location(chat_id, lat, lon)` | |
| `send_dice(chat_id, emoji="")` | |
| `send_chat_action(chat_id, action)` | Returns `Bool`. The "typing" hint. |
| `forward_message(chat_id, from_chat_id, message_id)` | Keeps the header. |
| `copy_message(chat_id, from_chat_id, message_id)` | Returns `JSON`. |

### Files

| Method | Returns | Notes |
| --- | --- | --- |
| `send_photo_file(chat_id, path, caption="")` | `Message` | Multipart upload from disk. |
| `send_document_file(chat_id, path, caption="")` | `Message` | |
| `send_video_file(chat_id, path, caption="")` | `Message` | |
| `send_media_group(chat_id, media_json)` | `JSON` | An album. |
| `get_file(file_id)` | `JSON` | Metadata. |
| `download_file(file_id, dest)` | `Bool` | getFile, then download. |

### Editing and deleting

| Method | Returns |
| --- | --- |
| `edit_message_text(chat_id, message_id, text, parse_mode="", reply_markup="")` | `Message` |
| `edit_message_caption(chat_id, message_id, caption, ...)` | `Message` |
| `edit_message_reply_markup(chat_id, message_id, reply_markup)` | `Message` |
| `edit_message_media(chat_id, message_id, media_json, reply_markup="")` | `Message` |
| `delete_message(chat_id, message_id)` | `Bool` |

### Answering queries

| Method | Returns |
| --- | --- |
| `answer_callback_query(id, text="", show_alert=False)` | `Bool` |
| `answer_inline_query(id, results_json)` | `Bool` |
| `answer_pre_checkout_query(id, ok, error_message="")` | `Bool` |
| `answer_shipping_query(id, ok, error_message="")` | `Bool` |

### Chat administration

| Method | Returns |
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

### Polls, reactions, payments

| Method | Returns |
| --- | --- |
| `send_poll(chat_id, question, options, quiz=False, correct_option_id=-1, ...)` | `Message` |
| `set_message_reaction(chat_id, message_id, emoji, is_big=False)` | `Bool` |
| `send_invoice(chat_id, title, description, payload, currency, prices_json, ...)` | `Message` |
| `create_invoice_link(title, description, payload, currency, prices_json, ...)` | `String` |
| `refund_star_payment(user_id, charge_id)` | `Bool` |
| `get_my_star_balance()` | `JSON` |

### Commands and stickers

| Method | Returns |
| --- | --- |
| `set_my_commands(commands_json)` | `Bool` |
| `delete_my_commands()` | `Bool` |
| `get_my_commands()` | `JSON` |
| `get_sticker_set(name)` | `JSON` |

### Generic

| Method | Returns | Notes |
| --- | --- | --- |
| `call(method, params)` | `JSON` | `params` is a `Params` builder. Reaches any method. |
| `call_raw(method, body_json)` | `JSON` | When you already have the JSON body. |

The transport retries network and 5xx errors and honours a 429 `retry_after`.
Permanent 4xx errors raise right away.

## Filters

Each factory returns a `Match`; call `.check(msg) -> Bool`. Compose them with
plain `if` / `elif`.

| Factory | Matches when |
| --- | --- |
| `Command("start")` | text is `/start`, `/start@bot`, or `/start arg` |
| `Commands(["a", "b"])` | text is `/a` or `/b` |
| `Text("hi")` | text equals `hi` |
| `StartsWith("/pay")` | text starts with `/pay` |
| `EndsWith("?")` | text ends with `?` |
| `Contains("http")` | text contains `http` |
| `ContentType("photo")` | the content type matches |
| `ContentTypes([...])` | the content type is one of these |
| `ChatType("private")` | the chat type matches |

## State (FSM)

`StateStore()` is the backend; `State` is the per-chat handle on `ctx.state`.

| Method | Returns |
| --- | --- |
| `get_state()` | `String` |
| `set_state(s)` | |
| `clear()` | |
| `set_data(key, value)` | |
| `get_data(key, default="")` | `String` |
| `group(name, state)` | `String` (namespaces a state) |

## Keyboards

| Type / method | Returns |
| --- | --- |
| `InlineKeyboard()` | |
| `.button(text, callback_data="", url="", web_app="", style="")` | |
| `ReplyKeyboard(resize=True, one_time=False)` | |
| `.button(text, request_contact=False, request_location=False)` | |
| `.next_row()` | start a new row |
| `.as_markup()` | `String` (pass as `reply_markup`) |
| `reply_keyboard_remove()` / `force_reply()` | `String` |

## JSON

| Function / method | Returns |
| --- | --- |
| `parse(text)` | `JSON` |
| `.kind()` / `.exists()` / `.is_null()` | type checks |
| `.as_int()` / `.as_float()` / `.as_bool()` / `.as_string()` | the value |
| `.has(key)` / `.get(key)` | `Bool` / `JSON` |
| `.len()` / `.at(i)` | array access |
| `substr(s, start, end)` / `quote(s)` / `json_escape(s)` | `String` |

`Params` builds a request body: `put_str`, `put_int`, `put_bool`,
`put_raw` (a value that is already JSON), and `build() -> String`.

## Utilities

| Name | Notes |
| --- | --- |
| `RateLimiter(rate=30.0, burst=30.0)`, `.acquire()` | Token bucket; blocks to stay under the rate. Thread-safe. |
| `escape_html(s)` | Escape `& < >` for `parse_mode="HTML"`. |
| `escape_markdown(s)` | Escape the MarkdownV2 special characters. |
| `Spinlock()`, `.acquire()` / `.release()` | Atomic test-and-set; shareable. |
| `parallelize[worker](n)` | From `std.algorithm`. Pass the index as the slot. |

## Types

Every typed object also exposes its raw JSON through `.json.get("field")`.

| Type | Accessors |
| --- | --- |
| `Update` | `update_id()`, `type()`, `has(k)`, `event(k)`, `message()`, `edited_message()`, `channel_post()`, `callback_query()`, `inline_query()`, `poll()`, `pre_checkout_query()`, `shipping_query()`, `my_chat_member()`, `chat_member()`, `chat_join_request()` |
| `Message` | `message_id()`, `date()`, `text()`, `caption()`, `chat()`, `chat_id()`, `from_user()`, `reply_to_message()`, `content_type()` |
| `CallbackQuery` | `id()`, `data()`, `from_user()`, `message()`, `chat_id()`, `inline_message_id()` |
| `User` | `id()`, `is_bot()`, `first_name()`, `last_name()`, `username()`, `language_code()`, `is_premium()`, `full_name()` |
| `Chat` | `id()`, `type()`, `title()`, `username()`, `is_private()`, `is_group()` |
| `InlineQuery` | `id()`, `query()`, `offset()`, `from_user()` |
