//
//  TerminalComposeDraftStore.swift
//  paullm-ssh
//
//  Holds per-session local compose drafts so unsent text survives tab/session
//  switches. Drafts are intentionally in-memory and local only — nothing here
//  is sent to the terminal until the user explicitly sends it.
//

import Foundation
import Combine

@MainActor
final class TerminalComposeDraftStore: ObservableObject {
    static let shared = TerminalComposeDraftStore()

    /// Unsent draft text keyed by connection session id.
    @Published private var drafts: [UUID: String] = [:]

    init() {}

    func draft(for sessionId: UUID) -> String {
        drafts[sessionId] ?? ""
    }

    func setDraft(_ text: String, for sessionId: UUID) {
        if text.isEmpty {
            drafts.removeValue(forKey: sessionId)
        } else {
            drafts[sessionId] = text
        }
    }

    func clearDraft(for sessionId: UUID) {
        drafts.removeValue(forKey: sessionId)
    }

    /// Drop drafts for sessions that no longer exist to avoid unbounded growth.
    func pruneDrafts(keepingSessionIds activeIds: Set<UUID>) {
        drafts = drafts.filter { activeIds.contains($0.key) }
    }
}
