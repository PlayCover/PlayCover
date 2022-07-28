//
//  ChangeGenshinAccountView.swift
//  PlayCover
//
//  Created by José Elias Moreno villegas on 21/07/22.
//
import SwiftUI


struct ChangeGenshinAccountView: View {
    @Environment(\.presentationMode) var presentationMode
    @State var folderName : String = ""
    @State var accountList : [String] = getAccountList()

    var body: some View {
        VStack (alignment: .center, spacing: 16){
            Spacer()
            Text("Select an Account").font(.largeTitle).lineLimit(1).fixedSize()
            Spacer()
            ForEach(accountList, id: \.self) { account in
                if account != ".DS_Store"{
                    Button(action: {
                        self.folderName = account
                        restoreUserData(folderName: account)
                        self.presentationMode.wrappedValue.dismiss()
                    }) {
                        HStack{
                            Image(systemName: "person.fill")
                            Text(account)
                        }.frame(minWidth: 300, alignment: .center)
                    }.controlSize(.large).buttonStyle(GrowingButton()).font(.title3)
                        .frame(width: 300, alignment: .center)
                }
            }.frame(width: 450)
            Spacer()
            Button(action: {
                presentationMode.wrappedValue.dismiss()
            }) {
                Text("Exit").frame(minWidth: 300, alignment: .center)
            }.buttonStyle(CancelButtonPink())
                .frame(height: 50)
            Spacer()
        }
    }
}

struct ChangeGenshinAccountView_preview: PreviewProvider {
    static var previews: some View{
        ChangeGenshinAccountView()
    }
}
