"""Typed wrappers over the Telegram Bot API.

This covers the commonly used methods directly. The other 120-odd methods go
through call() and call_raw(). Wrapping a new one by hand takes about four lines
when a bot needs it.
"""
from mojogram.client import Session
from mojogram.json import JSON, Params, quote
from mojogram.types import Message, User, Chat
from mojogram.http import http_download


struct Bot(ImplicitlyCopyable, Movable):
    var session: Session
    var token: String
    var api_base: String

    def __init__(out self, token: String, api_base: String = "https://api.telegram.org", timeout: Int = 60):
        self.token = token
        self.api_base = api_base
        self.session = Session(token, api_base, timeout)

    def with_slot(self, i: Int) -> Bot:
        """A copy bound to worker `i` (thread-safe temp files under parallelize)."""
        var b = self
        b.session.slot = i
        return b^

    # ---- generic escape hatch -------------------------------------------
    def call(self, method: String, params: Params) raises -> JSON:
        return self.session.call(method, params.build())

    def call_raw(self, method: String, body_json: String) raises -> JSON:
        return self.session.call(method, body_json)

    # ---- account / bot info ---------------------------------------------
    def get_me(self) raises -> User:
        return User(self.session.call("getMe", "{}"))

    def log_out(self) raises -> Bool:
        return self.session.call("logOut", "{}").as_bool()

    def close_bot(self) raises -> Bool:
        return self.session.call("close", "{}").as_bool()

    # ---- updates / webhook ----------------------------------------------
    def get_updates(self, offset: Int, timeout: Int = 30, limit: Int = 100, allowed_updates: String = "") raises -> JSON:
        # allowed_updates: a JSON array string, e.g. '["message","callback_query","message_reaction","chat_member"]'.
        # Telegram omits message_reaction and chat_member by default, so pass them here to receive them.
        var p = Params()
        p.put_int("offset", offset)
        p.put_int("timeout", timeout)
        p.put_int("limit", limit)
        if allowed_updates != "":
            p.put_raw("allowed_updates", allowed_updates)
        return self.session.call("getUpdates", p.build())

    def set_webhook(self, url: String, secret_token: String = "", allowed_updates: String = "") raises -> Bool:
        var p = Params()
        p.put_str("url", url)
        if secret_token != "":
            p.put_str("secret_token", secret_token)
        if allowed_updates != "":
            p.put_raw("allowed_updates", allowed_updates)
        return self.session.call("setWebhook", p.build()).as_bool()

    def delete_webhook(self, drop_pending: Bool = False) raises -> Bool:
        var p = Params()
        p.put_bool("drop_pending_updates", drop_pending)
        return self.session.call("deleteWebhook", p.build()).as_bool()

    def get_webhook_info(self) raises -> JSON:
        return self.session.call("getWebhookInfo", "{}")

    # ---- sending messages ------------------------------------------------
    def send_message(
        self,
        chat_id: Int,
        text: String,
        parse_mode: String = "",
        reply_markup: String = "",
        reply_to_message_id: Int = 0,
        disable_notification: Bool = False,
    ) raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("text", text)
        if parse_mode != "":
            p.put_str("parse_mode", parse_mode)
        if reply_to_message_id != 0:
            p.put_int("reply_to_message_id", reply_to_message_id)
        if disable_notification:
            p.put_bool("disable_notification", True)
        if reply_markup != "":
            p.put_raw("reply_markup", reply_markup)
        return Message(self.session.call("sendMessage", p.build()))

    def send_photo(self, chat_id: Int, photo: String, caption: String = "", parse_mode: String = "", reply_markup: String = "") raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("photo", photo)
        if caption != "":
            p.put_str("caption", caption)
        if parse_mode != "":
            p.put_str("parse_mode", parse_mode)
        if reply_markup != "":
            p.put_raw("reply_markup", reply_markup)
        return Message(self.session.call("sendPhoto", p.build()))

    def send_document(self, chat_id: Int, document: String, caption: String = "", reply_markup: String = "") raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("document", document)
        if caption != "":
            p.put_str("caption", caption)
        if reply_markup != "":
            p.put_raw("reply_markup", reply_markup)
        return Message(self.session.call("sendDocument", p.build()))

    def send_video(self, chat_id: Int, video: String, caption: String = "", reply_markup: String = "") raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("video", video)
        if caption != "":
            p.put_str("caption", caption)
        if reply_markup != "":
            p.put_raw("reply_markup", reply_markup)
        return Message(self.session.call("sendVideo", p.build()))

    def send_audio(self, chat_id: Int, audio: String, caption: String = "", reply_markup: String = "") raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("audio", audio)
        if caption != "":
            p.put_str("caption", caption)
        if reply_markup != "":
            p.put_raw("reply_markup", reply_markup)
        return Message(self.session.call("sendAudio", p.build()))

    def send_voice(self, chat_id: Int, voice: String) raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("voice", voice)
        return Message(self.session.call("sendVoice", p.build()))

    def send_sticker(self, chat_id: Int, sticker: String) raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("sticker", sticker)
        return Message(self.session.call("sendSticker", p.build()))

    def send_location(self, chat_id: Int, latitude: Float64, longitude: Float64) raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_raw("latitude", String(latitude))
        p.put_raw("longitude", String(longitude))
        return Message(self.session.call("sendLocation", p.build()))

    def send_dice(self, chat_id: Int, emoji: String = "") raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        if emoji != "":
            p.put_str("emoji", emoji)
        return Message(self.session.call("sendDice", p.build()))

    def send_poll(self, chat_id: Int, question: String, options: List[String], is_anonymous: Bool = True, quiz: Bool = False, correct_option_id: Int = -1, allows_multiple_answers: Bool = False) raises -> Message:
        """Send a poll. quiz=True makes it a quiz (set correct_option_id)."""
        var opts = String("[")
        for i in range(len(options)):
            if i > 0:
                opts += ","
            opts += "{" + quote("text") + ":" + quote(options[i]) + "}"
        opts += "]"
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("question", question)
        p.put_raw("options", opts)
        p.put_bool("is_anonymous", is_anonymous)
        if quiz:
            p.put_str("type", "quiz")
            if correct_option_id >= 0:
                p.put_int("correct_option_id", correct_option_id)
        if allows_multiple_answers:
            p.put_bool("allows_multiple_answers", True)
        return Message(self.session.call("sendPoll", p.build()))

    def set_message_reaction(self, chat_id: Int, message_id: Int, emoji: String, is_big: Bool = False) raises -> Bool:
        """React to a message with an emoji ("" clears the reaction)."""
        var reaction = String("[]")
        if emoji != "":
            reaction = "[{" + quote("type") + ":" + quote("emoji") + "," + quote("emoji") + ":" + quote(emoji) + "}]"
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("message_id", message_id)
        p.put_raw("reaction", reaction)
        if is_big:
            p.put_bool("is_big", True)
        return self.session.call("setMessageReaction", p.build()).as_bool()

    def edit_message_media(self, chat_id: Int, message_id: Int, media_json: String, reply_markup: String = "") raises -> Message:
        """Edit a message's media. media_json = an InputMedia object, e.g.
        '{"type":"photo","media":"<url-or-file_id>","caption":"..."}'."""
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("message_id", message_id)
        p.put_raw("media", media_json)
        if reply_markup != "":
            p.put_raw("reply_markup", reply_markup)
        return Message(self.session.call("editMessageMedia", p.build()))

    def send_chat_action(self, chat_id: Int, action: String) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("action", action)
        return self.session.call("sendChatAction", p.build()).as_bool()

    def forward_message(self, chat_id: Int, from_chat_id: Int, message_id: Int) raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("from_chat_id", from_chat_id)
        p.put_int("message_id", message_id)
        return Message(self.session.call("forwardMessage", p.build()))

    def copy_message(self, chat_id: Int, from_chat_id: Int, message_id: Int) raises -> JSON:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("from_chat_id", from_chat_id)
        p.put_int("message_id", message_id)
        return self.session.call("copyMessage", p.build())

    # ---- editing / deleting ---------------------------------------------
    def edit_message_text(self, chat_id: Int, message_id: Int, text: String, parse_mode: String = "", reply_markup: String = "") raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("message_id", message_id)
        p.put_str("text", text)
        if parse_mode != "":
            p.put_str("parse_mode", parse_mode)
        if reply_markup != "":
            p.put_raw("reply_markup", reply_markup)
        return Message(self.session.call("editMessageText", p.build()))

    def edit_message_caption(self, chat_id: Int, message_id: Int, caption: String) raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("message_id", message_id)
        p.put_str("caption", caption)
        return Message(self.session.call("editMessageCaption", p.build()))

    def edit_message_reply_markup(self, chat_id: Int, message_id: Int, reply_markup: String) raises -> Message:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("message_id", message_id)
        p.put_raw("reply_markup", reply_markup)
        return Message(self.session.call("editMessageReplyMarkup", p.build()))

    def delete_message(self, chat_id: Int, message_id: Int) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("message_id", message_id)
        return self.session.call("deleteMessage", p.build()).as_bool()

    # ---- answering queries ----------------------------------------------
    def answer_callback_query(self, callback_query_id: String, text: String = "", show_alert: Bool = False) raises -> Bool:
        var p = Params()
        p.put_str("callback_query_id", callback_query_id)
        if text != "":
            p.put_str("text", text)
        if show_alert:
            p.put_bool("show_alert", True)
        return self.session.call("answerCallbackQuery", p.build()).as_bool()

    def answer_inline_query(self, inline_query_id: String, results_json: String) raises -> Bool:
        var p = Params()
        p.put_str("inline_query_id", inline_query_id)
        p.put_raw("results", results_json)
        return self.session.call("answerInlineQuery", p.build()).as_bool()

    def answer_pre_checkout_query(self, pre_checkout_query_id: String, ok: Bool, error_message: String = "") raises -> Bool:
        var p = Params()
        p.put_str("pre_checkout_query_id", pre_checkout_query_id)
        p.put_bool("ok", ok)
        if error_message != "":
            p.put_str("error_message", error_message)
        return self.session.call("answerPreCheckoutQuery", p.build()).as_bool()

    # ---- chat management -------------------------------------------------
    def get_chat(self, chat_id: Int) raises -> Chat:
        var p = Params()
        p.put_int("chat_id", chat_id)
        return Chat(self.session.call("getChat", p.build()))

    def get_chat_member_count(self, chat_id: Int) raises -> Int:
        var p = Params()
        p.put_int("chat_id", chat_id)
        return self.session.call("getChatMemberCount", p.build()).as_int()

    def get_chat_member(self, chat_id: Int, user_id: Int) raises -> JSON:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("user_id", user_id)
        return self.session.call("getChatMember", p.build())

    def ban_chat_member(self, chat_id: Int, user_id: Int) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("user_id", user_id)
        return self.session.call("banChatMember", p.build()).as_bool()

    def unban_chat_member(self, chat_id: Int, user_id: Int) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("user_id", user_id)
        return self.session.call("unbanChatMember", p.build()).as_bool()

    def leave_chat(self, chat_id: Int) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        return self.session.call("leaveChat", p.build()).as_bool()

    def pin_chat_message(self, chat_id: Int, message_id: Int) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("message_id", message_id)
        return self.session.call("pinChatMessage", p.build()).as_bool()

    def unpin_chat_message(self, chat_id: Int, message_id: Int = 0) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        if message_id != 0:
            p.put_int("message_id", message_id)
        return self.session.call("unpinChatMessage", p.build()).as_bool()

    def approve_chat_join_request(self, chat_id: Int, user_id: Int) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("user_id", user_id)
        return self.session.call("approveChatJoinRequest", p.build()).as_bool()

    def decline_chat_join_request(self, chat_id: Int, user_id: Int) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("user_id", user_id)
        return self.session.call("declineChatJoinRequest", p.build()).as_bool()

    # ---- bot commands ----------------------------------------------------
    def set_my_commands(self, commands_json: String) raises -> Bool:
        var p = Params()
        p.put_raw("commands", commands_json)
        return self.session.call("setMyCommands", p.build()).as_bool()

    def delete_my_commands(self) raises -> Bool:
        return self.session.call("deleteMyCommands", "{}").as_bool()

    def get_my_commands(self) raises -> JSON:
        return self.session.call("getMyCommands", "{}")

    def send_media_group(self, chat_id: Int, media_json: String) raises -> JSON:
        """Send an album. `media_json` is a JSON array of InputMedia objects."""
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_raw("media", media_json)
        return self.session.call("sendMediaGroup", p.build())

    # ---- files -----------------------------------------------------------
    def get_file(self, file_id: String) raises -> JSON:
        var p = Params()
        p.put_str("file_id", file_id)
        return self.session.call("getFile", p.build())

    def download_file(self, file_id: String, dest: String) raises -> Bool:
        """Resolve the file via getFile, then download its bytes to `dest`."""
        var file_path = self.get_file(file_id).get("file_path").as_string()
        if file_path == "":
            return False
        var url = self.api_base + "/file/bot" + self.token + "/" + file_path
        return http_download(url, dest)

    # ---- file uploads (multipart) ---------------------------------------
    def _upload(self, method: String, chat_id: Int, file_field: String, file_path: String, caption: String) raises -> Message:
        var names = List[String]()
        var values = List[String]()
        names.append("chat_id")
        values.append(String(chat_id))
        if caption != "":
            names.append("caption")
            values.append(caption)
        return Message(self.session.call_multipart(method, names, values, file_field, file_path))

    def send_photo_file(self, chat_id: Int, path: String, caption: String = "") raises -> Message:
        """Upload a local photo file (multipart)."""
        return self._upload("sendPhoto", chat_id, "photo", path, caption)

    def send_document_file(self, chat_id: Int, path: String, caption: String = "") raises -> Message:
        """Upload a local document file (multipart)."""
        return self._upload("sendDocument", chat_id, "document", path, caption)

    def send_video_file(self, chat_id: Int, path: String, caption: String = "") raises -> Message:
        """Upload a local video file (multipart)."""
        return self._upload("sendVideo", chat_id, "video", path, caption)

    # ---- payments / Telegram Stars --------------------------------------
    def send_invoice(self, chat_id: Int, title: String, description: String, payload: String, currency: String, prices_json: String, provider_token: String = "") raises -> Message:
        """Send an invoice. For Telegram Stars: currency="XTR", provider_token="".
        prices_json e.g. '[{"label":"Item","amount":500}]'."""
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("title", title)
        p.put_str("description", description)
        p.put_str("payload", payload)
        p.put_str("currency", currency)
        p.put_raw("prices", prices_json)
        if provider_token != "":
            p.put_str("provider_token", provider_token)
        return Message(self.session.call("sendInvoice", p.build()))

    def create_invoice_link(self, title: String, description: String, payload: String, currency: String, prices_json: String, provider_token: String = "") raises -> String:
        var p = Params()
        p.put_str("title", title)
        p.put_str("description", description)
        p.put_str("payload", payload)
        p.put_str("currency", currency)
        p.put_raw("prices", prices_json)
        if provider_token != "":
            p.put_str("provider_token", provider_token)
        return self.session.call("createInvoiceLink", p.build()).as_string()

    def answer_shipping_query(self, shipping_query_id: String, ok: Bool, error_message: String = "") raises -> Bool:
        var p = Params()
        p.put_str("shipping_query_id", shipping_query_id)
        p.put_bool("ok", ok)
        if error_message != "":
            p.put_str("error_message", error_message)
        return self.session.call("answerShippingQuery", p.build()).as_bool()

    def refund_star_payment(self, user_id: Int, telegram_payment_charge_id: String) raises -> Bool:
        var p = Params()
        p.put_int("user_id", user_id)
        p.put_str("telegram_payment_charge_id", telegram_payment_charge_id)
        return self.session.call("refundStarPayment", p.build()).as_bool()

    def get_my_star_balance(self) raises -> JSON:
        return self.session.call("getMyStarBalance", "{}")

    # ---- stickers / forum topics ----------------------------------------
    def get_sticker_set(self, name: String) raises -> JSON:
        var p = Params()
        p.put_str("name", name)
        return self.session.call("getStickerSet", p.build())

    def create_forum_topic(self, chat_id: Int, name: String) raises -> JSON:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_str("name", name)
        return self.session.call("createForumTopic", p.build())

    def delete_forum_topic(self, chat_id: Int, message_thread_id: Int) raises -> Bool:
        var p = Params()
        p.put_int("chat_id", chat_id)
        p.put_int("message_thread_id", message_thread_id)
        return self.session.call("deleteForumTopic", p.build()).as_bool()
