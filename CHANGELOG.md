# Changelog

All notable changes to mojogram. Versions track features, not Mojo releases.

## 0.4.0

Toolchains. Both pixi (`pixi.toml`) and uv (`pyproject.toml`, Python 3.11+) work
now. Mojo is pinned to the nightly index (the 1.0 line); stable PyPI (0.26.x) is
incompatible.

Bot API coverage, around 60 typed methods:

- Updates: `allowed_updates` on `get_updates`, `Poller`, and `set_webhook`
  (needed to receive `message_reaction`, `chat_member`, and so on).
- Polls and reactions: `send_poll` (and quiz), `set_message_reaction`,
  `edit_message_media`.
- Payments and Telegram Stars: `send_invoice`, `create_invoice_link`,
  `refund_star_payment`, `get_my_star_balance`, `answer_shipping_query`.
- Stickers and topics: `get_sticker_set`, `create_forum_topic`,
  `delete_forum_topic`.
- Media send methods now accept `reply_markup`.

Keyboards:

- Inline `web_app` buttons (Mini Apps).
- Bot API 9.4 button `style` (danger/primary/success colors) and
  `icon_custom_emoji_id` on both inline and reply keyboards.
- `ReplyKeyboard` `request_contact` and `request_location`.

New modules:

- `inline.mojo`, inline-query result builders (`inline_article`, `inline_photo`,
  `inline_results`).
- `i18n.mojo`, an `I18n` translation catalog with locale fallback.
- `sync.mojo`, a `Spinlock` shared by the FSM and the RateLimiter.

Webhook: `WebhookServer` validates Telegram's secret-token header.

Quality: load and soak tested at 500k sequential plus 200k parallel parses with
no crash. Added LICENSE (MIT), this changelog, and CI that builds and runs the
tests on pixi and uv.

## 0.3.0

- De-cloned naming (`Poller`/`State`/`Match`/`InlineKeyboard`), removed all
  third-party-framework references.

## 0.2.0

- Pure-Mojo rewrite: hand-written JSON, curl transport, `parallelize`
  concurrency, Atomic-spinlock FSM, retry/429, RateLimiter, webhook server.
