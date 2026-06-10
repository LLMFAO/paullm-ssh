import Foundation
import Testing
@testable import paullm_ssh

/// In-memory `KnownHostsStorage` for tests. Behaves like a tiny key-value
/// store so we can exercise `KnownHostsManager` without touching the real
/// Keychain or `UserDefaults`.
final class FakeKnownHostsStorage: KnownHostsStorage, @unchecked Sendable {
    private var data: Data?
    private let lock = NSLock()

    init(initial: Data? = nil) {
        self.data = initial
    }

    func loadData() -> Data? {
        lock.lock(); defer { lock.unlock() }
        return data
    }

    func saveData(_ data: Data) {
        lock.lock(); defer { lock.unlock() }
        self.data = data
    }

    var snapshot: Data? {
        lock.lock(); defer { lock.unlock() }
        return data
    }
}

struct KnownHostsManagerTests {
    private func makeEntry(
        host: String = "example.com",
        port: Int = 22,
        fingerprint: String = "SHA256:abc",
        keyType: Int = 1,
        addedAt: Date = Date(timeIntervalSince1970: 1_000_000),
        lastSeenAt: Date = Date(timeIntervalSince1970: 1_000_000)
    ) -> KnownHostsManager.Entry {
        KnownHostsManager.Entry(
            host: host,
            port: port,
            fingerprint: fingerprint,
            keyType: keyType,
            addedAt: addedAt,
            lastSeenAt: lastSeenAt
        )
    }

    @Test
    func saveAndLookupRoundTrip() {
        let storage = FakeKnownHostsStorage()
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        let entry = makeEntry(fingerprint: "SHA256:deadbeef")
        manager.save(entry: entry)

        let looked = manager.entry(for: "example.com", port: 22)
        #expect(looked == entry)
    }

    @Test
    func updateSeenTouchesLastSeenOnly() {
        let storage = FakeKnownHostsStorage()
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        let original = makeEntry(
            addedAt: Date(timeIntervalSince1970: 100),
            lastSeenAt: Date(timeIntervalSince1970: 100)
        )
        manager.save(entry: original)

        // updateSeen should only refresh lastSeenAt, not addedAt.
        manager.updateSeen(host: "example.com", port: 22)

        let updated = manager.entry(for: "example.com", port: 22)
        #expect(updated != nil)
        #expect(updated?.addedAt == original.addedAt)
        #expect((updated?.lastSeenAt.timeIntervalSince1970 ?? 0) > original.lastSeenAt.timeIntervalSince1970)
    }

    @Test
    func updateSeenOnUnknownHostIsNoOp() {
        let storage = FakeKnownHostsStorage()
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        manager.updateSeen(host: "unknown.example", port: 22)
        #expect(manager.entry(for: "unknown.example", port: 22) == nil)
    }

    @Test
    func removeEntryRemovesOnlyTargetedHostPort() {
        let storage = FakeKnownHostsStorage()
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        manager.save(entry: makeEntry(host: "a.example", port: 22))
        manager.save(entry: makeEntry(host: "b.example", port: 22))
        manager.save(entry: makeEntry(host: "a.example", port: 2222))

        manager.removeEntry(host: "a.example", port: 22)

        #expect(manager.entry(for: "a.example", port: 22) == nil)
        #expect(manager.entry(for: "b.example", port: 22) != nil)
        #expect(manager.entry(for: "a.example", port: 2222) != nil)
    }

    @Test
    func removeEntryOnMissingKeyIsNoOp() {
        let storage = FakeKnownHostsStorage()
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        // Should not throw or alter state.
        manager.removeEntry(host: "nope.example", port: 22)
        #expect(manager.allEntries().isEmpty)
    }

    @Test
    func allEntriesIsSortedByHostThenPort() {
        let storage = FakeKnownHostsStorage()
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        manager.save(entry: makeEntry(host: "b.example", port: 22))
        manager.save(entry: makeEntry(host: "a.example", port: 2222))
        manager.save(entry: makeEntry(host: "a.example", port: 22))

        let entries = manager.allEntries()
        #expect(entries.map(\.host) == ["a.example", "a.example", "b.example"])
        #expect(entries.map(\.port) == [22, 2222, 22])
    }

    @Test
    func initMigratesFromUserDefaultsToKeychain() {
        // Populate an isolated legacy store with a known entry.
        let suite = UserDefaults(suiteName: "KnownHostsManagerTests.legacy.\(UUID().uuidString)")!
        let legacy = UserDefaultsKnownHostsStorage(defaults: suite, key: "paullm.knownHosts")
        let legacyEntry = makeEntry(fingerprint: "SHA256:legacy")
        let data = try! JSONEncoder().encode(["example.com:22": legacyEntry])
        legacy.saveData(data)

        // Run the manager with that legacy source — it should migrate the
        // entry into the new (keychain) store and clear the legacy key.
        let keychain = FakeKnownHostsStorage()
        let manager = KnownHostsManager(
            storage: keychain,
            migrationSource: legacy
        )

        #expect(keychain.snapshot != nil)
        #expect(manager.entry(for: "example.com", port: 22)?.fingerprint == "SHA256:legacy")
        #expect(legacy.loadData() == nil)
    }

    @Test
    func initSkipsMigrationWhenKeychainAlreadyHasData() {
        // Keychain already populated — the legacy store should be left alone.
        let suite = UserDefaults(suiteName: "KnownHostsManagerTests.legacy.\(UUID().uuidString)")!
        let legacy = UserDefaultsKnownHostsStorage(defaults: suite, key: "paullm.knownHosts")
        let legacyEntry = makeEntry(fingerprint: "SHA256:legacy")
        let legacyData = try! JSONEncoder().encode(["example.com:22": legacyEntry])
        legacy.saveData(legacyData)

        let existingEntry = makeEntry(host: "preexisting.example", fingerprint: "SHA256:existing")
        let existingData = try! JSONEncoder().encode(["preexisting.example:22": existingEntry])
        let keychain = FakeKnownHostsStorage(initial: existingData)

        _ = KnownHostsManager(storage: keychain, migrationSource: legacy)

        #expect(legacy.loadData() == legacyData)  // legacy untouched
        #expect(manager_entry_via_storage(keychain, host: "example.com", port: 22) == nil)
    }

    private func manager_entry_via_storage(_ storage: FakeKnownHostsStorage, host: String, port: Int) -> KnownHostsManager.Entry? {
        let m = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)
        return m.entry(for: host, port: port)
    }

    @Test
    func corruptedStorageJSONReturnsEmptyEntries() {
        let storage = FakeKnownHostsStorage(initial: Data("not json".utf8))
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        #expect(manager.entry(for: "anywhere", port: 22) == nil)
        #expect(manager.allEntries().isEmpty)
    }
}
