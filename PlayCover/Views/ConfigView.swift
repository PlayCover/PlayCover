//
//  ConfigView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 18/08/2022.
//

import SwiftUI

// swiftlint:disable line_length
// Test

enum ConfigProgress { case applicationsFolder, xcodeCli, done }

struct ConfigView: View {
    @Environment(\.dismiss) var dismiss

    @State var currentStep: ConfigProgress = .applicationsFolder

    var body: some View {
        VStack {
            HStack {
                Image(systemName: currentStep == .applicationsFolder ? "ellipsis.circle" : "checkmark.circle")
                    .foregroundColor(currentStep == .applicationsFolder ? .gray : .green)
                    .font(.system(size: 30))
                RoundedRectangle(cornerRadius: 10)
                    .fill(currentStep == .applicationsFolder ? .gray : .green)
                    .frame(height: 5)
                Image(systemName: currentStep != .done ? "ellipsis.circle" : "checkmark.circle")
                    .foregroundColor(currentStep != .done ? .gray : .green)
                    .font(.system(size: 30))
                RoundedRectangle(cornerRadius: 10)
                    .fill(currentStep == .done ? .green : .gray)
                    .frame(height: 5)
                Image(systemName: currentStep == .done ? "checkmark.circle" : "ellipsis.circle")
                    .foregroundColor(currentStep == .done ? .green : .gray)
                    .font(.system(size: 30))
            }

            switch currentStep {
            case .applicationsFolder:
                StepBodyView(title: "Move PlayCover to Applications", description: "PlayCover must be run from the Applications folder in order to work correctly.", buttonText: "Move", action: {currentStep = .xcodeCli})
            case .xcodeCli:
                StepBodyView(title: "Install Xcode Command Line Tools", description: "Xcode Command Line Tools are required for PlayCover to sign and run apps.\n\nThe install will take approximatley 5-10 minutes depending on your internet connection.", buttonText: "Install", action: {currentStep = .done})
            case .done:
                StepBodyView(title: "Done!", description: "Welcome to Playcover.\n\nEnjoy", buttonText: "Continue", action: {dismiss()})
            }
        }
        .padding()
        .frame(width: 500)
    }
}

struct StepBodyView: View {
    @State var title: String
    @State var description: String
    @State var buttonText: String
    var action: () -> Void

    var body: some View {
        Text(title)
            .font(.system(.title))
        Divider()
            .padding(.vertical)
        Text(description)
            .multilineTextAlignment(.center)
            .foregroundColor(.secondary)
        Button(buttonText) {
            self.action()
        }
        .tint(.accentColor)
        .padding()
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
                    .font(.system(size: 20))
            } else {
                Image(systemName: "xmark.octagon")
                    .foregroundColor(.red)
                    .font(.system(size: 20))
            }
            Spacer()
                .frame(width: 15)
            Text(text)
                .font(.system(.title3))
            Spacer()
            Button(action: {}, label: {Text("Fix Issue")})
                .tint(.accentColor)
        }
        .padding(.vertical)
    }
}

struct ConfigView_Previews: PreviewProvider {
    static var previews: some View {
        ConfigView()
    }
}
