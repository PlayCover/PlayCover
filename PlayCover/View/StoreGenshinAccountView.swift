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
            Text("storeAccount.storeAcc").font(.largeTitle).lineLimit(1).fixedSize()
            Spacer()
            HStack(spacing: 0) {
                Picker(selection: $selectedRegion,
                       label: Text("storeAccount.selectAccRegion")
                    .font(.headline).lineLimit(1).fixedSize(),
                       content: {
                            Text("storeAccount.selectAccRegion.usa").tag("America").frame(minWidth: 150, maxWidth: 150, minHeight: 350)
                            Text("storeAccount.selectAccRegion.euro").tag("Europe").frame(minWidth: 150, maxWidth: 150, minHeight: 350)
                }).pickerStyle(SegmentedPickerStyle())
                Spacer()
            }
            HStack {
                Text("storeAccount.nameOfAcc")
                    .font(.headline).lineLimit(1).fixedSize()
                TextField(NSLocalizedString("storeAccount.nameOfAcc.textfieldPlaceholder", comment: ""), text: $folderName)
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
                Text("storeAccount.store").frame(minWidth: 300, alignment: .center)
                }.controlSize(.large).buttonStyle(GrowingButton()).font(.title3)
            Spacer()
        }.padding()
                .alert(NSLocalizedString("alert.storeAccount.regionIsNotValid",
                                         comment: ""), isPresented: $regionIsNotValid) {
                    Button("button.Close",
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
