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
        TextField("Search...", text: $search)
            .padding(7)
            .padding(.horizontal, 25)
            .background(Color(NSColor.textBackgroundColor))
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
            .frame(maxWidth: .infinity).overlay(
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
    
    @State var showSetup = false
    @State var noticesExpanded = false
    @State var bottomHeight: CGFloat = 0
    
    @State private var showToast = false
    
    var body: some View {
        if apps.updatingApps { ProgressView() }
        else {
            ZStack(alignment: .bottom) {
                AppsView(bottomPadding: $bottomHeight)
                    .frame(maxWidth: .infinity, maxHeight: .infinity).environmentObject(AppsVM.shared)
                
                VStack(alignment: .leading, spacing: 0) {
                    VStack(alignment: .leading, spacing: 8) {
                        HStack(spacing: 8) {
                            Link("Join Discord Server", destination: URL(string: "https://discord.gg/rMv5qxGTGC")!)
                            Spacer()
                            if install.installing {
                                InstallProgress().environmentObject(install).padding(.bottom)
                            }
                            Spacer()
                            Button(action: {
                                Log.shared.logdata.copyToClipBoard()
                                showToast.toggle()
                            }) {
                                Text("Copy logs")
                            }
                            if !update.updateLink.isEmpty {
                                Button(action: { NSWorkspace.shared.open(URL(string: update.updateLink)!) }) {
                                    HStack {
                                        Image(systemName: "arrow.down.square.fill")
                                        Text("Update app")
                                    }
                                }.buttonStyle(UpdateButton())
                            }
                        }.padding().frame(maxWidth : .infinity)
                        
                       
                    }
                    
                    Divider()

                    VStack(alignment: .leading, spacing: 16) {
                        VStack(alignment: .leading, spacing: 0) {
                            HStack {
                                Text("Notices").font(.headline)
                                Spacer()
                                Button {
                                    withAnimation { noticesExpanded.toggle() }
                                } label: {
                                    Image(systemName: "chevron.down")
                                        .rotationEffect(Angle(degrees: noticesExpanded ? 180 : 0))
                                }
                            }
                            Text(StoreApp.notice)
                                .font(.body)
                                .frame(minHeight: 0, maxHeight: noticesExpanded ? nil : 0, alignment: .top)
                                .animation(.spring(), value: noticesExpanded)
                                .clipped()
                                .padding(.top, noticesExpanded ? 8 : 0)
                        }
                        
                        if !SystemConfig.isPlaySignActive() {
                            Divider()
                            HStack(spacing: 12) {
                                Text("Having problems logging into apps?").font(.title3)
                                Button("Enable PlaySign") { showSetup = true }
                                    .buttonStyle(.borderedProminent).accentColor(.accentColor).controlSize(.large)
                            }.frame(maxWidth: .infinity)
                        }
                    }.padding()
                }
                .background(.regularMaterial)
                .overlay(GeometryReader { geomatry in
                    Text("")
                        .onChange(of: geomatry.size.height) { v in bottomHeight = v }
                        .onAppear {
                            print("Bottom height: \(geomatry.size.height)")
                            bottomHeight = geomatry.size.height
                        }
                })
            }
            .toast(isPresenting: $showToast) {
                AlertToast(type: .regular, title: "Logs copied!")
            }
            .sheet(isPresented: $showSetup) {
                SetupView()
            }
            .alert("PlayCover must be in the Applications folder. Press the button below to let PlayCover move itself to /Applications.", isPresented: $integrity.integrityOff) {
                Button("Move to /Applications", role: .cancel) {
                    integrity.moveToApps()
                }
            }
        }
    }
}
