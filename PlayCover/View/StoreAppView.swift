//
//  StoreAppView.swift
//  PlayCover
//

import Foundation
import SwiftUI

struct StoreAppView: View {

    @State var app: StoreApp

    @Environment(\.colorScheme) var colorScheme

    @State var isHover: Bool = false

    func elementColor(_ dark: Bool) -> Color {
        return isHover ? Colr.controlSelect().opacity(0.3) : Color.black.opacity(0.0)
    }

    init(app: StoreApp) {
        _app = State(initialValue: app)
    }

    var body: some View {

        VStack(alignment: .center, spacing: 0) {
            AsyncImage(
                url: URL(string: app.data.icon),
                content: { image in
                    image.resizable().cornerRadius(16).shadow(radius: 1)
                },
                placeholder: {
                    ProgressView()
                }
            ).frame(width: 72, height: 72).cornerRadius(10).shadow(radius: 1).padding(.bottom, -8).padding(.top)

            HStack {
                Image(systemName: "arrow.down.circle.fill").opacity(1.0).font(.system(size: 16))
                Text(app.data.name).lineLimit(2).multilineTextAlignment(.center)
            }.frame(width: 150, height: 70)

        }.background(colorScheme == .dark ? elementColor(true) : elementColor(false))
            .cornerRadius(16.0)
            .frame(width: 150, height: 150)
            .onTapGesture {
                isHover = false
                if let url = URL(string: app.data.link) {
                    NSWorkspace.shared.open(url)
                }
            }
            .onHover(perform: { hovering in
                isHover = hovering
            })
    }
}
