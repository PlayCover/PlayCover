//
//  ConfigView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 18/08/2022.
//

import SwiftUI

struct ConfigView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        Text("Config View")
        Button(action: {dismiss()}, label: {Text("Dismiss")})
    }
}
