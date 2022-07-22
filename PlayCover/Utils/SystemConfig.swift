//
//  SystemConfig.swift
//  PlayCover
//

import Foundation

class SystemConfig {

	static let isPlaySignActive: Bool = {
        return isSIPDisabled() && isPRAMValid()
    }()

    static func enablePlaySign(_ argc: String) -> Bool {
        return shell.sudosh(["-S", "/usr/sbin/nvram",
                          "boot-args=amfi_get_out_of_my_way=0x1 ipc_control_port_options=0"], argc)
    }

    static var firstTimeSIP = true
    static var firstTimeBootArgs = true

    static func isSIPDisabled() -> Bool {
        let check = shell.shell("csrutil status", print: firstTimeSIP)
        firstTimeSIP = false
        return check.contains("unknown") || check.contains("disabled")
    }

    static func isPRAMValid() -> Bool {
        let check = shell.shell("nvram boot-args", print: firstTimeBootArgs)
        firstTimeBootArgs = false
        for option in NVRAM_OPTIONS {
            if check.contains(option) {
                return true
            }
        }

        print(firstTimeBootArgs)
        return false
    }

    private static let NVRAM_OPTIONS = ["amfi_get_out_of_my_way=1",
                                        "amfi_get_out_of_my_way=0x1",
                                        "amfi_get_out_of_my_way=1 ipc_control_port_options=0",
                                        "amfi_get_out_of_my_way=0x1 ipc_control_port_options=0"]

}
