# Sending messages and media

Everything you send goes through the `Bot` object. Inside a handler it's on
`ctx.bot`; you can also hold a `Bot` directly and call it from anywhere. Most
send methods return a `Message`, so you can keep its `message_id` and edit or
delete it later.

## Text

`send_message` is the workhorse. Only `chat_id` and `text` are required; the rest
are keyword arguments with sensible defaults.

```mojo
_ = ctx.bot.send_message(chat_id, "plain text")
_ = ctx.bot.send_message(chat_id, "*bold* _italic_", "Markdown")
_ = ctx.bot.send_message(
    chat_id,
    "see the docs",
    parse_mode="HTML",
    reply_markup=kb.as_markup(),
    reply_to_message_id=msg.message_id(),
    disable_notification=True,
)
```

Inside a handler the two shortcuts save you the `chat_id`:

```mojo
_ = ctx.answer("goes to the same chat")
_ = ctx.reply("quotes the incoming message")
```

Telegram caps a text message at 4096 characters. If you build long output, split
it yourself before sending; the framework doesn't chunk for you.

## Parse modes and escaping

A parse mode tells Telegram how to read the markup in your text. mojogram passes
the string through untouched, so the escaping is on you. The `format` helpers
exist for exactly this.

```mojo
from mojogram import escape_html, escape_markdown

var name = msg.from_user().first_name()        # untrusted, may contain < or *
_ = ctx.answer("Hi <b>" + escape_html(name) + "</b>", "HTML")
_ = ctx.answer("Hi *" + escape_markdown(name) + "*", "MarkdownV2")
```

`escape_html` covers `&`, `<`, `>`. `escape_markdown` backslash-escapes every
character MarkdownV2 treats as special. Skip it and a user whose name contains a
`_` or `[` will make Telegram reject the whole message with a 400.

## Photos, video, audio, documents

Two ways to send a file: by a reference Telegram already knows (a `file_id` from
an earlier message, or a public URL), or by uploading bytes from disk.

By reference, no upload:

```mojo
_ = ctx.bot.send_photo(chat_id, "https://example.com/cat.jpg", caption="a cat")
_ = ctx.bot.send_video(chat_id, file_id)            # reuse an id you stored
_ = ctx.bot.send_document(chat_id, file_id, caption="report.pdf")
_ = ctx.bot.send_audio(chat_id, file_id)
_ = ctx.bot.send_voice(chat_id, file_id)
_ = ctx.bot.send_sticker(chat_id, sticker_file_id)
```

From disk, a real multipart upload (the path is shell-escaped for you):

```mojo
_ = ctx.bot.send_photo_file(chat_id, "/tmp/chart.png", caption="today")
_ = ctx.bot.send_document_file(chat_id, "/tmp/report.pdf")
_ = ctx.bot.send_video_file(chat_id, "/tmp/clip.mp4", caption="demo")
```

The `*_file` variants run the upload through curl's multipart support and share
the same retry path as the JSON calls, so a transient 5xx mid-transfer is
retried rather than thrown straight at you.

## Albums

`send_media_group` posts several items as one album. You pass the media array as
a JSON string; build it with `Params`/`put_raw` or write it out:

```mojo
var media = String(
    '[{"type":"photo","media":"' + url1 + '","caption":"one"},'
    '{"type":"photo","media":"' + url2 + '"}]'
)
_ = ctx.bot.send_media_group(chat_id, media)
```

## Location, dice, chat action

```mojo
_ = ctx.bot.send_location(chat_id, 41.311, 69.240)   # Tashkent
_ = ctx.bot.send_dice(chat_id, "🎯")                  # dice, darts, basketball, ...
_ = ctx.bot.send_chat_action(chat_id, "typing")      # the "typing..." hint
```

`send_chat_action` is worth a call before any slow reply (a model response, a
file you're still generating). It shows "typing" or "uploading photo" so the
chat doesn't look frozen.

## Forwarding and copying

```mojo
_ = ctx.bot.forward_message(chat_id, from_chat_id, message_id)   # keeps the "forwarded from" header
_ = ctx.bot.copy_message(chat_id, from_chat_id, message_id)      # a clean copy, no header
```

## Editing and deleting

Hold onto the returned `Message` and you can change it in place. This is how you
build a live-updating message or a menu that rewrites itself on a button press.

```mojo
var sent = ctx.answer("working...")
# ... do the work ...
_ = ctx.bot.edit_message_text(chat_id, sent.message_id(), "done")
_ = ctx.bot.edit_message_caption(chat_id, sent.message_id(), "new caption")
_ = ctx.bot.edit_message_reply_markup(chat_id, sent.message_id(), kb.as_markup())
_ = ctx.bot.edit_message_media(chat_id, sent.message_id(), media_json)
_ = ctx.bot.delete_message(chat_id, sent.message_id())
```

## Downloading what users send

To pull a file a user uploaded, go from its `file_id` to a local path:

```mojo
_ = ctx.bot.download_file(photo_file_id, "/tmp/incoming.jpg")
```

`download_file` does the two-step dance for you (it calls `getFile`, then
fetches from the returned path). If you only need the metadata, `get_file`
returns the raw JSON.

## Anything not wrapped

About 60 methods have typed wrappers. The rest of the Bot API (120-plus methods)
is reachable through `call`, which takes a `Params` builder:

```mojo
from mojogram import Params

var p = Params()
p.put_int("chat_id", chat_id)
p.put_str("emoji", "🎲")
_ = ctx.bot.call("sendDice", p)
```

`Params` has `put_str`, `put_int`, `put_bool`, and `put_raw` for a value that's
already JSON (an array or nested object). See the [API reference](api-reference.md)
for the full list of typed methods.
