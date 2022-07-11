//
//  AppSettingsView.swift
//  PlayCover
//
//  Created by Александр Дорофеев on 08.12.2021.
//

import Foundation
import SwiftUI
import AlertToast

struct AppSettingsView : View {
    @State var settings : AppSettings
    
    @State var adaptiveDisplay : Bool
    @State var keymapping : Bool
    @State var gamingMode : Bool
    @State var bypass : Bool
    @State var selectedRefreshRate : Int
    @State var sensivity : Float
    
    @State var resetedAlert : Bool = false
    
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack(alignment: .leading){
            VStack(alignment: .leading){
                HStack {
                    Toggle(NSLocalizedString("Enable Keymapping", comment:""), isOn: $keymapping).padding()
                    Toggle(NSLocalizedString("Gaming Mode", comment:""), isOn: $gamingMode).padding()
                }
                HStack{
                    Image(systemName: "keyboard").font(.system(size: 96)).foregroundColor(Colr.primary).padding(.leading)
                    Text("With this you can bind touch layout to bind touch controls to mouse and keyboard. Use Control + P to open editor menu.").frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            VStack(alignment: .leading, spacing: 0){
                Toggle(NSLocalizedString("Adaptive display", comment:""), isOn: $adaptiveDisplay).padding()
                HStack{
                    Image(systemName: "display").font(.system(size: 96)).foregroundColor(Colr.primary).padding(.leading)
                    Text("Use this feature to play games in fullscreen and adapt app window to another dimensions.").frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            VStack(alignment: .leading){
                Toggle(isOn: $bypass) {
                    Text("Enable Jailbreak Bypass (Alpha)")
                }.padding()
                HStack{
                    Image(systemName: "terminal.fill").font(.system(size: 96)).foregroundColor(Colr.primary).padding(.leading)
                    Text("ATTENTION: Don't enable for some games yet! This allows you to bypass bans that don't let you login").frame(maxWidth: 200).padding().frame(minHeight: 100)
                }
            }
            Divider().padding(.leading, 36).padding(.trailing, 36)
            HStack(spacing: 0) {
                Spacer()
                Picker(selection: $selectedRefreshRate, label: Text("Screen refresh rate"), content: {
                    Text("60 Hz").tag(0)
                    Text("120 Hz").tag(1)
                }).pickerStyle(SegmentedPickerStyle()).frame(maxWidth: 300)
                Spacer()
            }
            VStack {
                Divider().padding(.leading, 36).padding(.trailing, 36)
                Text(NSLocalizedString("Mouse sensitivity: ", comment:"") + String(format: "%.f", sensivity))
                Slider(value: $sensivity, in: 1...100).frame(maxWidth: 400)
            }
            
            Divider().padding(.leading, 36).padding(.trailing, 36)
            HStack{
                Spacer()
                Button(NSLocalizedString("Reset settings and keymapping", comment:"")){
                    resetedAlert.toggle()
                    settings.reset()
                }.buttonStyle(CancelButton()).padding()
                Button("Ok"){
                    settings.keymapping = keymapping
                    settings.adaptiveDisplay = adaptiveDisplay
                    settings.sensivity = sensivity
                    settings.bypass = bypass
                    settings.gamingMode = gamingMode
                    
                    if selectedRefreshRate == 1 {
                        settings.refreshRate = 120
                    } else {
                        settings.refreshRate = 60
                    }
                    
                    presentationMode.wrappedValue.dismiss()
                    
                }.buttonStyle(GrowingButton()).padding().frame(height: 80)
                Spacer()
            }
        }.toast(isPresenting: $resetedAlert){
            AlertToast(type: .regular, title: NSLocalizedString("Settings reseted to default!", comment:""))
        }
    }
}
