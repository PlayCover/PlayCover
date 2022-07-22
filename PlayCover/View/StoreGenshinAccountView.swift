//
//  StoreGenshinAccount.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 21/07/22.
//

import SwiftUI

struct StoreGenshinAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var FolderName : String = ""
    @State var selectedRegion : String = ""
    var body: some View {
        Spacer()
        HStack(spacing: 0) {
            Spacer()
            Picker(selection: $selectedRegion, label: Text("Select account region"), content: {
                Text("America").tag("America")
                Text("Europe").tag("Europe")
            }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300)
            Spacer()
        }
        Spacer()
        TextField(NSLocalizedString("Search...", comment: ""), text: $FolderName)
        Spacer()
        Button("Ok"){
            print(selectedRegion)
            if !FolderName.isEmpty && !selectedRegion.isEmpty {
                if selectedRegion == "America" {
                    storeUserData(folderName: $FolderName.wrappedValue.lowercased(), accountRegion: "os_usa")
                } else {
                    storeUserData(folderName: $FolderName.wrappedValue.lowercased(), accountRegion: "os_euro")
                }
            }
            presentationMode.wrappedValue.dismiss()
            
        }.buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large)
        Spacer()
    }
}
