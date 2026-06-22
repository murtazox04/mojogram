"""Checks for the two security-sensitive helpers: shell-quoting in the curl
transport and secret-header parsing in the webhook server."""
from mojogram.http import _shq
from mojogram.server import _header_value


def main() raises:
    # _shq wraps in single quotes and turns an embedded ' into '\'' so the value
    # can't escape into the shell. _shq("a'b") -> 'a'\''b'
    if _shq("a'b") != "'a'\\''b'":
        raise Error("shq: embedded quote not neutralized: " + _shq("a'b"))
    if _shq("plain") != "'plain'":
        raise Error("shq: plain value mis-quoted")

    # _header_value reads the value from the header block, trims it, and ignores
    # an identical string planted in the body.
    var req = String(
        "POST / HTTP/1.1\r\n"
        "Host: x\r\n"
        "X-Telegram-Bot-Api-Secret-Token: s3cr3t\r\n"
        "\r\n"
        "X-Telegram-Bot-Api-Secret-Token: forged"
    )
    var v = _header_value(req, "X-Telegram-Bot-Api-Secret-Token")
    if v != "s3cr3t":
        raise Error("header: wrong value, got '" + v + "'")
    if _header_value(req, "X-Absent") != "":
        raise Error("header: absent header should be empty")

    print("security ok")
