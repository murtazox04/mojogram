"""The Poller owns the bot, the FSM storage, and the long-poll offset.

Mojo can't store a list of mixed handler functions, so instead of a hidden
registry mojogram uses a plain loop: you pull updates and call your own handler.
Nothing to dispatch through, and the compiler still checks the whole path.

    var dp = Poller(Bot(token))
    while True:
        var ups = dp.poll()
        for i in range(ups.len()):
            handle(dp.context(Update(ups.at(i))))
"""
from mojogram.bot import Bot
from mojogram.fsm import StateStore, State
from mojogram.context import UpdateContext
from mojogram.types import Update
from mojogram.json import JSON


struct Poller(ImplicitlyCopyable, Movable):
    var bot: Bot
    var storage: StateStore
    var offset: Int
    var allowed: String   # allowed_updates JSON array; "" = Telegram default

    def __init__(out self, bot: Bot, allowed_updates: String = ""):
        # Pass e.g. '["message","callback_query","message_reaction","chat_member"]'
        # to receive reaction/member events (excluded by default).
        self.bot = bot
        self.storage = StateStore()
        self.offset = 0
        self.allowed = allowed_updates

    def poll(mut self, timeout: Int = 30) raises -> JSON:
        """Long-poll one batch of updates and advance the offset past them."""
        var ups = self.bot.get_updates(self.offset, timeout, 100, self.allowed)
        var n = ups.len()
        if n > 0:
            self.offset = Update(ups.at(n - 1)).update_id() + 1
        return ups

    def context(self, update: Update, slot: Int = 0) -> UpdateContext:
        """Wrap an update with the bot and an FSM handle bound to its chat.

        slot is the worker id. Pass the parallelize index when processing a batch
        concurrently so each worker's HTTP temp files stay separate.
        """
        var cid = 0
        if update.has_message():
            cid = update.message().chat_id()
        elif update.has_callback_query():
            cid = update.callback_query().chat_id()
        return UpdateContext(self.bot.with_slot(slot), update, State(self.storage, cid))
