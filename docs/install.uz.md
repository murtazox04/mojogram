# O'rnatish

Mojo 1.0 Modular'ning nightly indeksida turadi. Ikkala toolchain menejeri ham
ishlaydi, shuning uchun o'zingizga qulayini tanlang.

## A varianti: pixi

```bash
curl -fsSL https://pixi.sh/install.sh | bash && source ~/.zshrc
pixi install
```

Bu `pixi.toml`ni o'qiydi va MAX hamda Mojo'ni Modular kanalidan oladi.

## B varianti: uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync --python 3.11
uv run mojo --version
```

Bu `pyproject.toml`ni o'qiydi, u Mojo'ni nightly indeksiga bog'lab qo'ygan.

!!! warning
    Stabil PyPI indeksidan foydalanmang. U Mojo 0.26.x'ni beradi, u hali eski
    `fn` va `alias` sintaksisida va mojogram'ni kompilyatsiya qilmaydi.
    `pyproject.toml` uv'ni nightly indeksiga yo'naltirib qo'ygan. macOS'dagi
    standart Python 3.9 juda eski, shuning uchun 3.11 ishlatiladi.

## Bitta tizim talabi

`PATH`'da `curl` bo'lishi kerak. Bu HTTP transporti. U macOS va barcha
keng tarqalgan Linux'larda bor. Ishga tushganda `curl_available()` bilan tekshiring.

## Misollarni ishga tushirish

```bash
export BOT_TOKEN="123456:your-token"
# yoki: uv run mojo run -I . examples/echo_bot.mojo
pixi run echo
pixi run form
pixi run keyboard
pixi run webhook
pixi run test
```

mojogram'ni o'z faylingizdan ishlatish uchun paketni import yo'liga qo'ying:

```bash
mojo run -I /path/to/mojogram yourbot.mojo
```
