"""The request layer over the curl transport, with retry and rate-limit handling.

It builds the URL, parses Telegram's response envelope, and retries transient
failures: network errors, HTTP 5xx, and 429 rate-limits (it honours the
retry_after value Telegram sends). Permanent client errors like 400, 401, 403
and 404 raise straight away.
"""
from std.time import sleep
from mojogram.http import http_post_json, http_post_multipart
from mojogram.json import JSON, parse

comptime MAX_RETRIES = 3


struct Session(ImplicitlyCopyable, Movable):
    var base_url: String
    var timeout: Int
    var slot: Int          # worker id for thread-safe temp-file naming

    def __init__(out self, token: String, api_base: String = "https://api.telegram.org", timeout: Int = 60):
        self.base_url = api_base + "/bot" + token
        self.timeout = timeout
        self.slot = 0

    def call(self, method: String, body_json: String) raises -> JSON:
        """POST JSON to /method with retry on transient failure; return `result`."""
        var url = self.base_url + "/" + method
        var attempt = 0
        while True:
            var text = http_post_json(url, body_json, self.timeout, self.slot)
            attempt += 1
            var doc = self._parse(text)
            if self._ok(doc):
                return doc.get("result")
            self._guard(method, doc, attempt)        # raises on permanent / exhausted
            self._backoff(doc, attempt)              # transient: sleep, then loop

    def call_multipart(
        self,
        method: String,
        field_names: List[String],
        field_values: List[String],
        file_field: String,
        file_path: String,
    ) raises -> JSON:
        """POST multipart/form-data (file upload) to /method; unwrap `result`.

        Uploads take the same retry path as JSON calls, since they are the most
        likely to hit a transient 5xx mid-transfer."""
        var url = self.base_url + "/" + method
        var attempt = 0
        while True:
            var text = http_post_multipart(
                url, field_names, field_values, file_field, file_path, self.timeout, self.slot
            )
            attempt += 1
            var doc = self._parse(text)
            if self._ok(doc):
                return doc.get("result")
            self._guard(method, doc, attempt)
            self._backoff(doc, attempt)

    def _parse(self, text: String) raises -> JSON:
        """Parse defensively: curl errors / partial output aren't valid JSON, so a
        bad response becomes an empty doc (treated as a transient failure) rather
        than crashing the caller with a parser error."""
        try:
            return parse(text)
        except:
            return parse("{}")

    def _ok(self, doc: JSON) raises -> Bool:
        return doc.has("ok") and doc.get("ok").as_bool()

    def _guard(self, method: String, doc: JSON, attempt: Int) raises:
        """Raise on a permanent client error, or once retries are spent."""
        if doc.has("ok"):
            var code = doc.get("error_code").as_int()
            if code != 429 and code < 500 and code != 0:
                raise Error(
                    "Telegram API error [" + String(code) + "] on " + method
                    + ": " + doc.get("description").as_string()
                )
        if attempt > MAX_RETRIES:
            if doc.has("ok"):
                raise Error(
                    "Telegram API error [" + String(doc.get("error_code").as_int())
                    + "] on " + method + " after " + String(MAX_RETRIES) + " retries"
                )
            raise Error("transport failure on " + method + " after " + String(MAX_RETRIES) + " retries")

    def _backoff(self, doc: JSON, attempt: Int) raises:
        """Transient failure: 429 honours retry_after, everything else gets a
        linear backoff. Sleeps in place; the caller loops afterwards."""
        var wait = Float64(attempt) * 0.5
        if doc.has("ok") and doc.get("error_code").as_int() == 429:
            var ra = doc.get("parameters").get("retry_after").as_int()
            wait = Float64(ra) if ra > 0 else 1.0
        sleep(wait)
