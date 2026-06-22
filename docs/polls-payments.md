# Polls, payments and admin

The methods here are less common than sending text, but they're all typed and
they all sit on `ctx.bot`. Anything not wrapped is still one `call()` away.

## Polls and quizzes

`send_poll` takes the question and a list of options. Flip `quiz=True` and set
`correct_option_id` for a quiz; leave the defaults for a normal poll.

```mojo
_ = ctx.bot.send_poll(chat_id, "Tabs or spaces?", ["Tabs", "Spaces"])

_ = ctx.bot.send_poll(
    chat_id,
    "Which is a Mojo keyword?",
    ["def", "func", "method"],
    quiz=True,
    correct_option_id=0,        # zero-based index into the options
)

_ = ctx.bot.send_poll(chat_id, "Pick any", ["a", "b", "c"], allows_multiple_answers=True)
```

A quiz needs a valid `correct_option_id`; send `quiz=True` with the default `-1`
and Telegram rejects it with a 400. Poll answers come back as `poll` and
`poll_answer` updates if you enable them in `allowed_updates`.

## Reactions

Drop an emoji reaction on a message:

```mojo
_ = ctx.bot.set_message_reaction(chat_id, msg.message_id(), "👍")
_ = ctx.bot.set_message_reaction(chat_id, msg.message_id(), "🔥", is_big=True)
```

## Payments and Telegram Stars

Telegram has two payment tracks: real money through a provider, and Telegram
Stars (the `XTR` currency, no provider token). Prices are a JSON array of
labeled amounts, in the currency's smallest unit.

```mojo
# Telegram Stars: currency XTR, provider_token left empty
var prices = String('[{"label":"Pro plan","amount":500}]')   # 500 Stars
_ = ctx.bot.send_invoice(
    chat_id, "Pro", "One month of Pro", "sub_pro", "XTR", prices
)

# A shareable link instead of a chat invoice
var link = ctx.bot.create_invoice_link("Pro", "One month", "sub_pro", "XTR", prices)
```

The checkout flow sends you two query updates. Answer both, fast (Telegram gives
you about ten seconds):

```mojo
# pre_checkout_query: approve or reject right before payment
_ = ctx.bot.answer_pre_checkout_query(query_id, True)
_ = ctx.bot.answer_pre_checkout_query(query_id, False, "Out of stock")

# shipping_query, only if you asked for a shipping address
_ = ctx.bot.answer_shipping_query(query_id, True)
```

For Stars you can refund a charge and read your balance:

```mojo
_ = ctx.bot.refund_star_payment(user_id, charge_id)
var balance = ctx.bot.get_my_star_balance()
```

## Chat administration

In groups where your bot is an admin:

```mojo
var chat = ctx.bot.get_chat(chat_id)
var count = ctx.bot.get_chat_member_count(chat_id)
var member = ctx.bot.get_chat_member(chat_id, user_id)   # raw JSON: status, permissions

_ = ctx.bot.ban_chat_member(chat_id, user_id)
_ = ctx.bot.unban_chat_member(chat_id, user_id)
_ = ctx.bot.leave_chat(chat_id)

_ = ctx.bot.pin_chat_message(chat_id, msg.message_id())
_ = ctx.bot.unpin_chat_message(chat_id)                  # message_id optional: unpins the latest
```

For groups with join approval:

```mojo
_ = ctx.bot.approve_chat_join_request(chat_id, user_id)
_ = ctx.bot.decline_chat_join_request(chat_id, user_id)
```

Forum topics, in supergroups that have them on:

```mojo
var topic = ctx.bot.create_forum_topic(chat_id, "Support")
_ = ctx.bot.delete_forum_topic(chat_id, thread_id)
```

## Command menu

Register the slash-command list the Telegram client shows, so users see your
commands when they type `/`:

```mojo
var cmds = String('[{"command":"start","description":"Start"},'
                  '{"command":"help","description":"Show help"}]')
_ = ctx.bot.set_my_commands(cmds)
var current = ctx.bot.get_my_commands()
_ = ctx.bot.delete_my_commands()
```

Set the commands once at startup, not on every update.
