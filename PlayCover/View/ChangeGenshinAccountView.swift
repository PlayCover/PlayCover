//
//  ChangeGenshinAccountView.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 21/07/22.
//
import SwiftUI

struct ChangeGenshinAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var folderName: String = ""
    @State var accountList: [String] = getAccountList()
    // swiftlint:disable multiple_closures_with_trailing_closure
    // swiftlint:disable opening_brace
    var body: some View {
        VStack(alignment: .center, spacing: 16) {
            Spacer()
            Text("storeAccount.selectAcc").font(.largeTitle).lineLimit(1).fixedSize()
            Spacer()
            ForEach(accountList, id: \.self) { account in
                if account != ".DS_Store"{
                    Button(action: {
                        self.folderName = account
                        restoreUserData(folderName: account)
                        self.presentationMode.wrappedValue.dismiss()
                    })
                    {
                        HStack {
                            Image(systemName: "person.fill")
                            Text(account)
                        }.frame(minWidth: 300, alignment: .center)
                    }
                    .padding([.top, .bottom])
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                    .tint(.accentColor)
                    .frame(width: 300, alignment: .center)
                }
            }.frame(width: 450)
            Spacer()
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            })
            {
                Text("button.Cancel").frame(minWidth: 300, alignment: .center)
            }.buttonStyle(CancelButtonPink())
                .frame(height: 50)
            Spacer()
        }
    }
}

struct ChangeGenshinAccountView_preview: PreviewProvider {
    static var previews: some View {
        ChangeGenshinAccountView()
    }
}
