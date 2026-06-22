"""A token bucket for Telegram's flood limits (around 30 messages a second).

Call acquire() before a send. It blocks just long enough to stay under the rate
you set, while allowing short bursts up to the bucket size. It is thread-safe
through a Spinlock, so parallel workers share one budget. Using it is optional:
create one and call it in your handler.

    var limiter = RateLimiter(rate=25.0, burst=25.0)
    ...
    limiter.acquire()
    _ = ctx.answer("...")
"""
from std.time import perf_counter_ns, sleep
from std.memory import ArcPointer
from mojogram.sync import Spinlock


struct RateLimiter(ImplicitlyCopyable, Movable):
    var rate: Float64                    # tokens (sends) per second
    var burst: Float64                   # bucket capacity
    var state: ArcPointer[List[Float64]] # [tokens, last_seconds], shared
    var lock: Spinlock

    def __init__(out self, rate: Float64 = 30.0, burst: Float64 = 30.0):
        self.rate = rate
        self.burst = burst
        var s = [burst, Float64(perf_counter_ns()) / 1.0e9]
        self.state = ArcPointer(s^)
        self.lock = Spinlock()

    def acquire(self):
        """Block until a token is available, then consume one."""
        while True:
            self.lock.acquire()
            var now = Float64(perf_counter_ns()) / 1.0e9
            var tokens = self.state[][0] + (now - self.state[][1]) * self.rate
            if tokens > self.burst:
                tokens = self.burst
            self.state[][1] = now
            if tokens >= 1.0:
                self.state[][0] = tokens - 1.0
                self.lock.release()
                return
            self.state[][0] = tokens
            var wait = (1.0 - tokens) / self.rate
            self.lock.release()
            sleep(wait)
