//
//  StoreAppVM.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 10/24/23.
//

import Foundation
import Observation

@Observable
final class StoreAppVM {
    var data: SourceAppsData

    init(data: SourceAppsData) {
        self.data = data
    }
}
