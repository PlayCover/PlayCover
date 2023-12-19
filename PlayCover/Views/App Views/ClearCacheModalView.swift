//
//  ClearCacheModalView.swift
//  PlayCover
//

import SwiftUI
import DataCache

struct ClearCacheModalView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var app: PlayApp
    @State private var isClearingCache = false
    @State private var appIcon: NSImage?
    @State private var cache = DataCache.instance

    var body: some View {
        VStack {
            Group {
                if let image = appIcon {
                    Image(nsImage: image)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                } else {
                    Rectangle()
                        .fill(.regularMaterial)
                        .overlay {
                            ProgressView()
                                .progressViewStyle(.circular)
                                .controlSize(.small)
                        }
                }
            }
            .cornerRadius(15)
            .shadow(radius: 1)
            .frame(width: 60, height: 60)
            .padding()
            Text("alert.app.delete")
                .bold()
                .frame(width: 250)
        }
        .padding()
        .fixedSize()
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                if isClearingCache {
                    ProgressView()
                        .scaleEffect(0.5)
                } else {
                    Button("\(Text("button.Proceed").foregroundColor(.red))") {
                        isClearingCache.toggle()
                        Task {
                            await app.clearAllCache()
                            isClearingCache.toggle()
                            dismiss()
                        }
                    }
                }
            }
            ToolbarItem(placement: .cancellationAction) {
                Button("button.Cancel") { dismiss() }
            }
        }
        .disabled(isClearingCache)
        .task(priority: .userInitiated) {
            let compareStr = app.info.bundleIdentifier + app.info.bundleVersion
            if cache.readImage(forKey: app.info.bundleIdentifier) != nil
                && cache.readString(forKey: compareStr) != nil {
                appIcon = cache.readImage(forKey: app.info.bundleIdentifier)
            } else { appIcon = Cacher().resolveLocalIcon(app) }
        }
    }
}

