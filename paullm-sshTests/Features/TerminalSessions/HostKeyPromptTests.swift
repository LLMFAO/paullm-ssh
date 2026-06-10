import Foundation
import Testing
@testable import paullm_ssh

/// In-memory `KnownHostsStorage` for the host-key prompt tests. Mirrors
/// the helper in `KnownHostsManagerTests.swift`; the duplication is
/// intentional so each test file can stand alone.
final class HostKeyPromptTestStorage: KnownHostsStorage, @unchecked Sendable {
    private var data: Data?
    private let lock = NSLock()

    func loadData() -> Data? {
        lock.lock(); defer { lock.unlock() }
        return data
    }

    func saveData(_ data: Data) {
        lock.lock(); defer { lock.unlock() }
        self.data = data
    }
}

struct HostKeyPromptTests {
    @Test
    func unknownErrorBuildsHostKeyPrompt() {
        let sessionId = UUID()
        let serverId = UUID()
        let error = SSHError.hostKeyUnknown(
            host: "newhost.example",
            port: 22,
            fingerprint: "SHA256:abc",
            keyType: 1
        )

        let prompt = error.hostKeyPrompt(
            sessionId: sessionId,
            serverId: serverId,
            serverName: "New Host"
        )

        #expect(prompt?.id == sessionId)
        #expect(prompt?.serverId == serverId)
        #expect(prompt?.serverName == "New Host")
        #expect(prompt?.host == "newhost.example")
        #expect(prompt?.port == 22)
        #expect(prompt?.presentedFingerprint == "SHA256:abc")
        #expect(prompt?.keyType == 1)
        if case .unknown = prompt?.kind {} else { Issue.record("Expected .unknown kind") }
    }

    @Test
    func mismatchErrorBuildsHostKeyPromptWithKnownFingerprint() {
        let error = SSHError.hostKeyMismatch(
            host: "server.example",
            port: 2222,
            knownFingerprint: "SHA256:old",
            presentedFingerprint: "SHA256:new",
            keyType: 1
        )

        let prompt = error.hostKeyPrompt(
            sessionId: UUID(),
            serverId: UUID(),
            serverName: "Server"
        )

        #expect(prompt?.host == "server.example")
        #expect(prompt?.port == 2222)
        #expect(prompt?.presentedFingerprint == "SHA256:new")
        if case .changed(let known) = prompt?.kind {
            #expect(known == "SHA256:old")
        } else {
            Issue.record("Expected .changed kind")
        }
    }

    @Test
    func nonHostKeyErrorProducesNilPrompt() {
        let error = SSHError.authenticationFailed
        #expect(error.hostKeyPrompt(
            sessionId: UUID(),
            serverId: UUID(),
            serverName: "X"
        ) == nil)
    }

    @Test
    func preApproveWritesEntryThatIsImmediatelyVisible() {
        let storage = HostKeyPromptTestStorage()
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        #expect(manager.entry(for: "newhost.example", port: 22) == nil)

        manager.preApprove(
            host: "newhost.example",
            port: 22,
            fingerprint: "SHA256:user-accepted",
            keyType: 1
        )

        let entry = manager.entry(for: "newhost.example", port: 22)
        #expect(entry?.fingerprint == "SHA256:user-accepted")
        #expect(entry?.keyType == 1)
    }

    @Test
    func removeEntryClearsPreApprovedKey() {
        let storage = HostKeyPromptTestStorage()
        let manager = KnownHostsManager(storage: storage, migrateFromUserDefaults: false)

        manager.preApprove(
            host: "newhost.example",
            port: 22,
            fingerprint: "SHA256:abc",
            keyType: 1
        )
        #expect(manager.entry(for: "newhost.example", port: 22) != nil)

        manager.removeEntry(host: "newhost.example", port: 22)
        #expect(manager.entry(for: "newhost.example", port: 22) == nil)
    }
}
