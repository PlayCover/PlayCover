//
//  StoreGenshinAccountView.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 21/07/22.
//

import SwiftUI

struct StoreGenshinAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var folderName: String = ""
    @State var selectedRegion: String = ""
    @State var regionIsNotValid: Bool = false
    @State var app: PlayApp

    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Text("storeAccount.storeAcc").font(.largeTitle).lineLimit(1).fixedSize()
            Spacer()
            if app.info.bundleIdentifier == "com.miHoYo.GenshinImpact"{
                HStack(spacing: 0) {
                    Picker(selection: $selectedRegion,
                           label: Text("storeAccount.selectAccRegion")
                        .font(.headline).lineLimit(1).fixedSize(),
                           content: {
                                Text("storeAccount.selectAccRegion.usa").tag("America")
                                Text("storeAccount.selectAccRegion.euro").tag("Europe")
                                Text("storeAccount.selectAccRegion.asia").tag("Asia")
                                Text("storeAccount.selectAccRegion.cht").tag("CHT")
                    }).pickerStyle(.segmented)
                    Spacer()
                }
            }
            HStack {
                Text("storeAccount.nameOfAcc")
                    .font(.headline).lineLimit(1).fixedSize()
                TextField(NSLocalizedString(
                    "storeAccount.nameOfAcc.textfieldPlaceholder", comment: ""
                ), text: $folderName)
            }
            Spacer()
            HStack {
                Button(action: {
                    if !folderName.isEmpty && !selectedRegion.isEmpty {
                        do {
                            if try checkCurrentRegion(selectedRegion: selectedRegion) {
                                regionIsNotValid = false
                                if selectedRegion == "America" {
                                    storeUserData(folderName: $folderName.wrappedValue.lowercased(),
                                                  accountRegion: "os_usa", app: app)
                                } else if selectedRegion == "Europe" {
                                    storeUserData(folderName: $folderName.wrappedValue.lowercased(),
                                                  accountRegion: "os_euro", app: app)
                                } else if selectedRegion == "Asia" {
                                    storeUserData(folderName: $folderName.wrappedValue.lowercased(),
                                                  accountRegion: "os_asia", app: app)
                                } else {
                                    storeUserData(folderName: $folderName.wrappedValue.lowercased(),
                                                  accountRegion: "os_cht", app: app)
                                }
                                presentationMode.wrappedValue.dismiss()
                            } else {
                                regionIsNotValid = true
                            }
                        } catch {
                            Log.shared.error("An error occoured while trying to store your account: "
                                             + error.localizedDescription)
                        }
                    } else if !folderName.isEmpty && selectedRegion.isEmpty {
                        storeUserData(folderName: $folderName.wrappedValue.lowercased(),
                                      accountRegion: "", app: app)
                        presentationMode.wrappedValue.dismiss()
                    } else {
                        presentationMode.wrappedValue.dismiss()
                    }
                    }, label: {
                    Text("storeAccount.store").frame(minWidth: 300, alignment: .center)
                }).controlSize(.large).font(.title3).padding()
                    .keyboardShortcut(.defaultAction)
                    .disabled(folderName == "")

                Button(action: {
                    presentationMode.wrappedValue.dismiss()
                }, label: {
                    Text("button.Close").frame(alignment: .center)
                })
                .controlSize(.large).padding()
                .keyboardShortcut(.cancelAction)
            }
        }.padding()
                .alert(NSLocalizedString("alert.storeAccount.regionIsNotValid",
                                         comment: ""), isPresented: $regionIsNotValid) {
                    Button("button.Close",
                           role: .cancel) {
                        regionIsNotValid.toggle()
                        presentationMode.wrappedValue.dismiss()
                    }
                }
        }
    }
