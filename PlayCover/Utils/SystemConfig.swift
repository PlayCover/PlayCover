//
//  SystemConfig.swift
//  PlayCover
//

import Foundation

class SystemConfig {

    static var isFirstTimePlaySign = false

    static let isPlaySignActive: Bool = isSIPDisabled() && isRunningAMFIEnabled()

    static func enablePlaySign(_ argc: String) -> Bool {
        shell.sudosh([
            "-S",
            "/usr/sbin/nvram",
            "boot-args=amfi_get_out_of_my_way=0x1 ipc_control_port_options=0"
        ], argc)
    }

    static func isSIPDisabled() -> Bool {
        let check = shell.shell("csrutil status")
        return check.contains("unknown") || check.contains("disabled")
    }

    static func isPRAMValid() -> Bool {
        let check = shell.shell("nvram boot-args")
        for option in NVRAM_OPTIONS where check.contains(option) {
            return true
        }
        return false
    }

    static func isRunningAMFIEnabled() -> Bool {
        let check = shell.shell("sysctl kern.bootargs")
        for option in NVRAM_OPTIONS where check.contains(option) {
            return true
        }
        return false
    }

    private static let NVRAM_OPTIONS = [
        "amfi_get_out_of_my_way=1",
        "amfi_get_out_of_my_way=0x1",
        "amfi_get_out_of_my_way=1 ipc_control_port_options=0",
        "amfi_get_out_of_my_way=0x1 ipc_control_port_options=0"
    ]

}
