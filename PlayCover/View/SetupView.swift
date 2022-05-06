//
//  SetupView.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 08.11.2021.
//

import Foundation
import SwiftUI

struct SetupView : View {
    
    @Environment(\.presentationMode) var presentationMode
    
    typealias promptResponseClosure = (_ strResponse:String, _ bResponse:Bool) -> Void
    
    func promptForReply(_ strMsg:String, _ strInformative:String, completion:promptResponseClosure) {

                let alert: NSAlert = NSAlert()

                alert.addButton(withTitle: "OK")      // 1st button
                alert.addButton(withTitle: "Cancel")  // 2nd button
                alert.messageText = strMsg
                alert.informativeText = strInformative

                let txt = NSSecureTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
            
                txt.stringValue = ""

                alert.accessoryView = txt
                let response: NSApplication.ModalResponse = alert.runModal()

                var bResponse = false
                if (response == NSApplication.ModalResponse.alertFirstButtonReturn) {
                    bResponse = true
                }
                
                completion(txt.stringValue, bResponse)

            }
    
    func playSignPromt(_ firstTime : Bool){
        let text = firstTime ? "Please, input your login password" : "You typed incorrect password."
        promptForReply(text, "It is one you use for Mac unlock"){ strResponse,bResponse in
            if SystemConfig.enablePlaySign(strResponse) {
                if SystemConfig.isPRAMValid() {
                    presentationMode.wrappedValue.dismiss()
                    Log.shared.msg("Now restart Mac and all is done!")
                } else{
                    playSignPromt(false)
                }
            } else{
                playSignPromt(false)
            }
        }
    }
    
    var body: some View {
        VStack{
            if !SystemConfig.isSIPDisabled(){
                Text("PlaySign apps require one time system setup. Please, follow instruction.").padding().font(.system(size: 18.0, weight: .thin))
                VStack(alignment: .leading, spacing: 5){
                    Text("1) Click the Apple symbol in the Menu bar.Click Restart")
                    Text("2) When screen turns black, hold on Power button")
                    Text("3) Click Utilities -> Terminal")
                    HStack{
                        Text("4) Type: ")
                        ZStack{
                            Label("csrutil disable", systemImage: "terminal").padding(16)
                        }.background(RoundedRectangle(cornerRadius: 8).stroke(lineWidth: 1).foregroundColor(Colr.highlighted(Colr.isDarkMode())))
                    }
                    Text("5) Press Return or Enter on your keyboard. Input your Mac screen password (it is invisible)")
                    Text("6) Click the Apple symbol in the Menu bar and Restart")
                    HStack {
                        ZStack{
                            Link("YouTube", destination: URL(string: "https://www.youtube.com/watch?v=H3CoI84s_FI")!).font(.system(size: 12)).padding().frame(alignment: .center)
                        }.background(RoundedRectangle(cornerRadius: 8).fill(Colr.controlSelect(Colr.isDarkMode()))).padding(.top, 16).padding(.bottom, 16).padding(.leading, 16)
                        ZStack{
                            Link("Bilibili", destination: URL(string: "https://www.bilibili.com/video/BV1Th411q7Lt")!).font(.system(size: 12)).padding().clipShape(Capsule()).frame(alignment: .center)
                        }.background(RoundedRectangle(cornerRadius: 8).fill(Colr.controlSelect(Colr.isDarkMode()))).padding(.top, 16).padding(.bottom, 16)
                    }
                    Text("If you have any error, press on Apple icon and select Startup disk. Then click on Restart or Unlock. After screen turns black, hold Power button again.").font(.system(size: 16.0, weight: .bold)).frame(minHeight: 100)
                    Button("OK"){
                        presentationMode.wrappedValue.dismiss()
                    }.padding()
                }.padding().frame(maxWidth: 500)
            } else if !SystemConfig.isPRAMValid() {
                Text("Please, press below button and input your Mac unlock screen password.").padding().font(.system(size: 18.0, weight: .thin)).padding()
                Button("Enable PlaySign"){
                    playSignPromt(true)
                }.padding()
            }
        }
    }
}
