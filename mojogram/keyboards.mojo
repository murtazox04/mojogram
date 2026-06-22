"""Keyboard builders that emit reply_markup as JSON text.

Each builder produces a JSON string you pass straight to send_message's
reply_markup argument, which forwards it verbatim through Params.put_raw.
"""
from std.collections import List
from mojogram.json import quote


def _join(parts: List[String], sep: String) -> String:
    var out = String()
    for i in range(len(parts)):
        if i > 0:
            out += sep
        out += parts[i]
    return out


struct InlineKeyboard(Copyable, Movable):
    """Inline keyboard (buttons attached under a message)."""

    var rows: List[String]      # each is a serialized "[{btn},...]"
    var current: List[String]   # serialized "{btn}" in the row being built

    def __init__(out self):
        self.rows = List[String]()
        self.current = List[String]()

    def button(mut self, text: String, callback_data: String = "", url: String = "", web_app: String = "", style: String = "", icon_custom_emoji_id: String = ""):
        # style (Bot API 9.4+): "danger" (red) / "primary" (blue) / "success" (green)
        var b = "{" + quote("text") + ":" + quote(text)
        if web_app != "":
            b += "," + quote("web_app") + ":{" + quote("url") + ":" + quote(web_app) + "}"
        elif url != "":
            b += "," + quote("url") + ":" + quote(url)
        else:
            b += "," + quote("callback_data") + ":" + quote(callback_data)
        if style != "":
            b += "," + quote("style") + ":" + quote(style)
        if icon_custom_emoji_id != "":
            b += "," + quote("icon_custom_emoji_id") + ":" + quote(icon_custom_emoji_id)
        b += "}"
        self.current.append(b)

    def next_row(mut self):
        if len(self.current) > 0:
            self.rows.append("[" + _join(self.current, ",") + "]")
            self.current = List[String]()

    def as_markup(mut self) -> String:
        self.next_row()
        return "{" + quote("inline_keyboard") + ":[" + _join(self.rows, ",") + "]}"


struct ReplyKeyboard(Copyable, Movable):
    """Custom reply keyboard (replaces the user's keyboard)."""

    var rows: List[String]
    var current: List[String]
    var resize: Bool
    var one_time: Bool

    def __init__(out self, resize: Bool = True, one_time: Bool = False):
        self.rows = List[String]()
        self.current = List[String]()
        self.resize = resize
        self.one_time = one_time

    def button(mut self, text: String, request_contact: Bool = False, request_location: Bool = False, style: String = "", icon_custom_emoji_id: String = ""):
        # style (Bot API 9.4+): "danger" (red) / "primary" (blue) / "success" (green)
        var b = "{" + quote("text") + ":" + quote(text)
        if request_contact:
            b += "," + quote("request_contact") + ":true"
        if request_location:
            b += "," + quote("request_location") + ":true"
        if style != "":
            b += "," + quote("style") + ":" + quote(style)
        if icon_custom_emoji_id != "":
            b += "," + quote("icon_custom_emoji_id") + ":" + quote(icon_custom_emoji_id)
        b += "}"
        self.current.append(b)

    def next_row(mut self):
        if len(self.current) > 0:
            self.rows.append("[" + _join(self.current, ",") + "]")
            self.current = List[String]()

    def as_markup(mut self) -> String:
        self.next_row()
        var s = "{" + quote("keyboard") + ":[" + _join(self.rows, ",") + "]"
        s += "," + quote("resize_keyboard") + ":" + ("true" if self.resize else "false")
        s += "," + quote("one_time_keyboard") + ":" + ("true" if self.one_time else "false")
        s += "}"
        return s


def reply_keyboard_remove() -> String:
    """Markup that hides the custom keyboard."""
    return "{" + quote("remove_keyboard") + ":true}"


def force_reply() -> String:
    """Markup that forces the user to reply to the bot's message."""
    return "{" + quote("force_reply") + ":true}"
