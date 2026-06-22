"""Pure-Mojo JSON: parser (text -> DOM) and serializer (Params -> text).

There is no JSON in the Mojo stdlib, so we ship our own. The DOM is an *arena*:
every node lives in one `List[JSONNode]` and references its children by index.
This avoids a recursive struct (`JSONNode` holding `List[JSONNode]`), the fragile
part of recursive types in a static language.

A JSON handle is an ArcPointer to the arena plus a node index, which makes it
cheap to copy.

Substring extraction goes through _slice, which slices the UTF-8 byte Span and
materializes a String, since modern Mojo removed String[a:b]. If your Mojo still
supports s[start:end] on String, you can replace the body of _slice with that.
"""
from std.memory import ArcPointer
from std.collections.string import StringSlice

comptime KIND_NULL = 0
comptime KIND_BOOL = 1
comptime KIND_INT = 2
comptime KIND_FLOAT = 3
comptime KIND_STR = 4
comptime KIND_ARR = 5
comptime KIND_OBJ = 6


# ----------------------------- byte helpers --------------------------------

def _nbytes(s: String) -> Int:
    return len(s.as_bytes())


def _byte(s: String, i: Int) -> Int:
    return Int(s.as_bytes()[i])


def _slice(s: String, start: Int, end: Int) -> String:
    # Span slicing is supported even where String[a:b] is not.
    return String(StringSlice(unsafe_from_utf8=s.as_bytes()[start:end]))


def substr(s: String, start: Int, end: Int) -> String:
    """Public byte-offset substring (since String has no `s[a:b]`)."""
    return _slice(s, start, end)


def _hexval(c: Int) -> Int:
    if c >= ord("0") and c <= ord("9"):
        return c - ord("0")
    if c >= ord("a") and c <= ord("f"):
        return c - ord("a") + 10
    if c >= ord("A") and c <= ord("F"):
        return c - ord("A") + 10
    return 0


def _hex4(s: String, start: Int) -> Int:
    var v = 0
    for k in range(4):
        v = v * 16 + _hexval(_byte(s, start + k))
    return v


struct JSONNode(Copyable, Movable):
    var kind: Int
    var b: Bool
    var i: Int
    var f: Float64
    var s: String
    var children: List[Int]   # array items, or object values (parallel to keys)
    var keys: List[String]    # object keys

    def __init__(out self, kind: Int):
        self.kind = kind
        self.b = False
        self.i = 0
        self.f = 0.0
        self.s = ""
        self.children = List[Int]()
        self.keys = List[String]()


# ----------------------------- the handle ----------------------------------

struct JSON(ImplicitlyCopyable, Movable):
    """A read-only cursor onto a parsed document. idx < 0 means null/absent."""

    var doc: ArcPointer[List[JSONNode]]
    var idx: Int

    def __init__(out self, doc: ArcPointer[List[JSONNode]], idx: Int):
        self.doc = doc
        self.idx = idx

    def kind(self) -> Int:
        if self.idx < 0:
            return KIND_NULL
        return self.doc[][self.idx].kind

    def is_null(self) -> Bool:
        return self.kind() == KIND_NULL

    def exists(self) -> Bool:
        return self.idx >= 0 and self.kind() != KIND_NULL

    def as_int(self) -> Int:
        if self.idx < 0:
            return 0
        ref node = self.doc[][self.idx]
        if node.kind == KIND_INT:
            return node.i
        if node.kind == KIND_FLOAT:
            return Int(node.f)
        if node.kind == KIND_BOOL:
            return 1 if node.b else 0
        return 0

    def as_float(self) -> Float64:
        if self.idx < 0:
            return 0.0
        ref node = self.doc[][self.idx]
        if node.kind == KIND_FLOAT:
            return node.f
        if node.kind == KIND_INT:
            return Float64(node.i)
        return 0.0

    def as_bool(self) -> Bool:
        if self.idx < 0:
            return False
        ref node = self.doc[][self.idx]
        if node.kind == KIND_BOOL:
            return node.b
        if node.kind == KIND_INT:
            return node.i != 0
        return False

    def as_string(self) -> String:
        if self.idx < 0:
            return ""
        ref node = self.doc[][self.idx]
        if node.kind == KIND_STR:
            return node.s
        if node.kind == KIND_INT:
            return String(node.i)
        if node.kind == KIND_FLOAT:
            return String(node.f)
        if node.kind == KIND_BOOL:
            return "true" if node.b else "false"
        return ""

    def has(self, key: String) -> Bool:
        if self.idx < 0:
            return False
        ref node = self.doc[][self.idx]
        if node.kind != KIND_OBJ:
            return False
        for k in range(len(node.keys)):
            if node.keys[k] == key:
                return True
        return False

    def get(self, key: String) -> JSON:
        """Object field, or an absent (null) handle."""
        if self.idx >= 0:
            ref node = self.doc[][self.idx]
            if node.kind == KIND_OBJ:
                for k in range(len(node.keys)):
                    if node.keys[k] == key:
                        return JSON(self.doc, node.children[k])
        return JSON(self.doc, -1)

    def len(self) -> Int:
        if self.idx < 0:
            return 0
        ref node = self.doc[][self.idx]
        if node.kind == KIND_ARR or node.kind == KIND_OBJ:
            return len(node.children)
        return 0

    def at(self, i: Int) -> JSON:
        """Array element by index, or an absent handle."""
        if self.idx >= 0:
            ref node = self.doc[][self.idx]
            if (node.kind == KIND_ARR or node.kind == KIND_OBJ) and i >= 0 and i < len(node.children):
                return JSON(self.doc, node.children[i])
        return JSON(self.doc, -1)


