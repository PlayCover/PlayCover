//
//  SystemConfig.swift
//  PlayCover
//

import Foundation

nonisolated enum SystemConfig {
    // Written only during the first-launch signing flow on the main thread.
    nonisolated(unsafe) static var isFirstTimePlaySign = false

    struct PlaySignStatus: Sendable, Equatable {
        var sipDisabled: Bool
        var amfiInNVRAM: Bool
        var amfiInRunningOS: Bool

        var isActive: Bool { sipDisabled && amfiInRunningOS }
    }

    static func playSignStatus() async -> PlaySignStatus {
        async let sip = isSIPDisabled()
        async let nvram = isPRAMValid()
        async let running = isRunningAMFIEnabled()
        return await PlaySignStatus(sipDisabled: sip, amfiInNVRAM: nvram, amfiInRunningOS: running)
    }

    static var isPlaySignActive: Bool {
        get async {
            await playSignStatus().isActive
        }
    }

    static func enablePlaySign(_ argc: String) async -> Bool {
        await Shell.runSu([
            "-S",
            "/usr/sbin/nvram",
            "boot-args=amfi_get_out_of_my_way=0x1 ipc_control_port_options=0"
        ], argc)
    }

    static func isSIPDisabled() async -> Bool {
        guard let check = try? await Shell.run("/usr/bin/csrutil", "status") else { return false }
        return check.contains("unknown") || check.contains("disabled")
    }

    static func isPRAMValid() async -> Bool {
        guard let check = try? await Shell.run("/usr/sbin/nvram", "boot-args") else { return false }
        return NVRAM_OPTIONS.contains { check.contains($0) }
    }

    static func isRunningAMFIEnabled() async -> Bool {
        guard let check = try? await Shell.run("/usr/sbin/sysctl", "kern.bootargs") else { return false }
        return NVRAM_OPTIONS.contains { check.contains($0) }
    }

    private static let NVRAM_OPTIONS = [
        "amfi_get_out_of_my_way=1",
        "amfi_get_out_of_my_way=0x1",
        "amfi_get_out_of_my_way=1 ipc_control_port_options=0",
        "amfi_get_out_of_my_way=0x1 ipc_control_port_options=0"
    ]
}
