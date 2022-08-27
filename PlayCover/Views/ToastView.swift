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

    var body: some View {
        VStack(spacing: -20) {
            Spacer()
            ForEach(toastVM.toasts, id: \.self) { toast in
                HStack {
                    switch toast.toastType {
                    case .notice:
                        Image(systemName: "info.circle")
                    case .error:
                        Image(systemName: "exclamationmark.triangle")
                    }
                    Text(toast.toastDetails)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding()
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + toast.timeRemaining) {
                        // Next toast to be removed will always be the first in the list
                        toastVM.toasts.removeFirst()
                    }
                }
            }
            if installVM.installing {
                VStack {
                    Text(installVM.status)
                    ProgressView(value: installVM.progress)
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
                .padding()
            }
        }
        .animation(.easeInOut(duration: 0.25), value: toastVM.toasts.count)
        .animation(.easeInOut(duration: 0.25), value: installVM.installing)
    }
}

struct ToastView_Preview: PreviewProvider {
    static var previews: some View {
        ToastView()
            .environmentObject(ToastVM.shared)
            .environmentObject(InstallVM.shared)
    }
}
