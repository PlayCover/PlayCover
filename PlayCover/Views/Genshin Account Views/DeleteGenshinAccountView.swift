//
//  DeleteGenshinAccountView.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 23/07/22.
//

import SwiftUI

struct DeleteGenshinAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var folderName: String = ""
    @State var accountList: [String] = getAccountList()
    @State var deleteAlert: Bool = false
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Text("storeAccount.deleteAcc").font(.largeTitle).lineLimit(1).fixedSize()
            Spacer()
            ForEach(accountList, id: \.self) { account in
                if account != ".DS_Store"{
                    Button(action: {
                        self.folderName = account
                        self.deleteAlert = true
                    }, label: {
                        HStack {
                            Image(systemName: "person.fill")
                            Text(account)
                        }.frame(minWidth: 300, alignment: .center)
                    }).controlSize(.large).buttonStyle(.automatic).font(.title3)
                        .foregroundColor(.accentColor)
                        .frame(width: 300, alignment: .center)
                        .alert("Really Delete Account?", isPresented: $deleteAlert) {
                            Button("Delete \"\(folderName)\" Account", role: .destructive) {
                                print("account: ", self.folderName)
                                deleteStoredAccount(folderName: self.folderName)
                                self.presentationMode.wrappedValue.dismiss()
                            }.foregroundColor(.red)
                            Button("button.Cancel", role: .cancel) {}
                                .controlSize(.large).padding()
                                .keyboardShortcut(.defaultAction)
                        }
                }
            }.frame(width: 450)
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("button.Cancel").frame(alignment: .center)
            }).controlSize(.large).padding()
            Spacer()
        }
        .frame(minWidth: 300)
    }
}

struct DeleteGenshinAccountView_preview: PreviewProvider {
    static var previews: some View {
        DeleteGenshinAccountView()
    }
}
