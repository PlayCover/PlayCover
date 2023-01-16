//
//  ViewExtenstions.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/26/1401 AP.
//

import SwiftUI

struct StackNavigationView<RootContent>: View where RootContent: View {

    @Binding var currentSubview: AnyView
    @Binding var showingSubview: Bool

    var body: some View {
        VStack {
            if !showingSubview {
                rootView()
                    .zIndex(-1)
            } else {
                StackNavigationSubview(isVisible: $showingSubview) {
                    currentSubview
                }
            }
        }
    }

    let rootView: () -> RootContent

    init(currentSubview: Binding<AnyView>, showingSubview: Binding<Bool>,
         @ViewBuilder rootView: @escaping () -> RootContent) {
        self._currentSubview = currentSubview
        self._showingSubview = showingSubview
        self.rootView = rootView
    }

    private struct StackNavigationSubview<Content>: View where Content: View {
        @Binding var isVisible: Bool
        let contentView: () -> Content

        var body: some View {
            VStack {
                contentView() // subview
            }
            .toolbar {
                ToolbarItem(placement: .navigation) {
                    Button {
                        isVisible = false
                    } label: {
                        Label("BACK", systemImage: "chevron.left")
                    }
                }
            }
        }
    }
}
