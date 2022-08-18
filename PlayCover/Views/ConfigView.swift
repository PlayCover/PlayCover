//
//  ConfigView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 18/08/2022.
//

import SwiftUI

struct ConfigView: View {
    @Environment(\.dismiss) var dismiss

    var body: some View {
        VStack {
            HStack {
                Text("PlayCover Configuration")
                    .font(.system(.largeTitle))
                    .bold()
                    .padding()
                Spacer()
            }
            CheckStepView(text: "PlayCover is in Applications folder", isComplete: true)
            Divider()
                .padding(.horizontal)
            CheckStepView(text: "Xcode Command Line Tools Installed", isComplete: false)
        }
        .padding()
        //Text("Config View")
        //Button(action: {dismiss()}, label: {Text("Dismiss")})
    }
}

struct CheckStepView: View {
    @State var text: String
    @State var isComplete: Bool

    var body: some View {
        HStack {
            if isComplete {
                Image(systemName: "checkmark.circle")
                    .foregroundColor(.green)
                    .font(.system(size: 30))
            } else {
                Image(systemName: "xmark.octagon")
                    .foregroundColor(.red)
                    .font(.system(size: 30))
            }
            Spacer()
                .frame(width: 40)
            Text(text)
                .font(.system(.title))
            Spacer()
        }
        .padding()
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView()
    }
}
