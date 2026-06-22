"""Inline-mode result builders.

Build the JSON for `answer_inline_query` results without hand-writing JSON:

    var results = inline_results([
        inline_article("1", "Salom", "Salom dunyo!"),
        inline_photo("2", "https://picsum.photos/300"),
    ])
    _ = bot.answer_inline_query(q.id(), results)

(Inline mode must be enabled for the bot via @BotFather.)
"""
from std.collections import List
from mojogram.json import quote


def inline_article(id: String, title: String, message_text: String) raises -> String:
    return (
        '{"type":"article","id":' + quote(id) + ',"title":' + quote(title)
        + ',"input_message_content":{"message_text":' + quote(message_text) + "}}"
    )


def inline_photo(id: String, photo_url: String, thumbnail_url: String = "") raises -> String:
    var thumb = thumbnail_url if thumbnail_url != "" else photo_url
    return (
        '{"type":"photo","id":' + quote(id) + ',"photo_url":' + quote(photo_url)
        + ',"thumbnail_url":' + quote(thumb) + "}"
    )


def inline_results(items: List[String]) raises -> String:
    var out = String("[")
    for i in range(len(items)):
        if i > 0:
            out += ","
        out += items[i]
    out += "]"
    return out
