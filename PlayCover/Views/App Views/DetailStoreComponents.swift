//
//  ViewExtenstions.swift
//  PlayCover
//
//  Created by Amir Mohammadi on 9/26/1401 AP.
//

import SwiftUI
import CachedAsyncImage

struct VerticalSpacer: View {
     var body: some View {
         Spacer()
         Divider()
             .frame(height: 50)
         Spacer()
     }
 }

struct BadgeView: View {
    @Binding var lookupIsNil: Bool
    @Binding var badgeInfo: String

    @State var badgeText: LocalizedStringKey
    @State var dataIsFromSource: Bool

    @State private var notSpecified: LocalizedStringKey = "ipaLibrary.detailed.nil"

    var body: some View {
        VStack {
            Text(badgeText)
                .textCase(.uppercase)
                .font(.subheadline.bold())
                .foregroundColor(Color(nsColor: .tertiaryLabelColor))
            Group {
                if lookupIsNil && !dataIsFromSource {
                    Text(notSpecified)
                } else {
                    Text(badgeInfo)
                }
            }
            .font(lookupIsNil && !dataIsFromSource ? .subheadline : .title2.bold())
            .padding(.top, 1)
        }
    }
}

struct EnlargedBanner: View {
    @Environment(\.presentationMode) private var presentationMode

    @Binding var presentedBannerURL: URL?
    @Binding var bannerImageURLs: [URL?]
    @Binding var bannerIsPresented: Bool

    var body: some View {
        CachedAsyncImage(url: presentedBannerURL, urlCache: .screenshotCache) { image in
            image
                .resizable()
                .aspectRatio(contentMode: .fit)
                .onTapGesture {
                    presentationMode.wrappedValue.dismiss()
                    bannerIsPresented = false
                }
        } placeholder: {
            ProgressView()
                .progressViewStyle(.circular)
        }
        .frame(maxHeight: 500)
        .overlay {
            VStack {
                HStack {
                    Spacer()
                    Button {
                        presentationMode.wrappedValue.dismiss()
                        bannerIsPresented = false
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .frame(width: 25, height: 25)
                            .shadow(radius: 5)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
                Spacer()
                let currentIndex = bannerImageURLs.firstIndex { url in
                    url == presentedBannerURL
                }
                HStack {
                    Button {
                        if var currentIndex = currentIndex {
                            if currentIndex > 0 {
                                currentIndex -= 1
                                presentedBannerURL = bannerImageURLs[currentIndex]
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.backward.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .frame(width: 25, height: 25)
                            .shadow(radius: 5)
                    }
                    .buttonStyle(.plain)
                    .padding()
                    Spacer()
                    Button {
                        if var currentIndex = currentIndex {
                            if currentIndex < bannerImageURLs.count - 1 {
                                currentIndex += 1
                                presentedBannerURL = bannerImageURLs[currentIndex]
                            }
                        }
                    } label: {
                        Image(systemName: "chevron.forward.circle.fill")
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .foregroundColor(.white)
                            .frame(width: 25, height: 25)
                            .shadow(radius: 5)
                    }
                    .buttonStyle(.plain)
                    .padding()
                }
            }
        }
    }
}
