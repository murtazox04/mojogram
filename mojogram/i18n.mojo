"""A tiny translation catalog for internationalization.

You register strings per locale and look them up with a fallback chain: first
the requested locale, then the default locale, and finally the key itself. It is
thread-safe through a Spinlock and shareable like the FSM store.

    var i18n = I18n("en")
    i18n.add("en", "hello", "Hello!")
    i18n.add("uz", "hello", "Salom!")
    _ = ctx.answer(i18n.t("uz", "hello"))   # -> "Salom!"
"""
from std.collections import Dict
from std.memory import ArcPointer
from mojogram.sync import Spinlock


struct I18n(ImplicitlyCopyable, Movable):
    var catalog: ArcPointer[Dict[String, String]]   # "<locale>\t<key>" -> text
    var default_locale: String
    var lock: Spinlock

    def __init__(out self, default_locale: String = "en"):
        self.catalog = ArcPointer(Dict[String, String]())
        self.default_locale = default_locale
        self.lock = Spinlock()

    def _k(self, locale: String, key: String) -> String:
        return locale + "\t" + key

    def add(self, locale: String, key: String, text: String):
        self.lock.acquire()
        self.catalog[][self._k(locale, key)] = text
        self.lock.release()

    def t(self, locale: String, key: String, fallback: String = "") raises -> String:
        self.lock.acquire()
        var lk = self._k(locale, key)
        var dk = self._k(self.default_locale, key)
        var out = fallback if fallback != "" else key
        if lk in self.catalog[]:
            out = self.catalog[][lk]
        elif dk in self.catalog[]:
            out = self.catalog[][dk]
        self.lock.release()
        return out
