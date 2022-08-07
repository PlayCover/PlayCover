//
//  ToastView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 07/08/2022.
//

import SwiftUI

struct ToastView: View {
    var body: some View {
        VStack {
            Spacer()
            VStack {
                Text("Example Toast")
            }
            .padding()
            .frame(maxWidth: .infinity)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 10))
        }
        .padding()
    }
}

struct ToastView_Preview: PreviewProvider {
    static var previews: some View {
        ToastView()
    }
}
