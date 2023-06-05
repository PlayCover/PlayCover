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
                        // Make sure the "destructor" hasn't already been called
                        if let idx = toastVM.toasts.firstIndex(where: { $0 == toast }),
                           !toastVM.toasts[idx].destructorCalled {
                            Task { @MainActor in
                                toastVM.toasts[idx].destructorCalled = true
                                try await Task.sleep(nanoseconds: toast.timeRemaining * 1000000000)

                                // Since toasts can be dismissed with a click, it will need to remove by value
                                toastVM.toasts.removeAll(where: { $0.toastDetails == toast.toastDetails })
                            }
                        }
                    }
                    .onTapGesture {
                        toastVM.toasts.removeAll(where: { $0 == toast })
                    }
                }
                if installVM.inProgress {
                    installVM.constructView()
                }
                if downloadVM.inProgress {
                    downloadVM.constructView()
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
