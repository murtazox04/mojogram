# mojogram webhook worker image.
# NOTE: pulls the MAX/Mojo toolchain (large, ~GB) on first build.
FROM ubuntu:24.04

RUN apt-get update \
 && apt-get install -y --no-install-recommends curl ca-certificates git \
 && rm -rf /var/lib/apt/lists/*

# pixi → MAX/Mojo
RUN curl -fsSL https://pixi.sh/install.sh | bash
ENV PATH="/root/.pixi/bin:${PATH}"

WORKDIR /app
COPY pixi.toml .
RUN pixi install
COPY mojogram ./mojogram
COPY examples ./examples

EXPOSE 8080
# BOT_TOKEN is injected at runtime (compose env). curl is the HTTP transport.
CMD ["pixi", "run", "mojo", "run", "-I", ".", "examples/webhook_bot.mojo"]
