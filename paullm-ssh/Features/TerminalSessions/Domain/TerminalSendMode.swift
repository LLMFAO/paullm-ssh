//
//  TerminalSendMode.swift
//  paullm-ssh
//
//  Describes how the local compose box delivers drafted text into the
//  active terminal session.
//

import Foundation

/// The ways the local compose box can deliver its drafted text to the terminal.
///
/// These map onto existing terminal transport primitives: raw text injection
/// (`sendText`), key events (Enter), and Ghostty's bracketed-paste-aware
/// `paste_from_clipboard` action. No new transport is introduced.
enum TerminalSendMode: String, CaseIterable, Identifiable, Codable {
    /// Send the text exactly as typed, with no trailing newline.
    case raw
    /// Send the text followed by a Return key press (executes a command).
    case enter
    /// Send multiline/long text through the safest bracketed-paste path.
    case pasteSafe
    /// Send a multiline prompt cleanly to an agent session, then submit it.
    case agent

    var id: String { rawValue }

    /// Short title shown in the mode picker.
    var title: String {
        switch self {
        case .raw: return String(localized: "Raw")
        case .enter: return String(localized: "Enter")
        case .pasteSafe: return String(localized: "Paste-safe")
        case .agent: return String(localized: "Agent prompt")
        }
    }

    /// One-line description of the behavior, shown in the picker.
    var detail: String {
        switch self {
        case .raw:
            return String(localized: "Send text exactly as typed.")
        case .enter:
            return String(localized: "Send text and press Return to run it.")
        case .pasteSafe:
            return String(localized: "Paste multiline text safely without running each line.")
        case .agent:
            return String(localized: "Paste a multiline prompt to an agent and submit it.")
        }
    }

    /// SF Symbol used to represent the mode in compact controls.
    var systemImage: String {
        switch self {
        case .raw: return "text.cursor"
        case .enter: return "return"
        case .pasteSafe: return "doc.on.clipboard"
        case .agent: return "sparkles"
        }
    }
}
