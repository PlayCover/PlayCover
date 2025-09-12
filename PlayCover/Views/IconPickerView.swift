//
//  IconPickerView.swift
//  PlayCover
//
//  Created by Edoardo C. on 24/06/25.
//

import SwiftUI

class IconPickerView {
    static let shared = IconPickerView()
    struct IconPickerViewStruct: View {
        @Binding var selectedSymbol: String
        @Binding var showSelector: Bool
        let icons: [String]
        @State private var tempSelection: String = ""
        let rows = [GridItem(.adaptive(minimum: 50, maximum: .infinity))]
        var body: some View {
            LazyVStack {
                Text(NSLocalizedString("folder.textfield.icon", comment: ""))
                LazyHGrid(rows: rows, spacing: 18) {
                    ForEach(icons, id: \.self) { icon in
                        IconPickerView.shared.iconVStack(icon: icon, tempSelection: $tempSelection)
                    }
                }
                .padding(.horizontal, 10)
                HStack {
                    Spacer()
                    Button(NSLocalizedString("button.Cancel", comment: "")) {
                        showSelector = false
                    }
                    Button(NSLocalizedString("button.OK", comment: "")) {
                        selectedSymbol = tempSelection
                        showSelector = false
                    }
                    .keyboardShortcut(.defaultAction)
                    .disabled(tempSelection.isEmpty)
                }
            }
            .padding()
            .onAppear {
                tempSelection = selectedSymbol
            }
        }
    }

    func iconVStack(icon: String, tempSelection: Binding<String>) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 32, height: 32)
                .padding(10)
                .overlay(
                    RoundedRectangle(cornerRadius: 15)
                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                )
                .shadow(radius: 1)
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(
                            tempSelection.wrappedValue == icon ? Color.blue.opacity(0.3) : Color.clear
                        )
                )
                .contentShape(Rectangle())
                .onTapGesture {
                    tempSelection.wrappedValue = icon
                }
            Spacer()
            Image(systemName: tempSelection.wrappedValue == icon ? "checkmark.circle.fill" : "circle")
                .font(.system(size: 18))
                .foregroundColor(tempSelection.wrappedValue == icon ? .blue : .gray)
                .onTapGesture {
                    tempSelection.wrappedValue = icon
                }
        }
    }
}
