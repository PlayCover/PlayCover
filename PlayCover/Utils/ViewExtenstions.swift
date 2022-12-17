//
//  ViewExtenstions.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/26/1401 AP.
//

import SwiftUI

struct BadgeTextStyle: ViewModifier {
    func body(content: Content) -> some View {
        if #available(macOS 13.0, *) {
            content
                .textCase(.uppercase)
                .font(.subheadline)
                .bold()
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
        }
    }
}

struct VerticalSpacer: View {
    var body: some View {
        Spacer()
        Divider()
            .frame(height: .infinity)
        Spacer()
    }
}
