//
//  ClearCacheModalView.swift
//  PlayCover
//

import SwiftUI

struct ClearCacheModalView: View {
    @Environment(\.dismiss) private var dismiss

    @Binding var app: PlayApp

    @State private var isClearingCache = false

    var body: some View {
        VStack {
            Image(nsImage: NSImage(named: "AppIcon") ?? NSImage(named: "AppIcon.dev") ?? NSImage())
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 65, height: 65)
                .padding(.bottom)
            Text("alert.app.delete")
                .bold()
                .foregroundStyle(Color(nsColor: NSColor.textColor))
                .frame(width: 215)
                .multilineTextAlignment(.center)
            HStack {
                Button { dismiss() } label: {
                    Text("button.Cancel")
                        .padding(.vertical, 5)
                        .padding(.horizontal, 33.5)
                }
                Button {
                    Task {
                        isClearingCache.toggle()
                        await app.clearAllCache()
                        isClearingCache.toggle()
                        dismiss()
                    }
                } label: {
                    Text("button.Proceed")
                        .padding(.vertical, 5)
                        .padding(.horizontal, 33.5)
                        .foregroundStyle(.red)
                        .opacity(isClearingCache ? 0 : 1)
                        .overlay {
                            if isClearingCache {
                                ProgressView()
                                    .scaleEffect(0.5)
                            }
                        }
                }
            }
            .padding(.top, 8)
            .disabled(isClearingCache)
        }
        .padding()
        .fixedSize()
        .background(.ultraThickMaterial)
    }
}
