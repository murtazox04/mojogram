"""Stress test: the Atomic spinlock makes parallel FSM access safe.

Without the lock, concurrent Dict mutation under `parallelize` corrupts/loses
entries. With it, both tests are exact.
"""
from std.algorithm import parallelize
from mojogram import StateStore, State


def main() raises:
    # 1) 500 workers write DISTINCT keys to the shared Dict concurrently.
    var store = StateStore()
    var n = 500

    @parameter
    def writer(i: Int):
        State(store, i).set_data("k", String(i))

    parallelize[writer](n)
    var missing = 0
    for i in range(n):
        if State(store, i).get_data("k") != String(i):
            missing += 1
    print("distinct-key writes: missing =", missing, "(want 0)")

    # 2) 1000 workers read-modify-write the SAME cell under one lock.
    #    Count by appending 'x' (length == increments) to avoid Int-parse.
    var s2 = StateStore()
    var m = 1000

    @parameter
    def inc(i: Int):
        s2.acquire()
        try:
            var cur = String("")
            if 0 in s2.states[]:
                cur = s2.states[][0]
            s2.states[][0] = cur + "x"
        except:
            pass
        s2.release()

    parallelize[inc](m)
    var final = 0
    if 0 in s2.states[]:
        final = len(s2.states[][0].as_bytes())
    print("contended counter:", final, "(want", m, ")")

    if missing == 0 and final == m:
        print("concurrency ok")
    else:
        raise Error("concurrency test FAILED")
