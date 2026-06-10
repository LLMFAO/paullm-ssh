import Foundation
import os.log

/// Storage backend for the known-hosts trust store.
///
/// Trust anchors must stay per-device, so the production backend
/// (`KeychainKnownHostsStorage`) is always written with `iCloudSync: false`.
/// `UserDefaultsKnownHostsStorage` exists only to migrate pre-existing
/// entries out of `UserDefaults` on first launch.
protocol KnownHostsStorage: Sendable {
    func loadData() -> Data?
    func saveData(_ data: Data)
}

/// Keychain-backed storage. Uses the existing `KeychainStore` with the
/// per-app service id and a fixed account key. Trust anchors are never
/// synced across devices via iCloud Keychain.
struct KeychainKnownHostsStorage: KnownHostsStorage, @unchecked Sendable {
    private let store: KeychainStore
    private let accountKey: String

    init(
        store: KeychainStore = KeychainStore(service: "app.paullm.ssh"),
        accountKey: String = "paullm.knownHosts"
    ) {
        self.store = store
        self.accountKey = accountKey
    }

    func loadData() -> Data? {
        do {
            return try store.get(accountKey)
        } catch {
            return nil
        }
    }

    func saveData(_ data: Data) {
        do {
            try store.set(data, forKey: accountKey, iCloudSync: false)
        } catch {
            // Trust-anchor persistence is best-effort; surface a log and
            // continue with the in-memory copy.
            Logger(subsystem: Bundle.main.bundleIdentifier ?? "paullm-ssh", category: "KnownHosts")
                .error("Failed to persist known hosts to keychain: \(error.localizedDescription, privacy: .public)")
        }
    }
}

/// `UserDefaults`-backed storage. Used only for one-time migration of
/// pre-existing entries into the Keychain store.
struct UserDefaultsKnownHostsStorage: KnownHostsStorage, @unchecked Sendable {
    private let defaults: UserDefaults
    private let key: String

    init(defaults: UserDefaults = .standard, key: String = "paullm.knownHosts") {
        self.defaults = defaults
        self.key = key
    }

    func loadData() -> Data? {
        defaults.data(forKey: key)
    }

    func saveData(_ data: Data) {
        defaults.set(data, forKey: key)
    }

    /// Drop the legacy entry. Used by the one-shot migration in
    /// `KnownHostsManager.init`.
    func remove() {
        defaults.removeObject(forKey: key)
    }
}

final class KnownHostsManager: @unchecked Sendable {
    static let shared = KnownHostsManager(storage: KeychainKnownHostsStorage())

    struct Entry: Codable, Equatable {
        let host: String
        let port: Int
        let fingerprint: String
        let keyType: Int
        let addedAt: Date
        var lastSeenAt: Date

        var id: String { "\(host):\(port)" }
    }

    private let logger = Logger(subsystem: Bundle.main.bundleIdentifier ?? "paullm-ssh", category: "KnownHosts")
    private let lock = NSLock()
    private let storage: KnownHostsStorage

    init(
        storage: KnownHostsStorage,
        migrateFromUserDefaults: Bool = true,
        migrationSource: UserDefaultsKnownHostsStorage = UserDefaultsKnownHostsStorage()
    ) {
        self.storage = storage
        if migrateFromUserDefaults,
           storage.loadData() == nil {
            // Migration source is the original UserDefaults key, exactly as
            // described in the plan. The `migrationSource` parameter lets
            // tests substitute an isolated defaults instance.
            if let data = migrationSource.loadData() {
                storage.saveData(data)
                migrationSource.remove()
                Logger(subsystem: Bundle.main.bundleIdentifier ?? "paullm-ssh", category: "KnownHosts")
                    .info("Migrated known hosts from UserDefaults to Keychain")
            }
        }
    }

    func entry(for host: String, port: Int) -> Entry? {
        lock.lock()
        defer { lock.unlock() }
        return loadAll()[hostKey(host: host, port: port)]
    }

    func updateSeen(host: String, port: Int) {
        lock.lock()
        defer { lock.unlock() }
        var entries = loadAll()
        let key = hostKey(host: host, port: port)
        if var entry = entries[key] {
            entry.lastSeenAt = Date()
            entries[key] = entry
            saveAll(entries)
        }
    }

    func save(entry: Entry) {
        lock.lock()
        defer { lock.unlock() }
        var entries = loadAll()
        entries[entry.id] = entry
        saveAll(entries)
    }

    /// Remove a single host:port entry. No-op if the entry does not exist.
    func removeEntry(host: String, port: Int) {
        lock.lock()
        defer { lock.unlock() }
        var entries = loadAll()
        if entries.removeValue(forKey: hostKey(host: host, port: port)) != nil {
            saveAll(entries)
            logger.info("Removed known host entry for \(host):\(port)")
        }
    }

    /// All known entries, sorted by `(host, port)` for stable UI presentation.
    func allEntries() -> [Entry] {
        lock.lock()
        defer { lock.unlock() }
        return loadAll().values.sorted {
            if $0.host == $1.host { return $0.port < $1.port }
            return $0.host < $1.host
        }
    }

    private func hostKey(host: String, port: Int) -> String {
        "\(host):\(port)"
    }

    private func loadAll() -> [String: Entry] {
        guard let data = storage.loadData() else {
            return [:]
        }
        return (try? JSONDecoder().decode([String: Entry].self, from: data)) ?? [:]
    }

    private func saveAll(_ entries: [String: Entry]) {
        guard let data = try? JSONEncoder().encode(entries) else {
            logger.error("Failed to encode known hosts store")
            return
        }
        storage.saveData(data)
    }
}
