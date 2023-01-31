//
//  ToastView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct ToastView: View {
    @EnvironmentObject var toastVM: ToastVM
    @EnvironmentObject var installVM: InstallVM
    @EnvironmentObject var downloadVM: DownloadVM

    var body: some View {
        if toastVM.isShown {
            VStack(spacing: -20) {
                Spacer()
                ForEach(toastVM.toasts, id: \.self) { toast in
                    HStack {
                        switch toast.toastType {
                        case .notice:
                            Image(systemName: "info.circle")
                        case .error:
                            Image(systemName: "exclamationmark.triangle")
                        case .network:
                            Image(systemName: "info.circle")
                        }
                        Text(toast.toastDetails)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding()
                    .onAppear {
                        Task { @MainActor in
                            try await Task.sleep(nanoseconds: toast.timeRemaining * 1000000000)
                            // Next toast to be removed will always be the first in the list
                            toastVM.toasts.removeFirst()
                        }
                    }
                }
                if installVM.inProgress {
                    VStack {
                        Text(NSLocalizedString(installVM.status.rawValue, comment: ""))
                        ProgressView(value: installVM.progress)
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                    .padding()
                }
                if downloadVM.inProgress {
                    VStack {
                        Text(NSLocalizedString(downloadVM.status.rawValue, comment: "")) +
                        Text(" \(downloadVM.storeAppData?.name ?? "")")
                        HStack {
                            ProgressView(value: downloadVM.progress)
                            if downloadVM.status == .downloading {
                                Button {
                                    DownloadApp(url: nil, app: nil, warning: nil).cancel()
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .font(.title3)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(.regularMaterial, in:
                                    RoundedRectangle(cornerRadius: 10))
                    .padding()
                }
            }
            .animation(.easeInOut(duration: 0.25), value: toastVM.toasts.count)
            .animation(.easeInOut(duration: 0.25), value: installVM.inProgress)
            .animation(.easeInOut(duration: 0.25), value: downloadVM.inProgress)
        }
    }
}

struct ToastView_Preview: PreviewProvider {
    static var previews: some View {
        ToastView()
            .environmentObject(ToastVM.shared)
            .environmentObject(InstallVM.shared)
            .environmentObject(DownloadVM.shared)
    }
}
