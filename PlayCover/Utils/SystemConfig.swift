//
//  SystemConfig.swift
//  PlayCover
//

import Foundation

class SystemConfig {
    static var isFirstTimePlaySign = false

    static let isPlaySignActive: Bool = isSIPDisabled() && isRunningAMFIEnabled()

    static func enablePlaySign(_ argc: String) -> Bool {
        Shell.runSu([
            "-S",
            "/usr/sbin/nvram",
            "boot-args=amfi_get_out_of_my_way=0x1 ipc_control_port_options=0"
        ], argc)
    }

    static func isSIPDisabled() -> Bool {
        do {
            let check = try Shell.run("/usr/bin/csrutil", "status")
            return check.contains("unknown") || check.contains("disabled")
        } catch {
            return false
        }
    }

    static func isPRAMValid() -> Bool {
        do {
            let check = try Shell.run("/usr/sbin/nvram", "boot-args")
            for option in NVRAM_OPTIONS where check.contains(option) {
                return true
            }
            return false
        } catch {
            return false
        }
    }

    static func isRunningAMFIEnabled() -> Bool {
        do {
            let check = try Shell.run("/usr/sbin/sysctl", "kern.bootargs")
            for option in NVRAM_OPTIONS where check.contains(option) {
                return true
            }
            return false
        } catch {
            return false
        }
    }

    private static let NVRAM_OPTIONS = [
        "amfi_get_out_of_my_way=1",
        "amfi_get_out_of_my_way=0x1",
        "amfi_get_out_of_my_way=1 ipc_control_port_options=0",
        "amfi_get_out_of_my_way=0x1 ipc_control_port_options=0"
    ]
}
