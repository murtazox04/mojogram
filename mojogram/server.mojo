"""A sequential HTTP/1.1 webhook server over libc sockets via FFI.

Telegram POSTs each update as JSON to your HTTPS URL. You terminate TLS at a
reverse proxy such as nginx, or an ngrok tunnel, and point it at this plaintext
server. The TCP socket comes from libc (socket, bind, listen, accept, recv,
send) through Mojo's external_call, with no Python and no extra dependencies.

next() blocks until a request arrives, replies 200 OK immediately (otherwise
Telegram retries the update), then returns the parsed Update for you to handle:

    var srv = WebhookServer(Bot(token), 8080)
    while True:
        handle(srv.context(srv.next()))

For concurrency, run several processes behind nginx, since Mojo 1.0 has no
threads. Each request is read with a single recv of up to 64 KiB, which is
plenty for a Telegram update; loop the recv if you expect larger bodies.

One platform note: sockaddr_in here is laid out for macOS and BSD, with sin_len
then sin_family. On Linux set HOST_IS_BSD to False, since the first two bytes are
a 16-bit sin_family.
"""
from std.ffi import external_call, c_int
from std.memory import alloc, UnsafePointer
from std.collections.string import StringSlice
from mojogram.bot import Bot
from mojogram.fsm import StateStore, State
from mojogram.context import UpdateContext
from mojogram.types import Update
from mojogram.json import parse

comptime AF_INET = 2
comptime SOCK_STREAM = 1
comptime SOL_SOCKET = 1
comptime SO_REUSEADDR = 4          # macOS 0x0004 (Linux: 2)
comptime RECV_CAP = 65536
comptime HOST_IS_BSD = True        # macOS/BSD sockaddr_in layout

comptime HTTP_200 = "HTTP/1.1 200 OK\r\nContent-Length: 0\r\nConnection: close\r\n\r\n"


def _http_body(request: String) -> String:
    """Return the body after the blank line of an HTTP request."""
    var marker = request.find("\r\n\r\n")
    if marker < 0:
        return "{}"
    var start = marker + 4
    var nbytes = len(request.as_bytes())
    if start >= nbytes:
        return "{}"
    return String(StringSlice(unsafe_from_utf8=request.as_bytes()[start:nbytes]))


def _header_value(request: String, name: String) -> String:
    """The value of header `name`, trimmed, or "" if absent. Only the header
    block (before the blank line) is searched, so a value in the body can't
    spoof it."""
    var bytes = request.as_bytes()
    var marker = request.find("\r\n\r\n")
    var head_len = marker if marker >= 0 else len(bytes)
    var head = String(StringSlice(unsafe_from_utf8=bytes[0:head_len]))
    var idx = head.find(name + ":")
    if idx < 0:
        return ""
    var vstart = idx + len(name.as_bytes()) + 1
    var hb = head.as_bytes()
    var end = vstart
    while end < len(hb) and hb[end] != UInt8(ord("\r")) and hb[end] != UInt8(ord("\n")):
        end += 1
    return String(String(StringSlice(unsafe_from_utf8=hb[vstart:end])).strip())


struct WebhookServer(Movable):
    var bot: Bot
    var storage: StateStore
    var fd: Int
    var buf: UnsafePointer[UInt8, MutUntrackedOrigin]
    var secret: String   # if set, requests must carry the matching secret-token header

    def __init__(out self, bot: Bot, port: Int = 8080, secret_token: String = "") raises:
        self.bot = bot
        self.storage = StateStore()
        self.secret = secret_token
        self.buf = alloc[UInt8](RECV_CAP)

        var fd = Int(external_call["socket", c_int](AF_INET, SOCK_STREAM, 0))
        if fd < 0:
            raise Error("webhook: socket() failed")
        self.fd = fd

        var one = alloc[Int32](1)
        one[0] = 1
        _ = external_call["setsockopt", c_int](fd, SOL_SOCKET, SO_REUSEADDR, one, 4)
        one.free()

        var addr = alloc[UInt8](16)
        for i in range(16):
            addr[i] = 0
        comptime if HOST_IS_BSD:
            addr[0] = 16
            addr[1] = AF_INET
        else:
            addr[0] = AF_INET
        addr[2] = UInt8((port >> 8) & 0xFF)   # sin_port, network byte order
        addr[3] = UInt8(port & 0xFF)
        if Int(external_call["bind", c_int](fd, addr, 16)) < 0:
            addr.free()
            raise Error("webhook: bind() failed on port " + String(port))
        addr.free()

        if Int(external_call["listen", c_int](fd, 64)) < 0:
            raise Error("webhook: listen() failed")
        print("mojogram: webhook listening on :" + String(port))

    def next(mut self) raises -> Update:
        """Block for one request, reply 200, return the parsed Update."""
        var caddr = alloc[UInt8](16)
        var clen = alloc[Int32](1)
        clen[0] = 16
        var client = Int(external_call["accept", c_int](self.fd, caddr, clen))
        caddr.free()
        clen.free()
        if client < 0:
            return Update(parse("{}"))

        var n = Int(external_call["recv", Int](client, self.buf, RECV_CAP, 0))
        # reply 200 immediately, then close
        var resp = String(HTTP_200)
        _ = external_call["send", Int](client, resp.unsafe_ptr(), len(resp.as_bytes()), 0)
        _ = external_call["close", c_int](Int32(client))

        if n <= 0:
            return Update(parse("{}"))
        var req = String(StringSlice(unsafe_from_utf8=Span(ptr=self.buf, length=n)))
        # Validate Telegram's secret token header (set via bot.set_webhook(secret_token=...)).
        # Exact match on the parsed header value, not a substring scan of the request.
        if self.secret != "" and _header_value(req, "X-Telegram-Bot-Api-Secret-Token") != self.secret:
            return Update(parse("{}"))   # reject: missing/incorrect secret
        # A malformed body must not crash the server loop; fall back to an empty update.
        try:
            return Update(parse(_http_body(req)))
        except:
            return Update(parse("{}"))

    def context(self, update: Update) -> UpdateContext:
        var cid = 0
        if update.has_message():
            cid = update.message().chat_id()
        elif update.has_callback_query():
            cid = update.callback_query().chat_id()
        return UpdateContext(self.bot, update, State(self.storage, cid))

    def close(mut self):
        _ = external_call["close", c_int](Int32(self.fd))
        self.buf.free()
