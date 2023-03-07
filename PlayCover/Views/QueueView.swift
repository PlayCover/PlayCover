//
//  QueueView.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 2/28/23.
//

import Foundation
import SwiftUI

struct QueuesView: View {
    public enum Tabs: Hashable {
        case install, download
    }

    @Environment(\.dismiss) var dismiss
    @State var selection: Tabs = Tabs.install

    var body: some View {
        VStack {
            HStack {
                Text("queue.view.title")
                    .font(.title2).bold()
                    .multilineTextAlignment(.leading)
                Spacer()
            }

            TabView(selection: $selection) {
                InstallQueueView()
                    .environmentObject(QueuesManager.shared)
                    .environmentObject(InstallVM.shared)
                    .tabItem {
                        Text("queue.view.installs")
                    }
                    .tag(Tabs.install)
                DownloadQueueView()
                    .environmentObject(QueuesManager.shared)
                    .environmentObject(DownloadVM.shared)
                    .tabItem {
                        Text("queue.view.downloads")
                    }
                    .tag(Tabs.download)
            }
            .frame(minWidth: 450, minHeight: 200)
            HStack {
                Spacer()
                Button("button.OK") {
                    dismiss()
                }
                .tint(.accentColor)
                .keyboardShortcut(.defaultAction)
            }
        }
        .padding()
    }
}

struct InstallQueueView: View {
    @EnvironmentObject var queuesManager: QueuesManager
    @EnvironmentObject var installVM: InstallVM

    var body: some View {
        if queuesManager.installQueueItems.isEmpty && queuesManager.currentInstallItem == nil {
            Text("queue.view.empty")
        } else {
            ScrollView {
                installVM.constructView(collapsable: false)

                ForEach(queuesManager.installQueueItems, id: \.ipa) { item in
                    HStack {
                        Spacer()
                        Text(item.ipa.lastPathComponent)
                        Spacer()
                        Button {
                            queuesManager.removeInstallItem(ipa: item.ipa)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding()
                }
            }
        }
    }
}

struct DownloadQueueView: View {
    @EnvironmentObject var queuesManager: QueuesManager
    @EnvironmentObject var downloadVM: DownloadVM

    var body: some View {
        if queuesManager.downloadQueueItems.isEmpty && queuesManager.currentDownloadItem == nil {
            Text("queue.view.empty")
        } else {
            ScrollView {
                downloadVM.constructView(collapsable: false)

                ForEach(queuesManager.downloadQueueItems, id: \.link) { item in
                    HStack {
                        Spacer()
                        Text(item.name)
                        Spacer()
                        Button {
                            queuesManager.removeDownloadItem(app: item)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.title3)
                        }
                        .buttonStyle(.plain)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding()
                }
            }
        }
    }
}
