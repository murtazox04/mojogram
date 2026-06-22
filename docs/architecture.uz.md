# Arxitektura

## Ma'lumot oqimi

```
Telegram ──getUpdates──> Bot.get_updates ──curl──> Poller.poll()
                                                         │ (offsetni suradi)
   sizning kodingiz: ─────────────────────────────────────┤
   har yangilanish uchun:  handle(dp.context(Update(...)))  │
                          │                                ▼
                          │                         UpdateContext{bot, update, state}
                          ▼
            filtrlar (ma'lumot) + sizning if/elif  ──>  Bot.<metod> ──curl──> Telegram
```

Framework egalik qiladigan event sikl ham, handler registri ham yo'q. Siklni siz
yozasiz; mojogram esa qismlarni beradi: transport, JSON, typed yangilanishlar,
FSM, filtrlar va Bot API.

## Qatlamlar

| Fayl | Vazifasi |
| ---- | -------- |
| `http.mojo` | Tarmoqqa tegadigan yagona joy: `curl` buyrug'ini quradi va uni `subprocess.run` orqali ishga tushiradi. |
| `json.mojo` | Sof Mojo JSON: arena-DOM parser, `Params` serializer va `substr`. |
| `client.mojo` | `Session`, URL qurish va `{ok,result}` konvertini ochish. |
| `bot.mojo` | `Bot`, typed API metodlar, multipart yuklash, umumiy `call()`. |
| `types.mojo` | Har event obyekti uchun JSON DOM ustidagi typed ko'rinishlar. |
| `filters.mojo` | Faqat ma'lumotli `Match` va factory yordamchilar. |
| `fsm.mojo` | `ArcPointer` asosidagi ulashilgan saqlash va `State`. |
| `keyboards.mojo` | JSON matn chiqaradigan klaviatura builderlari. |
| `context.mojo` | Handleringizga beriladigan `UpdateContext`. |
| `dispatcher.mojo` | `Poller.poll()` (offset hisobi) va `context()`. |
| `server.mojo` | `WebhookServer`, libc socketlari ustida FFI orqali HTTP qabuli. |

## Dizayn qarorlari

### 1. HTTPS `curl` CLI orqali

Mojo 1.0'da native TLS ham, libcurl'ni bog'lash uchun barqaror dinamik yuklagich
(`DLHandle`) ham yo'q. Shuning uchun ishonchli yo'l, tizimdagi `curl` binarini
`subprocess.run` bilan ishga tushirish, u stdout'ni (javob tanasini) qaytaradi.
So'rov tanalari va multipart qiymatlar vaqtinchalik fayllarga yoziladi va curl'ning
`@file` hamda `<file` sintaksisi bilan beriladi, shunda foydalanuvchi kontenti
hech qachon shell buyrug'i ichiga qo'shilmaydi.

### 2. JSON arena sifatida, boxed rekursiya emas

`json.mojo` bitta `List[JSONNode]`'ga parse qiladi; nodelar bolalariga rekursiv
`List[JSONNode]` maydoni orqali emas, *indeks* orqali murojaat qiladi. `JSON`
handle bu `(arenaga ArcPointer, indeks)`, `ImplicitlyCopyable`, uzatish arzon.
Accessorlar nodeni hech qachon nusxalamasligi uchun `ref` bog'lash orqali o'qiydi.

### 3. Stringlarda `s[a:b]` yo'q

Mojo String slicing'ni olib tashladi. Barcha substring ishi `json.substr` orqali
ketadi, u UTF-8 bayt `Span`'ini (u slicing'ni *qo'llaydi*) kesib, `String`'ni
qayta tiklaydi. `as_bytes()`'dan kelgan bayt offsetlar mos qoladi.

### 4. Saqlanadigan funksiya pointerlari yo'q, shuning uchun to'g'ridan dispatch

`def(...)` Mojo 1.0'da existential trait va struct maydoni yoki `List` elementi
bo'la olmaydi. Bu dinamik dekorator-registr namunasini imkonsiz qiladi. Buning
o'rniga mojogram sikl ichida sizning handleringizni to'g'ridan chaqiradi.
Shuning uchun filtrlar hech qanday custom predikat callback ko'tarmaydi. Ular sof
ma'lumot, haqiqiy mantiq esa handleringizda oddiy boshqaruv oqimi sifatida
yashaydi. Dispatch qatlami yo'q, kompilyator esa hammasini tekshiradi.

