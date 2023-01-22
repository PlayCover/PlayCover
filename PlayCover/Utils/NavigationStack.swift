//
//  NavigationStack.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 11/2/1401 AP.
//

import SwiftUI

enum StackNavigationTransition: Equatable {
    static func == (lhs: StackNavigationTransition, rhs: StackNavigationTransition) -> Bool {
        lhs.id == rhs.id
    }
    
    case none, defaultTranisition, custom(AnyTransition)

    var id: String {
        switch self {
        case .none: return "none"
        case .defaultTranisition: return "default"
        case .custom: return "custom"
        }
    }

    var anyTransition: AnyTransition {
        switch self {
        case .none:
            return AnyTransition.identity
        case .defaultTranisition:
            /// In this case you need to wrap `showingSubview = true` in the
            /// root of the view view in a `withAnimation(.spring()) { ... }`
            return AnyTransition.move(edge: .trailing)
        case .custom(let transition):
            return transition
        }
    }
}

struct StackNavigationView<RootContent>: View where RootContent: View {
    let rootView: () -> RootContent

    @Binding var currentSubview: AnyView
    @Binding var showingSubview: Bool
    @State var transition: StackNavigationTransition

    init(currentSubview: Binding<AnyView>,
         showingSubview: Binding<Bool>,
         transition: StackNavigationTransition,
         @ViewBuilder rootView: @escaping () -> RootContent) {
        self._currentSubview = currentSubview
        self._showingSubview = showingSubview
        self.transition = transition
        self.rootView = rootView
    }

    var body: some View {
        VStack {
            if !showingSubview {
                rootView()
                    .zIndex(-1)
                    .transition(transition == .defaultTranisition
                                ? .move(edge: .leading)
                                : transition.anyTransition)
            } else {
                StackNavigationSubview(currentSubview: $currentSubview,
                                       isVisible: $showingSubview,
                                       transition: transition) {
                    currentSubview
                        .transition(transition.anyTransition)
                        .zIndex(1)
                }
            }
        }
    }

    private struct StackNavigationSubview<Content>: View where Content: View {
        let subviewContent: () -> Content

        @Binding var currentSubview: AnyView
        @Binding var isVisible: Bool
        @State var transition: StackNavigationTransition

        init(currentSubview: Binding<AnyView>,
             isVisible: Binding<Bool>,
             transition: StackNavigationTransition,
             subviewContent: @escaping () -> Content) {
            self.subviewContent = subviewContent
            self._currentSubview = currentSubview
            self._isVisible = isVisible
            self.transition = transition
        }

        var body: some View {
            subviewContent() // subview
                .toolbar {
                    ToolbarItem(placement: .navigation) {
                        Button {
                            currentSubview = AnyView(EmptyView())
                            switch transition {
                            case .defaultTranisition:
                                withAnimation(.spring()) {
                                    isVisible = false
                                }
                            default:
                                isVisible = false
                            }
                        } label: {
                            Label("BACK", systemImage: "chevron.left")
                        }
                    }
                }
        }
    }
}
