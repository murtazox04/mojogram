"""A finite-state machine holding per-chat state and scratch data.

The maps live behind ArcPointer[Dict], so copying a StateStore or State shares
one underlying Dict. Mojo 1.0 has no Lock, so the store guards itself with a
spinlock built from Atomic on a shared heap cell. Every read and write takes the
lock, which makes concurrent access from parallel workers safe even when two
updates target the same chat.

The lock is held only for the tiny Dict operation, never across a handler's
network call, so parallelism stays intact. Data is keyed flat as "<chat_id>:<key>".
One coarse lock does the job since the Dict ops are cheap. If it ever contends,
shard the maps per chat.
"""
from std.collections import Dict
from std.memory import ArcPointer
from mojogram.sync import Spinlock


struct StateStore(ImplicitlyCopyable, Movable):
    """In-memory FSM backend with a spinlock. Copies share lock + maps."""

    var states: ArcPointer[Dict[Int, String]]
    var data: ArcPointer[Dict[String, String]]
    var lock: Spinlock

    def __init__(out self):
        self.states = ArcPointer(Dict[Int, String]())
        self.data = ArcPointer(Dict[String, String]())
        self.lock = Spinlock()

    def acquire(self):
        self.lock.acquire()

    def release(self):
        self.lock.release()


struct State(ImplicitlyCopyable, Movable):
    """Per-chat handle onto the shared, locked storage."""

    var storage: StateStore
    var chat_id: Int

    def __init__(out self, storage: StateStore, chat_id: Int):
        self.storage = storage
        self.chat_id = chat_id

    def _dkey(self, key: String) -> String:
        return String(self.chat_id) + ":" + key

    def get_state(self) raises -> String:
        self.storage.acquire()
        try:
            var r = String("")
            if self.chat_id in self.storage.states[]:
                r = self.storage.states[][self.chat_id]
            return r
        finally:
            self.storage.release()

    def set_state(self, state: String):
        self.storage.acquire()
        self.storage.states[][self.chat_id] = state
        self.storage.release()

    def clear(self) raises:
        self.storage.acquire()
        try:
            if self.chat_id in self.storage.states[]:
                _ = self.storage.states[].pop(self.chat_id)
            var prefix = String(self.chat_id) + ":"
            # ponytail: O(total state) rebuild to drop one chat. Fine until a
            # busy bot; shard the data Dict per chat_id if it ever bites.
            var survivors = Dict[String, String]()
            for entry in self.storage.data[].items():
                if not entry.key.startswith(prefix):
                    survivors[entry.key] = entry.value
            self.storage.data[] = survivors^
        finally:
            self.storage.release()

    def set_data(self, key: String, value: String):
        self.storage.acquire()
        self.storage.data[][self._dkey(key)] = value
        self.storage.release()

    def get_data(self, key: String, default: String = "") raises -> String:
        self.storage.acquire()
        try:
            var k = self._dkey(key)
            var r = default
            if k in self.storage.data[]:
                r = self.storage.data[][k]
            return r
        finally:
            self.storage.release()


def group(group_name: String, state: String) -> String:
    """Namespace a state name, e.g. group("Form", "name") -> "Form:name"."""
    return group_name + ":" + state
