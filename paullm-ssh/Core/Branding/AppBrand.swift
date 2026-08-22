//
//  AppBrand.swift
//  paullm-ssh
//
//  Single source of truth for the app's identity, contact channels, and
//  legal attribution. These strings were previously duplicated across the
//  About and Support screens on both platforms and had drifted apart.
//

import Foundation

enum AppBrand {

    // MARK: - Identity

    static let displayName = "paullm-ssh"
    static let tagline = "Professional SSH client\nfor macOS & iOS"

    // MARK: - Contact

    static let supportEmail = "me@pauljpettit.com"
    static let supportMailto = "mailto:me@pauljpettit.com"

    static let xHandle = "@thepaullm"
    static let xURL = "https://x.com/thepaullm"

    // MARK: - Links
    //
    // These all resolve today. The previous Website/Privacy/Terms links pointed
    // at paullm.dev, which has no DNS record, so all three were dead.

    static let repoURL = "https://github.com/LLMFAO/paullm-ssh"
    static let issuesURL = "https://github.com/LLMFAO/paullm-ssh/issues"

    /// GPL-3.0 is the license these binaries are distributed under, so the
    /// license file is the app's actual terms of use.
    static let licenseURL = "https://github.com/LLMFAO/paullm-ssh/blob/main/LICENSE"
    static let privacyURL = "https://github.com/LLMFAO/paullm-ssh/blob/main/PRIVACY.md"

    // MARK: - Legal attribution
    //
    // This app is a modified version of VVTerm, which is licensed GPL-3.0.
    // GPLv3 §4 requires keeping the original copyright notices intact and §5(a)
    // requires modified versions to carry prominent notice of modification, so
    // the upstream attribution stays alongside our own copyright.

    static var copyrightLine: String {
        let year = Calendar.current.component(.year, from: Date())
        return "© \(year) Paul Pettit"
    }

    /// GPLv3 §5(a) requires a modified work to carry prominent notice that it
    /// was changed, along with a relevant date.
    static let upstreamAttribution = "Modified from VVTerm (© Vivy Technologies Co., Limited) since May 2026. Licensed under GPL-3.0."
}