### 5. FSM holati `ArcPointer[Dict]` orqali

Python'siz ulashilgan o'zgaruvchan holat: `StateStore` `ArcPointer[Dict]` saqlaydi.
`StateStore`/`State`'ni nusxalash refcount'ni oshiradi va bitta `Dict`'ni
ulashadi. Ma'lumot nested `Dict`'ni o'zgartirmaslik uchun `"<chat_id>:<key>"`
ko'rinishida tekis kalitlanadi.

## Nusxalash qoidalari (Mojo 1.0)

- Faqat `String`/`Int`/`ArcPointer`/boshqa `ImplicitlyCopyable` maydonlardan
  iborat structlar `(ImplicitlyCopyable, Movable)` deb e'lon qilinadi, masalan
  `JSON`, barcha `types`, `Bot`, `State`, `UpdateContext`.
- `List`/`Dict` maydonli structlar `ImplicitlyCopyable` bo'la olmaydi, masalan
  `JSONNode`, `Match`. Ular `(Copyable, Movable)` qoladi; nusxalar oshkora
  (`.copy()` yoki `^`).

## Parallellik

Mojo 1.0'da `threading`/`Lock` yo'q; parallellik primitivi `parallelize` (GIL'siz
thread-pool parallel-for, ya'ni haqiqiy parallellik). mojogram poll to'plamini
ixtiyoriy ravishda parallel ishlaydi (`examples/parallel_bot.mojo`); standart
sikl ketma-ket. 8 ta I/O-bound chaqiruvda taxminan 4x o'lchandi.

Thread-xavfsizlik **slotlar** orqali: `Bot.with_slot(i)` (`Poller.context(update, i)`
ishlatadi) har ishchiga o'z HTTP vaqtinchalik fayllarini beradi, shunda parallel
`curl` chaqiruvlari hech qachon to'qnashmaydi.

FSM thread-xavfsiz. Mojo 1.0'da `Lock` yo'q, shuning uchun `StateStore` `Atomic`
(`std.atomic`, ulashilgan heap katakda CAS) dan spinlock quradi va uni har Dict op
atrofida oladi. `parallelize` ostida sinaldi: 500 ta distinct-key yozuv hech
nimani yo'qotmaydi, 1000 ta contended read-modify-write aniq jamlanadi. Lock faqat
Dict op'ning mikrosoniyalariga ushlanadi, hech qachon handler I/O bo'ylab emas.
(U torn holatdan saqlaydi; bir xil chat uchun get-then-set *ketma-ketligi* hali
ham ikki op, bu one-set-per-update oqimlarga mos.)

## Webhook qabuli

`server.mojo`'dagi `WebhookServer` libc socketlari ustida `external_call`
(socket/bind/listen/accept/recv/send) orqali ketma-ket HTTP/1.1 server. `next()`
bitta so'rovni qabul qiladi, darhol `200 OK` qaytaradi va parse qilingan
`Update`'ni beradi. Haqiqiy ngrok HTTPS tunnel orqali uchma-uch tekshirildi
(ochiq TLS → tunnel → Mojo server → 200). Threadlar yo'q, shuning uchun u
bir-ulanishli; nginx orqasida N jarayon bilan kengaytiring.

## Qurilmagan (kengaytirish nuqtalari)

| Imkoniyat | Izoh |
| --------- | ---- |
| Async dispatch | Mojo 1.0'da yo'q; `parallelize` parallel to'plam ishlashni qoplaydi. |
| Jarayon ichidagi webhook parallelligi | Server bir-ulanishli (threadsiz); N jarayon + nginx bilan kengaytiring. |
| To'liq typed API | Barcha metodlar `call(method, Params)` orqali yetib boriladi. |
| Saqlanadigan FSM | `State` metod yuzasini Redis/DB ustida amalga oshiring (spinlock'ni saqlang yoki DB'nikidan foydalaning). |
