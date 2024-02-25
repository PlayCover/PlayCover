//
//  StoreAppVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/24/23.
//

import Foundation

class StoreAppVM: ObservableObject {
    @Published var data: StoreAppData

    init(data: StoreAppData) {
        self.data = data
    }
}
