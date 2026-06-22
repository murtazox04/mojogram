# Ishonchlilik va parallellik

Botni ishlab chiqarishda tirik saqlaydigan narsa: beqaror tarmoqda yiqilmaslik,
Telegram'ning flood limitlariga urilmaslik, va yangilanishlar to'planganda
boringizdagi yadrolardan foydalanish.

## Qayta urinishlar avtomatik

Har API chaqiruvi retry qatlamidan o'tadi. Tarmoq xatolari, HTTP 5xx va 429
rate-limit'lar qisqa backoff bilan qayta uriniladi; 429 taxmin qilish o'rniga
Telegram yuborgan `retry_after` qiymatini hurmat qiladi. Doimiy mijoz xatolari
(400, 401, 403, 404) darhol ko'tariladi, chunki ularni qayta urinish hech qachon
yordam bermaydi.

Buni siz hech sozlamaysiz. U JSON chaqiruvlari uchun ham, fayl yuklash uchun ham
standart yoniq. Hatto JSON ham bo'lmagan javob (curl uzilishi, kesilgan tana)
vaqtinchalik xato deb hisoblanadi, shuning uchun bitta yomon o'qish chaqiruvni
qulatmaydi.

## Xatolarni boshqarish

API chaqiruvlari doimiy xatoda ko'tariladi, shuning uchun xato berishi mumkin
bo'lganlarini o'rab, nima qilishni hal qiling. Poll siklida har yangilanish uchun
ushlang, shunda bitta yomon handler jarayonni o'ldirmaydi:

```mojo
while True:
    var ups = dp.poll()
    for i in range(ups.len()):
        try:
            handle(dp.context(Update(ups.at(i))))
        except e:
            # log qiling va xizmatda qoling
            print("handler xatosi:", e)
```

Xato xabari Telegram'ning kodi va tavsifini olib keladi, masalan
`Telegram API error [400] on sendMessage: chat not found`, shuning uchun bitta
log qatori odatda nima noto'g'ri ketganini ko'rish uchun yetarli.

## Rate limiting

Telegram sizni umumiy taxminan soniyasiga 30 xabar, va bitta chatga taxminan
soniyasiga bitta xabar bilan cheklaydi. Undan oshib ketsangiz, 429 olasiz. Retry
qatlami vaqti-vaqti bilan keladigan 429'ni yutadi, lekin zich siklda yuborayotgan
bo'lsangiz, o'z tomoningizda `RateLimiter` bilan tezlikni ushlang. U token
bucket: `acquire()` tezlik ostida qolish uchun yetarlicha bloklaydi.

```mojo
from mojogram import RateLimiter

# 25 msg/s, chegaradan bir oz past
var limiter = RateLimiter(rate=25.0, burst=25.0)

for chat_id in chat_ids:
    # juda tez ketsak, kutadi
    limiter.acquire()
    _ = bot.send_message(chat_id, "broadcast")
```

U thread-xavfsiz (ichida `Atomic` spinlock), shuning uchun bitta limiter'ni
parallel ishchilar bo'ylab ulashsa bo'ladi.

## Parallel to'plamlar

Mojo 1.0'da threadlar yo'q, lekin `parallelize` bor, GIL'siz thread-pool ustida
parallel-for. mojogram undan poll to'plamini yadrolar bo'ylab ishlash uchun
foydalanadi, shunda bitta sekin handler qolganlarini ushlab qolmaydi. Bu
ixtiyoriy; standart sikl ketma-ket.

```mojo
from std.algorithm import parallelize

var ups = dp.poll()
var n = ups.len()

@parameter
def worker(i: Int):
    try:
        # i ni slot sifatida bering
        handle(dp.context(Update(ups.at(i)), i))
    except e:
        print(e)

parallelize[worker](n)
```

Buni ikki narsa xavfsiz qiladi. Ishchi indeksini slot sifatida berish har ishchiga
o'z HTTP vaqtinchalik fayllarini beradi, shunda parallel `curl` chaqiruvlari
bir-birini buzmaydi. Va FSM store o'z maplarini spinlock bilan himoyalaydi, shunda
ulashilgan holatga tegayotgan ishchilar uni buza olmaydi. Lock faqat Dict op'ning
mikrosoniyalariga ushlanadi, hech qachon handler tarmoq chaqiruvi bo'ylab emas,
shuning uchun parallellik haqiqiy. U 500 ta distinct-key yozuv (hech biri
yo'qolmaydi) va 1000 ta contended read-modify-write (aniq) bilan sinaldi.

Bitta eslatma: store torn holatdan himoya qiladi, lekin bir xil chat uchun
get-then-set baribir ikki operatsiya. Bu bir-chatga-bir-yangilanish FSM oqimlari
uchun yetarli, ya'ni odatiy holat.

## Bir nechta tilda gapirish

`I18n` kichik tarjima katalogi. Satrlaringizni har locale uchun qo'shing, keyin
ularni fallback bilan qidiring: so'ralgan locale, keyin standart locale, keyin
siz bergan fallback matn.

```mojo
from mojogram import I18n

var i18n = I18n(default_locale="en")
i18n.add("en", "hello", "Hello")
i18n.add("uz", "hello", "Salom")

var lang = msg.from_user().language_code()    # "uz", "en", ...
_ = ctx.answer(i18n.t(lang, "hello", "Hello"))
```

`language_code()` to'g'ridan foydalanuvchidan keladi, shuning uchun locale'ni
so'ramasdan har bir odam uchun tanlasa bo'ladi.
