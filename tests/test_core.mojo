"""Runtime self-checks for the pure-Mojo core (parser, types, filters, builders).

Run:  pixi run mojo run -I . tests/test_core.mojo
"""
from mojogram import parse, Update, Params, Command, Text, ContentType
from mojogram import InlineKeyboard, json_escape, I18n, inline_article, inline_results


def check(name: String, cond: Bool) raises:
    if cond:
        print("  ok  ", name)
    else:
        print("  FAIL", name)
        raise Error("assertion failed: " + name)


def test_parse_update() raises:
    var raw = String('{"ok":true,"result":[{"update_id":100,"message":{')
    raw += '"message_id":5,"date":1,"text":"/start hi","chat":{"id":42,"type":"private"},'
    raw += '"from":{"id":7,"is_bot":false,"first_name":"Murtazo","last_name":"X","username":"mx"}}}]}'
    var doc = parse(raw)
    check("ok==true", doc.get("ok").as_bool())
    var arr = doc.get("result")
    check("result len 1", arr.len() == 1)
    var upd = Update(arr.at(0))
    check("update_id", upd.update_id() == 100)
    check("type==message", upd.type() == "message")
    var msg = upd.message()
    check("message_id", msg.message_id() == 5)
    check("text", msg.text() == "/start hi")
    check("chat_id", msg.chat_id() == 42)
    check("chat type", msg.chat().type() == "private")
    check("from id", msg.from_user().id() == 7)
    check("full_name", msg.from_user().full_name() == "Murtazo X")
    check("content_type", msg.content_type() == "text")


def test_filters() raises:
    var raw = String('{"message_id":1,"text":"/start hi","chat":{"id":1,"type":"private"}}')
    var msg = parse(raw)
    from mojogram.types import Message
    var m = Message(msg)
    check("Command start", Command("start").check(m))
    check("Command stop false", not Command("stop").check(m))
    check("Text mismatch", not Text("nope").check(m))
    check("Text eq", Text("/start hi").check(m))
    check("ContentType text", ContentType("text").check(m))


def test_escape() raises:
    var raw = String('{"t":"line1\\nline2 \\"q\\" end"}')
    var doc = parse(raw)
    check("unescape", doc.get("t").as_string() == 'line1\nline2 "q" end')
    check("escape roundtrip", json_escape('a"b') == 'a\\"b')


def test_params() raises:
    var p = Params()
    p.put_int("chat_id", 42)
    p.put_str("text", "hi")
    p.put_raw("reply_markup", "{}")
    check("params", p.build() == '{"chat_id":42,"text":"hi","reply_markup":{}}')


def test_keyboard() raises:
    var kb = InlineKeyboard()
    kb.button("Yes", "y")
    kb.button("No", "n")
    var m = kb.as_markup()
    check("inline kb", m == '{"inline_keyboard":[[{"text":"Yes","callback_data":"y"},{"text":"No","callback_data":"n"}]]}')


def test_extras() raises:
    # styled button (Bot API 9.4)
    var kb = InlineKeyboard()
    kb.button("Del", "d", style="danger")
    check("styled kb", kb.as_markup() == '{"inline_keyboard":[[{"text":"Del","callback_data":"d","style":"danger"}]]}')
    # i18n with fallback chain
    var i = I18n("en")
    i.add("en", "hi", "Hello")
    i.add("uz", "hi", "Salom")
    check("i18n uz", i.t("uz", "hi") == "Salom")
    check("i18n fallback", i.t("ru", "hi") == "Hello")
    check("i18n key", i.t("ru", "missing") == "missing")
    # inline results
    var r = inline_results([inline_article("1", "T", "body")])
    check("inline", r == '[{"type":"article","id":"1","title":"T","input_message_content":{"message_text":"body"}}]')


def main() raises:
    print("test_parse_update"); test_parse_update()
    print("test_filters"); test_filters()
    print("test_escape"); test_escape()
    print("test_params"); test_params()
    print("test_keyboard"); test_keyboard()
    print("test_extras"); test_extras()
    print("\nall tests passed")
