//
//  StoreAppGridView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct StoreAppView: View {
    @State var app: StoreAppData
    @State var isList: Bool

    @State var isHover: Bool = false

    var body: some View {
        StoreAppConditionalView(app: app, isList: isList)
        .background(
            withAnimation {
                isHover ? Color.gray.opacity(0.3) : Color.clear
            }
                .animation(.easeInOut(duration: 0.15), value: isHover)
        )
        .cornerRadius(10)
        .onTapGesture {
            isHover = false
            if let url = URL(string: app.link) {
                NSWorkspace.shared.open(url)
            }
        }
        .onHover(perform: { hovering in
            isHover = hovering
        })
    }
}

struct StoreAppConditionalView: View {
    @State var app: StoreAppData
    @State var isList: Bool

    var body: some View {
        if isList {
            HStack(alignment: .center, spacing: 0) {
                Image(systemName: "arrow.down.circle")
                Spacer()
                    .frame(width: 20)
                // TODO: Fix async image appearence
                AsyncImage(
                    url: URL(string: app.icon),
                    content: { image in
                        image
                            .resizable()
                    },
                    placeholder: {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                )
                .frame(width: 40, height: 40)
                .cornerRadius(10)
                .shadow(radius: 1)
                Spacer()
                    .frame(width: 20)
                Text(app.name)
                Spacer()
                Text(app.version)
                    .padding(.horizontal, 5)
                    .foregroundColor(.secondary)
            }
        } else {
            VStack(alignment: .center, spacing: 0) {
                AsyncImage(
                    url: URL(string: app.icon),
                    content: { image in
                        image
                            .resizable()
                    },
                    placeholder: {
                        ProgressView()
                            .progressViewStyle(.circular)
                    }
                )
                .frame(width: 88, height: 88)
                .cornerRadius(10)
                .shadow(radius: 1)
                .padding(.top, 8)
                HStack {
                    Image(systemName: "arrow.down.circle")
                        .font(.system(size: 16))
                    Text(app.name)
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                }
                .padding(.bottom, 14)
            }
            .frame(width: 150, height: 150)
        }
    }
}
