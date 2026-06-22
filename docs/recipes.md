# How do I...?

Short answers to the things you'll actually want to do. Each one is a complete
handler body; drop it into the `handle` function from the
[Quickstart](getting-started.md). Every snippet here is compiled against the
package, so it works as written.

## Reply to a command

```mojo
if ctx.is_message() and Command("start").check(ctx.message()):
    _ = ctx.answer("Welcome!")
```

`Command("start")` matches `/start`, `/start@yourbot`, and `/start with args`.
For several commands at once, use `Commands(["help", "about"])`.

## Echo whatever the user types

```mojo
if ctx.is_message():
    _ = ctx.answer(ctx.message().text())
```

## Send a photo or a file

```mojo
_ = ctx.bot.send_photo(chat_id, "https://example.com/cat.jpg", caption="a cat")
_ = ctx.bot.send_photo_file(chat_id, "/tmp/chart.png")     # upload from disk
_ = ctx.bot.send_document_file(chat_id, "/tmp/report.pdf")
```

By URL or `file_id` it's instant; the `*_file` variants upload bytes. See
[Sending](sending.md) for the full set.

## Show buttons and react to a tap

```mojo
if ctx.is_message() and Command("menu").check(ctx.message()):
    var kb = InlineKeyboard()
    kb.button("Yes", "ans:yes")
    kb.button("No", "ans:no")
    _ = ctx.answer("Pick one", "", kb.as_markup())
elif ctx.is_callback():
    var cb = ctx.callback()
    ctx.ack()                                  # stop the button spinner
    _ = ctx.answer("You chose " + cb.data())
```

## Ask a question and wait for the answer

This is what the per-chat state machine is for. Set a state, and on the next
message check which state the chat is in:

```mojo
if ctx.is_message() and Command("name").check(ctx.message()):
    ctx.state.set_state("awaiting_name")
    _ = ctx.answer("What's your name?")
elif ctx.is_message() and ctx.state.get_state() == "awaiting_name":
    var name = ctx.message().text()
    ctx.state.set_data("name", name)
    ctx.state.clear()                          # done, drop the state
    _ = ctx.answer("Nice to meet you, " + name)
```

The state and its data are per chat, so two users talking to the bot don't step
on each other. Chain more states for a multi-step form.

## Restrict a command to certain users

Filters are data; an "is this an admin" check is just an `if`:

```mojo
comptime ADMIN_ID = 12345678                 # your Telegram user id

if ctx.is_message() and Command("shutdown").check(ctx.message()):
    if ctx.message().from_user().id() == ADMIN_ID:
        _ = ctx.answer("shutting down")
    else:
        _ = ctx.answer("not allowed")
```

## Keep a menu in one message

Instead of sending a new message each tap, edit the one the button is on:

```mojo
if ctx.is_callback():
    var cb = ctx.callback()
    ctx.ack()
    var m = cb.message()
    _ = ctx.bot.edit_message_text(m.chat_id(), m.message_id(), "You picked " + cb.data())
```

## Show "typing..." before a slow reply

```mojo
_ = ctx.bot.send_chat_action(chat_id, "typing")
# ... do the slow work (a model call, building a file) ...
_ = ctx.answer(result)
```

## Send the same message to many chats

Throttle so you don't trip Telegram's flood limit:

```mojo
from mojogram import RateLimiter

var limiter = RateLimiter(rate=25.0, burst=25.0)
for uid in subscriber_ids:
    limiter.acquire()                          # waits if we're going too fast
    _ = bot.send_message(uid, "Announcement")
```

## Take a Telegram Stars payment

```mojo
var prices = String('[{"label":"Pro plan","amount":500}]')   # 500 Stars
_ = ctx.bot.send_invoice(chat_id, "Pro", "One month", "sub_pro", "XTR", prices)
# then approve checkout when Telegram asks:
_ = ctx.bot.answer_pre_checkout_query(query_id, True)
```

See [Polls, payments and admin](polls-payments.md) for the rest of the flow.

## Format text safely

User text can contain characters that break Markdown or HTML, so escape it:

```mojo
from mojogram import escape_html

var name = ctx.message().from_user().first_name()
_ = ctx.answer("Hello <b>" + escape_html(name) + "</b>", "HTML")
```

## Call a method that isn't wrapped

About 60 methods have typed wrappers. For the other 120-plus, build params and
call by name:

```mojo
from mojogram import Params

var p = Params()
p.put_int("chat_id", chat_id)
p.put_int("message_id", message_id)
_ = ctx.bot.call("unpinAllChatMessages", p)
```

## Run it in production

For a few users, polling is enough (the Quickstart loop). For real traffic,
switch to webhooks behind nginx; see [Deployment](deployment.md).
