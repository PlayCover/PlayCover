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
        toasts.insert(ToastInfo(toastType: toastType, toastDetails: toastDetails, timeRemaining: 2), at: 0)
    }
}

struct ToastInfo: Hashable {
    let toastType: ToastType
    let toastDetails: String
    let timeRemaining: UInt64
    var destructorCalled = false
}

enum ToastType {
    case notice, error, network
}
