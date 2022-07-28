//
//  StoreGenshinAccount.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 21/07/22.
//

import SwiftUI
import AlertToast

struct StoreGenshinAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var FolderName : String = ""
    @State var selectedRegion : String = ""
    @State var regionIsNotValid: Bool = false
    var body: some View {
        VStack (alignment: .center, spacing: 16){
            Spacer()
            Text("Store an account").font(.largeTitle).lineLimit(1).fixedSize()
            Spacer()
            HStack(spacing: 0) {
                Picker(selection: $selectedRegion, label: Text("Select account region").font(.headline).lineLimit(1).fixedSize(),
                       content: {
                            Text("America").tag("America").frame(minWidth: 150, maxWidth: 150, minHeight: 350)
                            Text("Europe").tag("Europe").frame(minWidth: 150, maxWidth: 150, minHeight: 350)
                }).pickerStyle(SegmentedPickerStyle())
                Spacer()
            }
            HStack{
                Text("Name of your account").font(.headline).lineLimit(1).fixedSize()
                TextField(NSLocalizedString("Name of account...", comment: ""), text: $FolderName)
            }
            Spacer()
            Button(action:{
                if !FolderName.isEmpty && !selectedRegion.isEmpty {
                    if checkCurrentRegion(selectedRegion: selectedRegion){
                        regionIsNotValid = false
                        if selectedRegion == "America" {
                            storeUserData(folderName: $FolderName.wrappedValue.lowercased(),
                                          accountRegion: "os_usa")
                        } else {
                            storeUserData(folderName: $FolderName.wrappedValue.lowercased(),
                                          accountRegion: "os_euro")
                        }
                        presentationMode.wrappedValue.dismiss()
                    } else{
                        regionIsNotValid = true
                    }
                } else { presentationMode.wrappedValue.dismiss()
                }
            }){
                Text("Store!").frame(minWidth: 300, alignment: .center)
                }.controlSize(.large).buttonStyle(UpdateButton()).font(.title3)
                
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

//"The current account is set to a different server. enter the game, change region and pass through the gates and try again"


struct genshinView_preview: PreviewProvider {
    static var previews: some View{
        StoreGenshinAccountView()
    }
}
