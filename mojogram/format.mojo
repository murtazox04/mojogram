"""Text escaping for safe message formatting.

Telegram's MarkdownV2 and HTML parse modes treat certain characters specially;
unescaped user text breaks the message (or is rejected). Escape it first.

    _ = ctx.answer(escape_html(user_text), "HTML")
    _ = ctx.answer(escape_markdown(user_text), "MarkdownV2")

ASCII specials are escaped byte-wise; multi-byte UTF-8 passes through untouched
(it's copied in the run slices).
"""
from mojogram.json import substr


def escape_html(s: String) -> String:
    """Escape &, <, > for parse_mode=HTML."""
    var b = s.as_bytes()
    var n = len(b)
    var out = String("")
    var run = 0
    for i in range(n):
        var c = Int(b[i])
        if c == ord("&"):
            out += substr(s, run, i) + "&amp;"
            run = i + 1
        elif c == ord("<"):
            out += substr(s, run, i) + "&lt;"
            run = i + 1
        elif c == ord(">"):
            out += substr(s, run, i) + "&gt;"
            run = i + 1
    return out + substr(s, run, n)


def _is_md_special(c: Int) -> Bool:
    # MarkdownV2 reserved set: _ * [ ] ( ) ~ ` > # + - = | { } . !
    return (
        c == ord("_") or c == ord("*") or c == ord("[") or c == ord("]")
        or c == ord("(") or c == ord(")") or c == ord("~") or c == ord("`")
        or c == ord(">") or c == ord("#") or c == ord("+") or c == ord("-")
        or c == ord("=") or c == ord("|") or c == ord("{") or c == ord("}")
        or c == ord(".") or c == ord("!")
    )


def escape_markdown(s: String) -> String:
    """Backslash-escape every MarkdownV2 reserved character."""
    var b = s.as_bytes()
    var n = len(b)
    var out = String("")
    var run = 0
    for i in range(n):
        if _is_md_special(Int(b[i])):
            out += substr(s, run, i) + "\\"
            run = i   # the special char itself is copied in the next slice
    return out + substr(s, run, n)
