"""Message filters: pure data, evaluated by check(msg).

Mojo 1.0 can't store mixed function values in a field, so filters don't carry a
custom predicate callback. A Match is just a small bag of declarative conditions
(commands, text shape, content type, chat type) that are all ANDed together. Any
logic beyond that goes straight into your handler as ordinary control flow.
"""
from std.collections import List
from mojogram.types import Message
from mojogram.json import substr


def _in(needle: String, haystack: List[String]) -> Bool:
    for i in range(len(haystack)):
        if haystack[i] == needle:
            return True
    return False


struct Match(Copyable, Movable):
    var commands: List[String]
    var text_equals: String
    var text_equals_on: Bool
    var text_startswith: String
    var text_endswith: String
    var text_contains: String
    var content_types: List[String]
    var chat_types: List[String]

    def __init__(out self):
        self.commands = []
        self.text_equals = ""
        self.text_equals_on = False
        self.text_startswith = ""
        self.text_endswith = ""
        self.text_contains = ""
        self.content_types = []
        self.chat_types = []

    def check(self, msg: Message) raises -> Bool:
        if len(self.content_types) > 0 and not _in(msg.content_type(), self.content_types):
            return False
        if len(self.chat_types) > 0 and not _in(msg.chat().type(), self.chat_types):
            return False
        if len(self.commands) > 0 and not self._matches_command(msg):
            return False
        if self.text_equals_on and msg.text() != self.text_equals:
            return False
        if self.text_startswith != "" and not msg.text().startswith(self.text_startswith):
            return False
        if self.text_endswith != "" and not msg.text().endswith(self.text_endswith):
            return False
        if self.text_contains != "" and self.text_contains not in msg.text():
            return False
        return True

    def _matches_command(self, msg: Message) raises -> Bool:
        var text = msg.text()
        if not text.startswith("/"):
            return False
        var end = len(text.as_bytes())
        var space = text.find(" ")
        if space != -1 and space < end:
            end = space
        var at = text.find("@")
        if at != -1 and at < end:
            end = at
        return _in(substr(text, 1, end), self.commands)  # skip leading '/'


# ---- factory helpers -------------------------------------------------------

def Command(name: String) -> Match:
    var f = Match()
    f.commands.append(name)
    return f^


def Commands(names: List[String]) -> Match:
    var f = Match()
    f.commands = names.copy()
    return f^


def Text(value: String) -> Match:
    var f = Match()
    f.text_equals = value
    f.text_equals_on = True
    return f^


def StartsWith(prefix: String) -> Match:
    var f = Match()
    f.text_startswith = prefix
    return f^


def EndsWith(suffix: String) -> Match:
    var f = Match()
    f.text_endswith = suffix
    return f^


def Contains(value: String) -> Match:
    var f = Match()
    f.text_contains = value
    return f^


def ContentType(ct: String) -> Match:
    var f = Match()
    f.content_types.append(ct)
    return f^


def ContentTypes(cts: List[String]) -> Match:
    var f = Match()
    f.content_types = cts.copy()
    return f^


def ChatType(ct: String) -> Match:
    var f = Match()
    f.chat_types.append(ct)
    return f^
