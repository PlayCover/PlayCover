//
//  ToastVM.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 08/08/2022.
//

import Foundation

class ToastVM: ObservableObject {
    static let shared = ToastVM()

    @Published var toasts: [ToastInfo] = []
    @Published var isShown: Bool = true

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
