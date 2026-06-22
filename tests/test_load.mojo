"""Load/soak test: sustained parsing + parallel load, checking stability."""
from mojogram import parse
from std.time import perf_counter_ns
from std.algorithm import parallelize

def main() raises:
    var upd = String('{"update_id":123,"message":{"message_id":9,"date":1700000000,"text":"Salom 🎉 мир test message","chat":{"id":-1001234567890,"type":"supergroup","title":"G"},"from":{"id":42,"is_bot":false,"first_name":"User","username":"u"}}}')
    # 1) soak. 500k parse+access (arena alloc/free each time)
    var n = 500000
    var t0 = perf_counter_ns()
    var sink = 0
    for i in range(n):
        var d = parse(upd)
        sink += d.get("message").get("chat").get("id").as_int()
    var t1 = perf_counter_ns()
    print("soak:", n, "parses in", (t1 - t0) // 1000000, "ms =", n * 1000000000 // (t1 - t0), "ops/s (sink", sink, ")")
    # 2) parallel load. 200k across cores
    var m = 200000
    var p0 = perf_counter_ns()
    @parameter
    def w(i: Int):
        _ = i
        try:
            var d = parse(upd)
            _ = d.get("message").get("text").as_string()
        except:
            pass
    parallelize[w](m)
    var p1 = perf_counter_ns()
    print("parallel:", m, "parses in", (p1 - p0) // 1000000, "ms =", m * 1000000000 // (p1 - p0), "ops/s")
    print("load ok, no crash over", n + m, "parses")
