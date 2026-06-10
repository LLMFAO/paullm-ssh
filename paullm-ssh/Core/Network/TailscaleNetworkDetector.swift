import Foundation
import Darwin

/// Detects whether this device currently appears to be on a Tailscale network.
///
/// A sandboxed app can't enumerate tailnet peers (that needs the Tailscale Admin
/// API), but it *can* tell whether the local device is itself on the tailnet by
/// looking for an interface address in Tailscale's CGNAT IPv4 range
/// (100.64.0.0/10) or its IPv6 ULA prefix (fd7a:115c:a1e0::/48). That's enough to
/// surface an "add a Tailscale host" prompt when no servers are configured.
enum TailscaleNetworkDetector {
    /// 100.64.0.0/10 expressed in host byte order.
    private static let cgnatNetwork: UInt32 = 0x6440_0000
    private static let cgnatMask: UInt32 = 0xFFC0_0000

    /// Returns true when an active (non-loopback) interface holds an address in
    /// Tailscale's address space.
    static func isOnTailnet() -> Bool {
        var interfacePointer: UnsafeMutablePointer<ifaddrs>?
        guard getifaddrs(&interfacePointer) == 0, let first = interfacePointer else {
            return false
        }
        defer { freeifaddrs(interfacePointer) }

        var pointer: UnsafeMutablePointer<ifaddrs>? = first
        while let current = pointer {
            defer { pointer = current.pointee.ifa_next }
            let entry = current.pointee

            let flags = Int32(entry.ifa_flags)
            guard (flags & IFF_UP) != 0, (flags & IFF_LOOPBACK) == 0 else { continue }
            guard let address = entry.ifa_addr else { continue }

            switch Int32(address.pointee.sa_family) {
            case AF_INET:
                let ipv4 = address.withMemoryRebound(to: sockaddr_in.self, capacity: 1) { $0.pointee }
                let hostOrder = UInt32(bigEndian: ipv4.sin_addr.s_addr)
                if (hostOrder & cgnatMask) == cgnatNetwork {
                    return true
                }
            case AF_INET6:
                let ipv6 = address.withMemoryRebound(to: sockaddr_in6.self, capacity: 1) { $0.pointee }
                if isTailscaleIPv6(ipv6.sin6_addr) {
                    return true
                }
            default:
                break
            }
        }
        return false
    }

    /// Tailscale IPv6 addresses live under fd7a:115c:a1e0::/48.
    private static func isTailscaleIPv6(_ addr: in6_addr) -> Bool {
        var value = addr
        return withUnsafeBytes(of: &value) { raw in
            raw.count >= 6
                && raw[0] == 0xfd && raw[1] == 0x7a
                && raw[2] == 0x11 && raw[3] == 0x5c
                && raw[4] == 0xa1 && raw[5] == 0xe0
        }
    }
}
