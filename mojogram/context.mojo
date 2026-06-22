"""Handler contexts.

`UpdateContext` is what your handler receives each update: the bot, the raw
`Update`, and an FSM handle already bound to the right chat. It also carries
convenience accessors so simple bots never touch `Update` directly.
"""
from mojogram.bot import Bot
from mojogram.types import Message, CallbackQuery, Update
from mojogram.fsm import State


struct UpdateContext(ImplicitlyCopyable, Movable):
    var bot: Bot
    var update: Update
    var state: State

    def __init__(out self, bot: Bot, update: Update, state: State):
        self.bot = bot
        self.update = update
        self.state = state

    # --- event shape ---
    def is_message(self) -> Bool:
        return self.update.has_message()

    def message(self) -> Message:
        return self.update.message()

    def is_callback(self) -> Bool:
        return self.update.has_callback_query()

    def callback(self) -> CallbackQuery:
        return self.update.callback_query()

    def chat_id(self) raises -> Int:
        if self.update.has_message():
            return self.update.message().chat_id()
        if self.update.has_callback_query():
            return self.update.callback_query().chat_id()
        return 0

    # --- convenience replies ---
    def answer(self, text: String, parse_mode: String = "", reply_markup: String = "") raises -> Message:
        return self.bot.send_message(self.chat_id(), text, parse_mode, reply_markup)

    def reply(self, text: String) raises -> Message:
        var mid = self.update.message().message_id()
        return self.bot.send_message(self.chat_id(), text, "", "", mid)

    def ack(self, text: String = "") raises:
        """Acknowledge a callback query (stops the client spinner)."""
        _ = self.bot.answer_callback_query(self.update.callback_query().id(), text)
