//
//  CachedAsyncImageWrapper.swift
//  PlayCover
//
//  Created by TheMoonThatRises on 1/28/25.
//

import CachedAsyncImage
import SwiftUI

struct CachedAsyncImageWrapper: View {

    let url: String?
    let placeholder: ((String) -> any View)?
    let image: (CPImage) -> any View
    let error: ((String, @escaping () -> Void) -> any View)?

    var body: some View {
        if let url = url, !url.isEmpty {
            CachedAsyncImage(url: url, placeholder: placeholder, image: image, error: error)
        } else {
            if let placeholder = placeholder {
                AnyView(placeholder(""))
            }
        }
    }

}
