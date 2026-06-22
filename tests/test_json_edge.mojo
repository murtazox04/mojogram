"""Adversarial JSON cases. hardening the hand-written parser."""
from mojogram import parse

def ck(name: String, cond: Bool) raises:
    if cond: print("  ok  ", name)
    else:
        print("  FAIL", name); raise Error("FAIL " + name)

def main() raises:
    # raw UTF-8 (emoji + cyrillic + accents) round-trips
    var a = parse('{"t":"héllo 🎉 мир"}')
    ck("utf8 raw", a.get("t").as_string() == "héllo 🎉 мир")
    # surrogate-pair \u escape -> emoji
    var b = parse('{"t":"🎉"}')
    ck("surrogate emoji", b.get("t").as_string() == "🎉")
    # BMP \u escape
    ck("bmp escape", parse('{"t":"Aé"}').get("t").as_string() == "Aé")
    # numbers
    ck("neg int", parse('{"n":-42}').get("n").as_int() == -42)
    ck("big chat_id", parse('{"id":-1001234567890}').get("id").as_int() == -1001234567890)
    ck("float", parse('{"f":3.5}').get("f").as_float() == 3.5)
    ck("scientific", parse('{"e":1.5e3}').get("e").as_float() == 1500.0)
    # nested
    var n = parse('{"a":{"b":[1,2,{"c":3}]}}')
    ck("deep nest", n.get("a").get("b").at(2).get("c").as_int() == 3)
    ck("arr len", n.get("a").get("b").len() == 3)
    # empties + whitespace
    var e = parse('{ "a" : [] , "b" : {} }')
    ck("empty arr", e.get("a").len() == 0)
    ck("empty obj", e.get("b").len() == 0)
    # bool/null
    var v = parse('{"t":true,"f":false,"z":null}')
    ck("true", v.get("t").as_bool())
    ck("false", not v.get("f").as_bool())
    ck("null", v.get("z").is_null())
    ck("absent", not v.has("nope"))
    # escapes
    ck("escapes", parse('{"s":"a\\tb\\\\c\\"d\\/e"}').get("s").as_string() == "a\tb\\c\"d/e")
    # unicode key
    ck("uni key", parse('{"клавиша":1}').get("клавиша").as_int() == 1)
    print("\njson edge ok")
