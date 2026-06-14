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

    /// The session whose compose editor currently holds keyboard focus, if any.
    /// The terminal wrapper reads this to avoid stealing first responder back
    /// from the compose box while the user is typing locally.
    @Published var focusedSessionId: UUID?

    init() {}

    /// Mark (or clear) the compose editor focus for a session.
    func setEditorFocused(_ focused: Bool, for sessionId: UUID) {
        if focused {
            focusedSessionId = sessionId
        } else if focusedSessionId == sessionId {
            focusedSessionId = nil
        }
    }

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