# ----------------------------- the parser ----------------------------------

def parse(src: String) raises -> JSON:
    """Parse a JSON document, returning a handle to its root."""
    var arena = List[JSONNode]()
    var pos = 0
    _skip_ws(src, pos)
    var root = _parse_value(src, pos, arena)
    return JSON(ArcPointer(arena^), root)


def _skip_ws(src: String, mut pos: Int):
    var n = _nbytes(src)
    while pos < n:
        var c = _byte(src, pos)
        if c == 32 or c == 9 or c == 10 or c == 13:
            pos += 1
        else:
            break


def _parse_value(src: String, mut pos: Int, mut arena: List[JSONNode]) raises -> Int:
    _skip_ws(src, pos)
    if pos >= _nbytes(src):
        raise Error("json: unexpected end of input")
    var c = _byte(src, pos)
    if c == ord("{"):
        return _parse_object(src, pos, arena)
    elif c == ord("["):
        return _parse_array(src, pos, arena)
    elif c == ord('"'):
        var node = JSONNode(KIND_STR)
        node.s = _scan_string(src, pos)
        arena.append(node^)
        return len(arena) - 1
    elif c == ord("t") or c == ord("f"):
        var node = JSONNode(KIND_BOOL)
        if c == ord("t"):
            node.b = True
            pos += 4  # true
        else:
            node.b = False
            pos += 5  # false
        arena.append(node^)
        return len(arena) - 1
    elif c == ord("n"):
        pos += 4  # null
        arena.append(JSONNode(KIND_NULL))
        return len(arena) - 1
    else:
        return _parse_number(src, pos, arena)


def _scan_string(src: String, mut pos: Int) raises -> String:
    pos += 1  # opening quote
    var start = pos
    var n = _nbytes(src)
    while pos < n:
        var c = _byte(src, pos)
        if c == ord("\\"):
            pos += 2  # skip escape pair; \uXXXX hex handled in _unescape
            continue
        if c == ord('"'):
            break
        pos += 1
    var raw = _slice(src, start, pos)
    pos += 1  # closing quote
    return _unescape(raw)


def _unescape(raw: String) raises -> String:
    var n = _nbytes(raw)
    var has_bs = False
    for i in range(n):
        if _byte(raw, i) == ord("\\"):
            has_bs = True
            break
    if not has_bs:
        return raw

    var out = String("")
    var i = 0
    var run = 0
    while i < n:
        if _byte(raw, i) == ord("\\"):
            out += _slice(raw, run, i)
            i += 1
            var c = _byte(raw, i)
            if c == ord("n"):
                out += "\n"
            elif c == ord("t"):
                out += "\t"
            elif c == ord("r"):
                out += "\r"
            elif c == ord("b"):
                out += chr(8)
            elif c == ord("f"):
                out += chr(12)
            elif c == ord("/"):
                out += "/"
            elif c == ord('"'):
                out += '"'
            elif c == ord("\\"):
                out += "\\"
            elif c == ord("u"):
                var cp = _hex4(raw, i + 1)
                i += 4
                if cp >= 0xD800 and cp <= 0xDBFF and i + 6 <= n and _byte(raw, i + 1) == ord("\\") and _byte(raw, i + 2) == ord("u"):
                    var lo = _hex4(raw, i + 3)
                    cp = 0x10000 + ((cp - 0xD800) << 10) + (lo - 0xDC00)
                    i += 6
                out += chr(cp)
            else:
                out += chr(c)
            i += 1
            run = i
        else:
            i += 1
    out += _slice(raw, run, n)
    return out


