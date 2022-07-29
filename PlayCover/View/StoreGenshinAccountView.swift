//
//  StoreGenshinAccountView.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 21/07/22.
//
// swiftlint:disable line_length
// swiftlint:disable multiple_closures_with_trailing_closure
import SwiftUI
import AlertToast

struct StoreGenshinAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var folderName: String = ""
    @State var selectedRegion: String = ""
    @State var regionIsNotValid: Bool = false
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Text("Store an account").font(.largeTitle).lineLimit(1).fixedSize()
            Spacer()
            HStack(spacing: 0) {
                Picker(selection: $selectedRegion,
                       label: Text("Select account region")
                    .font(.headline).lineLimit(1).fixedSize(),
                       content: {
                            Text("America").tag("America").frame(minWidth: 150, maxWidth: 150, minHeight: 350)
                            Text("Europe").tag("Europe").frame(minWidth: 150, maxWidth: 150, minHeight: 350)
                }).pickerStyle(SegmentedPickerStyle())
                Spacer()
            }
            HStack {
                Text("Name of your account")
                    .font(.headline).lineLimit(1).fixedSize()
                TextField(NSLocalizedString("Name of account...", comment: ""), text: $folderName)
            }
            Spacer()
            Button(action: {
                if !folderName.isEmpty && !selectedRegion.isEmpty {
                    if checkCurrentRegion(selectedRegion: selectedRegion) {
                        regionIsNotValid = false
                        if selectedRegion == "America" {
                            storeUserData(folderName: $folderName.wrappedValue.lowercased(),
                                          accountRegion: "os_usa")
                        } else {
                            storeUserData(folderName: $folderName.wrappedValue.lowercased(),
                                          accountRegion: "os_euro")
                        }
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        regionIsNotValid = true
                    }
                } else { presentationMode.wrappedValue.dismiss()
                }
            }) {
                Text("Store!").frame(minWidth: 300, alignment: .center)
                }
                .padding([.top, .bottom])
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .tint(.accentColor)

            Spacer()
        }.padding()
                .alert(NSLocalizedString("The current account is set to a different Region. Launch the game, Change the region, and pass through the gates to save. Then try again",
                                         comment: ""), isPresented: $regionIsNotValid) {
                    Button("Close",
                           role: .cancel) {
                        regionIsNotValid.toggle()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
            Spacer()
        }
    }

struct GenshinView_preview: PreviewProvider {
    static var previews: some View {
        StoreGenshinAccountView()
    }
}
