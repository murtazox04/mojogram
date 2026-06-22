"""The HTTP transport: the system curl CLI driven through subprocess.run.

Mojo 1.0 has no native TLS and no stable dynamic loader for binding libcurl, so
the dependable path is to drive the curl binary that ships on every machine. The
Telegram Bot API is just HTTPS POST with JSON, which curl handles well.

Every call takes a slot, a small worker id. Temp files are named per slot, so
concurrent calls under parallelize never clobber each other; sequential code uses
slot 0. Request bodies and field values are written to temp files, and every
value that does end up on the command line (URLs, paths, field names) is passed
through _shq() so a stray quote can't break out of the shell.

curl has to be on PATH.
"""
from std.subprocess import run
from std.os.path import exists


def _shq(s: String) -> String:
    """Quote s as one safe shell token. A literal ' becomes '\\'' so the value
    can never escape its surrounding single quotes into the command."""
    return "'" + s.replace("'", "'\\''") + "'"


def curl_available() raises -> Bool:
    """True if the `curl` binary is on PATH. Call at startup for a clear error."""
    return "OK" in run("command -v curl >/dev/null 2>&1 && echo OK || echo NO")


def http_download(url: String, dest: String, timeout: Int = 120) raises -> Bool:
    """Download `url` to `dest` via curl; True if a non-empty file resulted."""
    _ = run("curl -sS -m " + String(timeout) + " -o " + _shq(dest) + " " + _shq(url))
    return exists(dest)


def http_post_json(url: String, body: String, timeout: Int = 60, slot: Int = 0) raises -> String:
    """POST `body` as application/json; return the response body text."""
    var req = "/tmp/mojogram_req_" + String(slot) + ".json"
    with open(req, "w") as f:
        f.write(body)
    var cmd = (
        "curl -sS -m " + String(timeout)
        + " -X POST -H 'Content-Type: application/json'"
        + " --data-binary @" + req
        + " " + _shq(url)
    )
    return run(cmd)


def http_post_multipart(
    url: String,
    field_names: List[String],
    field_values: List[String],
    file_field: String,
    file_path: String,
    timeout: Int = 120,
    slot: Int = 0,
) raises -> String:
    """POST multipart/form-data: text fields plus one file. Field values go to
    temp files; the file path and field names are shell-escaped via _shq()."""
    var cmd = String("curl -sS -m ") + String(timeout)
    for i in range(len(field_names)):
        var vpath = "/tmp/mojogram_f" + String(slot) + "_" + String(i) + ".txt"
        with open(vpath, "w") as f:
            f.write(field_values[i])
        cmd += " -F " + _shq(field_names[i] + "=<" + vpath)
    cmd += " -F " + _shq(file_field + "=@" + file_path)
    cmd += " " + _shq(url)
    return run(cmd)
