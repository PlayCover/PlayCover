//
//  ToastVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 08/08/2022.
//

import Foundation
import Observation

@Observable
final class ToastVM {
    static var shared: ToastVM { AppEnvironment.shared.toasts }

    var toasts: [ToastInfo] = []
    var isShown: Bool = true

    func showToast(toastType: ToastType, toastDetails: String) {
        toasts.append(ToastInfo(toastType: toastType, toastDetails: toastDetails, timeRemaining: 2))
    }
}

struct ToastInfo: Hashable {
    let toastType: ToastType
    let toastDetails: String
    let timeRemaining: UInt64
}

enum ToastType {
    case notice, error, network
}
