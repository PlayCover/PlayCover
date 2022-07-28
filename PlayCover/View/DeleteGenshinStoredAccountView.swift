//
//  DeleteGenshinStoredAccount.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 23/07/22.
//

import SwiftUI

struct DeleteGenshinStoredAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var FolderName : String = ""
    @State var AccountList : [String] = getAccountList()
    var body: some View {
        VStack (alignment: .center, spacing: 16){
            Spacer()
            ForEach(AccountList, id: \.self) { account in
                if account != ".DS_Store"{
                    
                    Button(action: {
                        self.FolderName = account
                        deleteStoredAccount(folderName: account)
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        Image(systemName: "person.fill").foregroundColor(Color(.systemCyan))
                        Text(account).frame(minWidth: 300, maxWidth: 400, minHeight: 350)
                    }.controlSize(.large).padding(15)
                }
            }.frame(width: 450)
            Spacer()
            Button("exit") {
                presentationMode.wrappedValue.dismiss()
            }.buttonStyle(.borderedProminent).tint(.accentColor).controlSize(.large)
            Spacer()
        }.padding(20)
    }
}
