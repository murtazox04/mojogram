# Callbacks and inline mode

Two kinds of update don't carry a normal message: a tap on an inline button
(a callback query) and a typed `@yourbot ...` query (inline mode). Both arrive
through the same poll loop, and you branch on them like anything else.

## Callback queries

When a user taps an inline button, Telegram sends a callback query carrying the
button's `callback_data`. Always answer it, even with no text, or the client
shows a spinner on the button until it times out.

```mojo
def handle(ctx: UpdateContext) raises:
    if ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack()                         # clears the spinner, no popup
        if cb.data() == "vote:up":
            ctx.ack("Thanks for the vote")   # small toast
        elif cb.data() == "danger":
            _ = ctx.bot.answer_callback_query(cb.id(), "Are you sure?", show_alert=True)
```

`ctx.ack(text="")` is the shortcut; `answer_callback_query` is the full call when
you want `show_alert=True` (a modal the user has to dismiss, instead of a toast).

A `CallbackQuery` gives you `id()`, `data()`, `from_user()`, `message()`,
`chat_id()`, and `inline_message_id()`. The `message()` is the message the button
was attached to, which is what you edit to update a menu in place:

```mojo
var cb = ctx.callback()
ctx.ack()
var m = cb.message()
_ = ctx.bot.edit_message_text(m.chat_id(), m.message_id(), "you picked: " + cb.data())
_ = ctx.bot.edit_message_reply_markup(m.chat_id(), m.message_id(), new_kb.as_markup())
```

### A self-rewriting menu

Editing the same message on each tap is how you build a menu that doesn't
flood the chat:

```mojo
def handle(ctx: UpdateContext) raises:
    if ctx.is_message() and Command("menu").check(ctx.message()):
        var kb = InlineKeyboard()
        kb.button("Sound on", "set:sound:1")
        kb.button("Sound off", "set:sound:0")
        _ = ctx.answer("Settings", "", kb.as_markup())
        return
    if ctx.is_callback():
        var cb = ctx.callback()
        ctx.ack("saved")
        var m = cb.message()
        _ = ctx.bot.edit_message_text(m.chat_id(), m.message_id(), "Saved " + cb.data())
```

Keep `callback_data` short. Telegram limits it to 64 bytes, so pack an action and
an id (`"del:42"`), not a whole payload.

## Inline mode

Inline mode lets users type `@yourbot something` in any chat and pick from
results your bot returns. Turn it on in @BotFather first (`/setinline`).

An inline query update carries the typed text. You answer it with a list of
result objects, built with the `inline_*` helpers:

```mojo
from mojogram import inline_article, inline_photo, inline_results

def handle(ctx: UpdateContext) raises:
    if ctx.update.has("inline_query"):
        var q = ctx.update.inline_query()      # InlineQuery: id(), query(), from_user()
        var text = q.query()
        var results = inline_results([
            inline_article("1", "Echo: " + text, "You typed: " + text),
            inline_article("2", "Shout", text.upper()),
        ])
        _ = ctx.bot.answer_inline_query(q.id(), results)
```

- `inline_article(id, title, message_text)` is a text result. The `id` must be
  unique within the response.
- `inline_photo(id, photo_url, thumb_url)` shows a photo result.
- `inline_results([...])` packs the items into the JSON array
  `answer_inline_query` expects.

When the user picks a result, Telegram can send a `chosen_inline_result` update
(enable it via `allowed_updates`) so you can log or react to the choice.

## What to enable

Reactions, `chat_member`, and a few other update types are off by default. Ask
for them when you build the `Poller`, by passing an `allowed_updates` JSON array:

```mojo
var dp = Poller(
    Bot(token),
    allowed_updates='["message","callback_query","inline_query","chosen_inline_result"]',
)
```

The `Poller` carries that list into every `get_updates` call. Leave it empty and
you get Telegram's default set, which already includes messages and callback
queries but not inline results, reactions, or member changes.
