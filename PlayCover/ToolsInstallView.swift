//
//  ContentView.swift
//  PlayCover
//
//  Created by syren on 03.08.2021.
//

import SwiftUI

struct ToolsInstallView: View {
    
    @State var clickedInstall: Bool = false
    @State var buttonTitle: String = "Install Xcode"
    @State var showingAlert = false
    
    var body: some View {
        VStack{
            Text("You should install Xcode to start using PlayCover")
                .padding().fixedSize(horizontal: true, vertical: false)
            Spacer()
                Button(buttonTitle){
                    if !clickedInstall {
                        goToUrl(uri: "https://apps.apple.com/ru/app/xcode/id497799835")
                        clickedInstall = true
                        buttonTitle = "Continue"
                    } else{
                        if checkIfXcodeInstalled(){
                            print("success!")
                        } else{
                            buttonTitle = "Install Xcode"
                            clickedInstall = false
                            showingAlert = true
                        }
                    }
                    
                }.padding().accentColor(.blue).alert(isPresented: $showingAlert) {
                    Alert(title: Text("Xcode is not installed!"), message: Text("You should install Xcode app to continue"), dismissButton: .default(Text("Got it!")))
                }
        }.padding()
    }
}
