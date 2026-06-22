"""A spinlock, the one synchronization primitive mojogram needs.

Mojo 1.0 has no Lock, so this is a test-and-set spinlock built from Atomic on a
heap cell. It is ImplicitlyCopyable, and copies share the same cell because only
the pointer is copied, so passing a Spinlock around still guards a single lock.

StateStore and RateLimiter both use it. It is only ever held for a microsecond
critical section, so it never serializes a handler's network call.
"""
from std.atomic import Atomic
from std.memory import alloc, UnsafePointer


struct Spinlock(ImplicitlyCopyable, Movable):
    var flag: UnsafePointer[Atomic[DType.int64], MutUntrackedOrigin]

    def __init__(out self):
        self.flag = alloc[Atomic[DType.int64]](1)
        self.flag[].store(0)

    def acquire(self):
        while True:
            var expected = Int64(0)
            if self.flag[].compare_exchange(expected, 1):
                return

    def release(self):
        self.flag[].store(0)
