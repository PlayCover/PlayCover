//
//  NavView.swift
//  PlayCover
//

import Foundation
import SwiftUI
import Cocoa
import AlertToast

extension NSTextField {
        open override var focusRingType: NSFocusRingType {
                get { .none }
                set { }
        }
}

struct SearchView : View {
    
    @State private var search : String = ""
    @State private var isEditing = false
    @Environment(\.colorScheme) var colorScheme
    
    var body : some View {
        TextField("Search ...", text: $search)
            .padding(7)
            .padding(.horizontal, 25)
            .background(colorScheme == .dark ? Colr.control() : Colr.control())
            .cornerRadius(8)
            .font(Font.system(size: 16))
            .padding(.horizontal, 10)
            .onChange(of: search, perform: { value in
                uif.searchText = value
                AppsVM.shared.fetchApps()
                if value.isEmpty {
                    isEditing = false
                } else{
                    isEditing = true
                }
            })
            .textFieldStyle(PlainTextFieldStyle())
            .frame(width: 300).overlay(
                HStack {
                    Image(systemName: "magnifyingglass")
                        .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 16)
                    if isEditing {
                                Button(action: {
                                    self.search = ""
                                }) {
                                    Image(systemName: "multiply.circle.fill")
                                        .padding(.trailing, 16)
                                }.buttonStyle(PlainButtonStyle())
                            }
                }
            )
    }
}

struct MainView: View {
    
    @EnvironmentObject var update : UpdateService
    @EnvironmentObject var install : InstallVM
    @EnvironmentObject var apps : AppsVM
    @EnvironmentObject var integrity : AppIntegrity
    
    @State var showSetup : Bool = false
    
    @State private var showToast = false
    
    var body: some View {
        if apps.updatingApps {
          ProgressView()
        } else{
            VStack(spacing: 0) {
                AppsView().environmentObject(AppsVM.shared).padding(.bottom, -20).padding(0)
                Spacer()
                ZStack{
                HStack(alignment: .center){
                    Button(action: {
                        Log.shared.logdata.copyToClipBoard()
                        showToast.toggle()
                    }) {
                        HStack {
                            VStack{
                                Text("Have a problem with controller?")
                                Link(destination: URL(string: "https://discord.gg/rMv5qxGTGC")!) {
                                    Text("Visit Discord")
                                }
                            }
                        }
                    }.buttonStyle(CancelButton())
                    Spacer()
                    if install.installing {
                        InstallProgress().environmentObject(install).padding(.top).padding(.bottom)
                        Spacer()
                    }
                    if !update.updateLink.isEmpty {
                        Spacer()
                        Button(action: {  NSWorkspace.shared.open(URL(string: update.updateLink)!) }) {
                            HStack {
                                Image(systemName: "arrow.down.square.fill")
                                Text("Update app")
                            }
                        }.buttonStyle(UpdateButton())
                    }
                }.padding()
                }.frame(maxWidth : .infinity).background(Colr.control())
                Text(StoreApp.notice).padding().frame(maxWidth : .infinity).background(Colr.controlSelect())
                if !SystemConfig.isPlaySignActive() {
                    HStack(alignment: .center){
                        Text("Have problems with login in apps?")
                        Button(action: {
                           showSetup = true
                        }) {
                            HStack {
                                Text("Enable PlaySign")
                            }
                        }.buttonStyle(CancelButton())
                    }.padding().frame(maxWidth : .infinity).background(Colr.controlSelect())
                }
            }.toast(isPresenting: $showToast){
                AlertToast(type: .regular, title: "Logs copied!")
            }.sheet(isPresented: $showSetup) {
                SetupView()
            }.alert("PlayCover must be inside Applications folder. Press button to move it.", isPresented: $integrity.integrityOff) {
                Button("Move to apps", role: .cancel) {
                    integrity.moveToApps()
                }
            }
        }
    }
}
