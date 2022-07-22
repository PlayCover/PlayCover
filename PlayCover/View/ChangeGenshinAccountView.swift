//
//  ChangeGenshinAccountView.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 21/07/22.
//
import SwiftUI


struct ChangeGenshinAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var FolderName : String = ""
    @State var AccountList : [String] = getAccountList()

    var body: some View {

        Spacer()
        ForEach(AccountList, id: \.self) { account in
            if account != ".DS_Store"{
                Button(action: {
                    self.FolderName = account
                    restoreUserData(folderName: account)
                    self.presentationMode.wrappedValue.dismiss()
                }) {
                    Text(account)
                }.controlSize(.large).frame(minWidth: 300, maxWidth: 400)
            }
        }
        Spacer()
        Button("exit") {
            presentationMode.wrappedValue.dismiss()
        }.buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large)
        Spacer()
    }
}
