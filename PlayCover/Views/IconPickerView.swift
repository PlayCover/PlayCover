//
//  IconPickerView.swift
//  PlayCover
//
//  Created by Edoardo C. on 24/06/25.
//

import SwiftUI

struct IconPickerView: View {
    @Binding var selectedSymbol: String
    @Binding var showSelector: Bool
    let icons: [String]

    @State private var tempSelection: String = ""

    let columns = [GridItem(.adaptive(minimum: 50, maximum: .infinity))]

    var body: some View {
        LazyVStack {
            Text(NSLocalizedString("folder.textfield.icon", comment: ""))
            LazyVGrid(columns: columns, spacing: 8) {
                ForEach(icons, id: \.self) { icon in
                    Image(systemName: icon)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 32, height: 32)
                        .padding(10)
                        .background(tempSelection == icon ? Color.blue.opacity(0.3) : Color.clear)
                        .cornerRadius(15)
                        .shadow(radius: 1)
                        .overlay(
                            RoundedRectangle(cornerRadius: 15)
                                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                        )
                        .contentShape(Rectangle())
                        .onTapGesture {
                            tempSelection = icon
                        }
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