def _parse_number(src: String, mut pos: Int, mut arena: List[JSONNode]) raises -> Int:
    var start = pos
    var n = _nbytes(src)
    var is_float = False
    while pos < n:
        var c = _byte(src, pos)
        if c == ord(".") or c == ord("e") or c == ord("E"):
            is_float = True
            pos += 1
        elif (c >= ord("0") and c <= ord("9")) or c == ord("-") or c == ord("+"):
            pos += 1
        else:
            break
    var tok = _slice(src, start, pos)
    if is_float:
        var node = JSONNode(KIND_FLOAT)
        node.f = Float64(tok)
        arena.append(node^)
    else:
        var node = JSONNode(KIND_INT)
        node.i = Int(tok)
        arena.append(node^)
    return len(arena) - 1


def _parse_array(src: String, mut pos: Int, mut arena: List[JSONNode]) raises -> Int:
    pos += 1  # [
    var node = JSONNode(KIND_ARR)
    _skip_ws(src, pos)
    if pos < _nbytes(src) and _byte(src, pos) == ord("]"):
        pos += 1
        arena.append(node^)
        return len(arena) - 1
    while True:
        var child = _parse_value(src, pos, arena)
        node.children.append(child)
        _skip_ws(src, pos)
        var c = _byte(src, pos)
        if c == ord(","):
            pos += 1
            continue
        elif c == ord("]"):
            pos += 1
            break
        else:
            raise Error("json: expected ',' or ']' in array")
    arena.append(node^)
    return len(arena) - 1


def _parse_object(src: String, mut pos: Int, mut arena: List[JSONNode]) raises -> Int:
    pos += 1  # {
    var node = JSONNode(KIND_OBJ)
    _skip_ws(src, pos)
    if pos < _nbytes(src) and _byte(src, pos) == ord("}"):
        pos += 1
        arena.append(node^)
        return len(arena) - 1
    while True:
        _skip_ws(src, pos)
        var key = _scan_string(src, pos)
        _skip_ws(src, pos)
        if _byte(src, pos) != ord(":"):
            raise Error("json: expected ':' in object")
        pos += 1
        var val = _parse_value(src, pos, arena)
        node.keys.append(key)
        node.children.append(val)
        _skip_ws(src, pos)
        var c = _byte(src, pos)
        if c == ord(","):
            pos += 1
            continue
        elif c == ord("}"):
            pos += 1
            break
        else:
            raise Error("json: expected ',' or '}' in object")
    arena.append(node^)
    return len(arena) - 1


# --------------------------- serialization ---------------------------------

def _hex2(c: Int) -> String:
    var d = String("0123456789abcdef")
    var hi = (c >> 4) & 0xF
    var lo = c & 0xF
    return _slice(d, hi, hi + 1) + _slice(d, lo, lo + 1)


def json_escape(s: String) -> String:
    """Escape a string's contents (no surrounding quotes). UTF-8 bytes pass through."""
    var n = _nbytes(s)
    var out = String("")
    var run = 0
    for i in range(n):
        var c = _byte(s, i)
        if c == ord('"') or c == ord("\\") or c < 0x20:
            out += _slice(s, run, i)
            if c == ord('"'):
                out += '\\"'
            elif c == ord("\\"):
                out += "\\\\"
            elif c == ord("\n"):
                out += "\\n"
            elif c == ord("\r"):
                out += "\\r"
            elif c == ord("\t"):
                out += "\\t"
            else:
                out += "\\u00" + _hex2(c)
            run = i + 1
    out += _slice(s, run, n)
    return out


def quote(s: String) -> String:
    return '"' + json_escape(s) + '"'


struct Params(Copyable, Movable):
    """Builds a JSON request body incrementally: `{"k":v,...}`."""

    var buf: String
    var first: Bool

    def __init__(out self):
        self.buf = ""
        self.first = True

    def _sep(mut self):
        if not self.first:
            self.buf += ","
        self.first = False

    def put_str(mut self, key: String, value: String):
        self._sep()
        self.buf += quote(key) + ":" + quote(value)

    def put_int(mut self, key: String, value: Int):
        self._sep()
        self.buf += quote(key) + ":" + String(value)

    def put_bool(mut self, key: String, value: Bool):
        self._sep()
        self.buf += quote(key) + ":" + ("true" if value else "false")

    def put_raw(mut self, key: String, raw_json: String):
        """Insert an already-serialized JSON value (e.g. a keyboard markup)."""
        self._sep()
        self.buf += quote(key) + ":" + raw_json

    def build(self) -> String:
        return "{" + self.buf + "}"
