# Install

Mojo 1.0 lives on Modular's nightly index. Either toolchain manager works, so
pick the one you already use.

## Option A: pixi

```bash
curl -fsSL https://pixi.sh/install.sh | bash && source ~/.zshrc
pixi install
```

This reads `pixi.toml` and pulls MAX and Mojo from the Modular channel.

## Option B: uv

```bash
curl -LsSf https://astral.sh/uv/install.sh | sh
uv sync --python 3.11
uv run mojo --version
```

This reads `pyproject.toml`, which pins Mojo to the nightly index.

!!! warning
    Do not use the stable PyPI index. It ships Mojo 0.26.x, which still uses the
    old `fn` and `alias` syntax and will not compile mojogram. The `pyproject.toml`
    already points uv at the nightly index. The macOS system Python is 3.9, which
    is too old, so use 3.11.

## One system requirement

You need `curl` on your `PATH`. That is the HTTP transport. It ships with macOS
and every mainstream Linux. You can check it at startup with `curl_available()`.

## Run the examples

```bash
export BOT_TOKEN="123456:your-token"
# or: uv run mojo run -I . examples/echo_bot.mojo
pixi run echo
pixi run form
pixi run keyboard
pixi run webhook
pixi run test
```

To use mojogram from your own file, put the package on the import path:

```bash
mojo run -I /path/to/mojogram yourbot.mojo
```
