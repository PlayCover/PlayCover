//
//  ErrorViewModel.swift
//  PlayCover
//

import Foundation
import SwiftUI

let evm = ErrorViewModel.shared

class ErrorViewModel: ObservableObject {
    
    static let shared = ErrorViewModel()
    
    @Published var error : String = ""
    
    var showError : Binding<Bool> { Binding (
        get: { !self.error.isEmpty },
        set: { if !$0 { self.error = "" } }
        )
    }
    
    required init() {}

}
