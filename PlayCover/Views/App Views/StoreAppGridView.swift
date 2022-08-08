//
//  StoreAppGridView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct StoreAppGridView: View {
    @State var app: StoreAppData
    @State var isHover: Bool = false

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            AsyncImage(
                url: URL(string: app.icon),
                content: { image in
                    image
                        .resizable()
                        .cornerRadius(16)
                        .shadow(radius: 1)
                },
                placeholder: {
                    Image(systemName: "doc")
                }
            )
            .frame(width: 72, height: 72)
            .cornerRadius(10)
            .shadow(radius: 1)
            .padding(.bottom, -8)
            .padding(.top)
            HStack {
                Image(systemName: "arrow.down.circle")
                    .opacity(1.0)
                    .font(.system(size: 16))
                Text(app.name)
                    .lineLimit(2)
                    .multilineTextAlignment(.center)
            }
            .frame(width: 150, height: 70)
        }
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isHover ? Color.secondary : Color.clear, lineWidth: 1)
        )
        .frame(width: 150, height: 150)
        .onTapGesture {
            isHover = false
            if let url = URL(string: app.link) {
                // TODO: Change to download in-app
                NSWorkspace.shared.open(url)
            }
        }
        .onHover(perform: { hovering in
            isHover = hovering
        })
    }
}
