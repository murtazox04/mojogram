"""Typed views over Telegram objects, backed by the pure-Mojo JSON DOM.

Every type wraps a `JSON` handle and exposes typed accessors. Fields not given a
named accessor are still reachable via `.json.get("field")`, so the whole Bot API
object graph is accessible even where we haven't hand-written a getter.
"""
from mojogram.json import JSON


struct User(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def id(self) -> Int:
        return self.json.get("id").as_int()

    def is_bot(self) -> Bool:
        return self.json.get("is_bot").as_bool()

    def first_name(self) -> String:
        return self.json.get("first_name").as_string()

    def last_name(self) -> String:
        return self.json.get("last_name").as_string()

    def username(self) -> String:
        return self.json.get("username").as_string()

    def language_code(self) -> String:
        return self.json.get("language_code").as_string()

    def is_premium(self) -> Bool:
        return self.json.get("is_premium").as_bool()

    def full_name(self) -> String:
        var last = self.last_name()
        if last != "":
            return self.first_name() + " " + last
        return self.first_name()


struct Chat(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def id(self) -> Int:
        return self.json.get("id").as_int()

    def type(self) -> String:
        return self.json.get("type").as_string()

    def title(self) -> String:
        return self.json.get("title").as_string()

    def username(self) -> String:
        return self.json.get("username").as_string()

    def first_name(self) -> String:
        return self.json.get("first_name").as_string()

    def is_private(self) -> Bool:
        return self.type() == "private"

    def is_group(self) -> Bool:
        var t = self.type()
        return t == "group" or t == "supergroup"


struct Message(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def message_id(self) -> Int:
        return self.json.get("message_id").as_int()

    def date(self) -> Int:
        return self.json.get("date").as_int()

    def text(self) -> String:
        return self.json.get("text").as_string()

    def caption(self) -> String:
        return self.json.get("caption").as_string()

    def chat(self) -> Chat:
        return Chat(self.json.get("chat"))

    def chat_id(self) -> Int:
        return self.json.get("chat").get("id").as_int()

    def from_user(self) -> User:
        return User(self.json.get("from"))

    def reply_to_message(self) -> Message:
        return Message(self.json.get("reply_to_message"))

    def has(self, key: String) -> Bool:
        return self.json.has(key)

    def content_type(self) -> String:
        """The kind of content this message carries."""
        var j = self.json
        if j.has("text"):
            return "text"
        elif j.has("photo"):
            return "photo"
        elif j.has("animation"):
            return "animation"
        elif j.has("audio"):
            return "audio"
        elif j.has("document"):
            return "document"
        elif j.has("sticker"):
            return "sticker"
        elif j.has("story"):
            return "story"
        elif j.has("video"):
            return "video"
        elif j.has("video_note"):
            return "video_note"
        elif j.has("voice"):
            return "voice"
        elif j.has("contact"):
            return "contact"
        elif j.has("dice"):
            return "dice"
        elif j.has("game"):
            return "game"
        elif j.has("poll"):
            return "poll"
        elif j.has("venue"):
            return "venue"
        elif j.has("location"):
            return "location"
        elif j.has("new_chat_members"):
            return "new_chat_members"
        elif j.has("left_chat_member"):
            return "left_chat_member"
        elif j.has("pinned_message"):
            return "pinned_message"
        elif j.has("invoice"):
            return "invoice"
        elif j.has("successful_payment"):
            return "successful_payment"
        return "unknown"


struct CallbackQuery(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def id(self) -> String:
        return self.json.get("id").as_string()

    def data(self) -> String:
        return self.json.get("data").as_string()

    def from_user(self) -> User:
        return User(self.json.get("from"))

    def message(self) -> Message:
        return Message(self.json.get("message"))

    def chat_instance(self) -> String:
        return self.json.get("chat_instance").as_string()

    def inline_message_id(self) -> String:
        return self.json.get("inline_message_id").as_string()

    def chat_id(self) -> Int:
        return self.json.get("message").get("chat").get("id").as_int()


struct InlineQuery(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def id(self) -> String:
        return self.json.get("id").as_string()

    def query(self) -> String:
        return self.json.get("query").as_string()

    def offset(self) -> String:
        return self.json.get("offset").as_string()

    def from_user(self) -> User:
        return User(self.json.get("from"))


struct ChosenInlineResult(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def result_id(self) -> String:
        return self.json.get("result_id").as_string()

    def query(self) -> String:
        return self.json.get("query").as_string()

    def from_user(self) -> User:
        return User(self.json.get("from"))


struct Poll(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def id(self) -> String:
        return self.json.get("id").as_string()

    def question(self) -> String:
        return self.json.get("question").as_string()

    def is_closed(self) -> Bool:
        return self.json.get("is_closed").as_bool()

    def total_voter_count(self) -> Int:
        return self.json.get("total_voter_count").as_int()


struct PollAnswer(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def poll_id(self) -> String:
        return self.json.get("poll_id").as_string()

    def from_user(self) -> User:
        return User(self.json.get("user"))

    def option_count(self) -> Int:
        return self.json.get("option_ids").len()


struct PreCheckoutQuery(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def id(self) -> String:
        return self.json.get("id").as_string()

    def currency(self) -> String:
        return self.json.get("currency").as_string()

    def total_amount(self) -> Int:
        return self.json.get("total_amount").as_int()

    def payload(self) -> String:
        return self.json.get("invoice_payload").as_string()

    def from_user(self) -> User:
        return User(self.json.get("from"))


struct ShippingQuery(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def id(self) -> String:
        return self.json.get("id").as_string()

    def payload(self) -> String:
        return self.json.get("invoice_payload").as_string()

    def from_user(self) -> User:
        return User(self.json.get("from"))


struct ChatMemberUpdated(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def chat(self) -> Chat:
        return Chat(self.json.get("chat"))

    def from_user(self) -> User:
        return User(self.json.get("from"))

    def old_status(self) -> String:
        return self.json.get("old_chat_member").get("status").as_string()

    def new_status(self) -> String:
        return self.json.get("new_chat_member").get("status").as_string()


struct ChatJoinRequest(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def chat(self) -> Chat:
        return Chat(self.json.get("chat"))

    def from_user(self) -> User:
        return User(self.json.get("from"))

    def bio(self) -> String:
        return self.json.get("bio").as_string()


struct Update(ImplicitlyCopyable, Movable):
    var json: JSON

    def __init__(out self, json: JSON):
        self.json = json

    def update_id(self) -> Int:
        return self.json.get("update_id").as_int()

    def has(self, key: String) -> Bool:
        return self.json.has(key)

    def type(self) -> String:
        """Which event this update carries (the present field name)."""
        # Checked directly (no split/StringSlice) in Telegram's priority order.
        if self.json.has("message"):
            return "message"
        if self.json.has("edited_message"):
            return "edited_message"
        if self.json.has("channel_post"):
            return "channel_post"
        if self.json.has("edited_channel_post"):
            return "edited_channel_post"
        if self.json.has("inline_query"):
            return "inline_query"
        if self.json.has("chosen_inline_result"):
            return "chosen_inline_result"
        if self.json.has("callback_query"):
            return "callback_query"
        if self.json.has("shipping_query"):
            return "shipping_query"
        if self.json.has("pre_checkout_query"):
            return "pre_checkout_query"
        if self.json.has("poll"):
            return "poll"
        if self.json.has("poll_answer"):
            return "poll_answer"
        if self.json.has("my_chat_member"):
            return "my_chat_member"
        if self.json.has("chat_member"):
            return "chat_member"
        if self.json.has("chat_join_request"):
            return "chat_join_request"
        if self.json.has("message_reaction"):
            return "message_reaction"
        return "unknown"

    def event(self, key: String) -> JSON:
        """Raw JSON of a named sub-event."""
        return self.json.get(key)

    # Typed convenience accessors for the common events.
    def has_message(self) -> Bool:
        return self.json.has("message")

    def message(self) -> Message:
        return Message(self.json.get("message"))

    def has_edited_message(self) -> Bool:
        return self.json.has("edited_message")

    def edited_message(self) -> Message:
        return Message(self.json.get("edited_message"))

    def has_channel_post(self) -> Bool:
        return self.json.has("channel_post")

    def channel_post(self) -> Message:
        return Message(self.json.get("channel_post"))

    def has_callback_query(self) -> Bool:
        return self.json.has("callback_query")

    def callback_query(self) -> CallbackQuery:
        return CallbackQuery(self.json.get("callback_query"))

    def inline_query(self) -> InlineQuery:
        return InlineQuery(self.json.get("inline_query"))

    def chosen_inline_result(self) -> ChosenInlineResult:
        return ChosenInlineResult(self.json.get("chosen_inline_result"))

    def poll(self) -> Poll:
        return Poll(self.json.get("poll"))

    def poll_answer(self) -> PollAnswer:
        return PollAnswer(self.json.get("poll_answer"))

    def pre_checkout_query(self) -> PreCheckoutQuery:
        return PreCheckoutQuery(self.json.get("pre_checkout_query"))

    def shipping_query(self) -> ShippingQuery:
        return ShippingQuery(self.json.get("shipping_query"))

    def my_chat_member(self) -> ChatMemberUpdated:
        return ChatMemberUpdated(self.json.get("my_chat_member"))

    def chat_member(self) -> ChatMemberUpdated:
        return ChatMemberUpdated(self.json.get("chat_member"))

    def chat_join_request(self) -> ChatJoinRequest:
        return ChatJoinRequest(self.json.get("chat_join_request"))
