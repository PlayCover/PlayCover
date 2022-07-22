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
        Spacer()
        HStack(spacing: 0) {
            Spacer()
            Picker(selection: $selectedRegion, label: Text("Select account region"),
                   content: {
                        Text("America").tag("America")
                        Text("Europe").tag("Europe")
            }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300)
            Spacer()
        }
        Spacer()
        TextField(NSLocalizedString("Search...", comment: ""), text: $FolderName)
        Spacer()
        Button("Ok"){
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
            }
        }.buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large)
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
