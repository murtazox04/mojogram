# Qo'llanma

## Filtrlar

Filtr oddiy ma'lumot. Handleringiz ichida unga `check(msg)` chaqirasiz, va bitta
filtr ichidagi shartlar AND bilan birlashtiriladi. OR yoki murakkabroq mantiq
uchun oddiy `if` va `elif` ishlating.

| Factory | Qachon mos keladi |
| --- | --- |
| `Command("start")` | matn `/start`, shu jumladan `/start@bot` va `/start arg` |
| `Commands(["a", "b"])` | matn `/a` yoki `/b` |
| `Text("hello")` | matn aynan `hello` |
| `StartsWith("/pay")` | matn `/pay` bilan boshlanadi |
| `EndsWith("?")` | matn `?` bilan tugaydi |
| `Contains("http")` | matnda `http` bor |
| `ContentType("photo")` | kontent turi rasm |
| `ChatType("private")` | chat shaxsiy |

```mojo
from mojogram import Command, ContentType, ChatType
from mojogram.types import Message

def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        _ = ctx.answer("boshlandi")
    elif ContentType("photo").check(msg):
        _ = ctx.reply("zo'r rasm")
    elif ChatType("private").check(msg) and msg.from_user().id() == 12345678:
        _ = ctx.answer("salom admin")
```

## Cheklangan holatlar mashinasi (FSM)

Holat va vaqtinchalik ma'lumot har chat uchun `StateStore`'da, butun dispatcher
bo'ylab ulashilgan holda yashaydi. Har handlerning `ctx.state`'i joriy chatga bog'liq.

```mojo
ctx.state.set_state("email_kutilmoqda")
var s = ctx.state.get_state()             # bo'sh bo'lsa ""
ctx.state.set_data("email", "x@y.z")
var e = ctx.state.get_data("email")       # standart ""
ctx.state.clear()                         # shu chat holati va ma'lumotini o'chirish
```

Ikki bosqichli forma:

```mojo
def handle(ctx: UpdateContext) raises:
    if not ctx.is_message():
        return
    var msg = ctx.message()
    if Command("start").check(msg):
        ctx.state.set_state("ism")
        _ = ctx.answer("Ismingiz?")
        return
    var st = ctx.state.get_state()
    if st == "ism":
        ctx.state.set_data("ism", msg.text())
        ctx.state.set_state("yosh")
        _ = ctx.answer("Yoshingiz?")
    elif st == "yosh":
        var ism = ctx.state.get_data("ism")
        ctx.state.clear()
        _ = ctx.answer("Tayyor, " + ism + ".")
```

`StateStore` xotirada turadi. Saqlash uchun xuddi shu metodlarni Redis yoki
ma'lumotlar bazasi ustida yozing.

## Klaviaturalar

```mojo
from mojogram import InlineKeyboard, ReplyKeyboard

var kb = InlineKeyboard()
kb.button("Ochish", url="https://example.com")        # url tugma
kb.button("Ovoz", "vote:up")                            # callback tugma
kb.button("O'chirish", "del", style="danger")           # qizil (Bot API 9.4)
kb.button("Mini app", web_app="https://example.com")    # Mini App ochadi
_ = ctx.answer("birini tanlang", "", kb.as_markup())
```

Reply klaviaturalar ham xuddi shunday ishlaydi va `request_contact` hamda
`request_location`'ni qo'llaydi. Tugma ranglari `style` argumentidan keladi:
`danger` qizil, `primary` ko'k, `success` yashil. Ular Bot API 9.4 va undan
keyingi Telegram mijozlarida ko'rinadi.

## Parallellik

Mojo 1.0'da threadlar yo'q, lekin `parallelize` bor, GIL'siz thread-pool ustida
parallel for. mojogram undan poll to'plamini ixtiyoriy parallel qayta ishlash
uchun foydalanadi, shunda bitta sekin handler qolganlarini ushlab qolmaydi.

```mojo
from std.algorithm import parallelize

var ups = dp.poll()
var n = ups.len()

@parameter
def worker(i: Int):
    try:
        handle(dp.context(Update(ups.at(i)), i))   # i ni slot sifatida bering
    except e:
        print(e)

parallelize[worker](n)
```

Indeksni slot sifatida berish har ishchining HTTP vaqtinchalik fayllarini
ajratib turadi. FSM holatiga ham parallel ishchilardan tegish xavfsiz, chunki
store spinlock bilan himoyalangan. Telegram flood limitlari ostida yuborish uchun
yuborishlaringizni `RateLimiter` bilan o'rang.

## Webhook'lar

Polling o'rniga push uchun `WebhookServer`'ni ishga tushiring. TLS'ni nginx yoki
ngrok tunnelida tugating va serverga yo'naltiring.

```mojo
var srv = WebhookServer(Bot(token), 8080, secret_token="my-secret")
while True:
    handle(srv.context(srv.next()))
```

Server Telegram'ning secret token sarlavhasini tekshiradi. U bir vaqtda bitta
ulanishni qayta ishlaydi, shuning uchun yuk uchun nginx orqasida bir nechta
jarayon ishga tushiring. Tayyor compose fayli uchun `deploy/`ga qarang.
