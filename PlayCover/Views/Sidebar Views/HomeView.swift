//
//  HomeView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 06/08/2022.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject var appsVM: AppsVM

    // swiftlint: disable line_length

    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                LargeAppView(app: appsVM.apps[0])
                Spacer()
                    .frame(height: 20)
                HStack {
                    HalfAppBannerView(app: appsVM.apps[0], gradient: LinearGradient(colors: [Color(hue: 50/360, saturation: 1, brightness: 0.8), Color(hue: 10/360, saturation: 1, brightness: 0.8)], startPoint: UnitPoint.topLeading, endPoint: UnitPoint.bottomTrailing))
                    Spacer()
                        .frame(width: 20)
                    HalfAppBannerView(app: appsVM.apps[1], gradient: LinearGradient(colors: [Color(hue: 270/360, saturation: 1, brightness: 0.8), Color(hue: 290/360, saturation: 1, brightness: 0.8)], startPoint: UnitPoint.topLeading, endPoint: UnitPoint.bottomTrailing))
                }
                Divider()
                    .padding(.vertical)
                HStack {
                    Text("Recently Opened Apps")
                        .font(.title2)
                        .fontWeight(.semibold)
                    Spacer()
                    Text("See All")
                        .foregroundColor(.cyan)
                }
                HStack {
                    VStack {
                        SmallAppBannerView(app: appsVM.apps[0])
                        SmallAppBannerView(app: appsVM.apps[0])
                        SmallAppBannerView(app: appsVM.apps[0])
                        SmallAppBannerView(app: appsVM.apps[0])
                        SmallAppBannerView(app: appsVM.apps[0])
                        SmallAppBannerView(app: appsVM.apps[0])
                    }
                    Spacer()
                        .frame(width: 40)
                    VStack {
                        SmallAppBannerView(app: appsVM.apps[1])
                        SmallAppBannerView(app: appsVM.apps[1])
                        SmallAppBannerView(app: appsVM.apps[1])
                        SmallAppBannerView(app: appsVM.apps[1])
                        SmallAppBannerView(app: appsVM.apps[1])
                        SmallAppBannerView(app: appsVM.apps[1])
                    }
                }
            }
            .padding(.all)
        }
        .navigationTitle("Home")
    }
}

struct LargeAppView: View {
    @State var app: PlayApp

    var body: some View {
        HStack {
            if let img = app.icon {
                Image(nsImage: img)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 150, height: 150)
                .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                .shadow(radius: 10)
                .padding(.all)
            }
            VStack(alignment: .leading) {
                Text(app.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text("You've played a total of 31.2 hours of \(app.name) this week, beating last week's record of 12.2 hours!")
                    .foregroundColor(.white)
                Spacer()
                    .frame(height: 20)
                Text("Ready to play again?")
                    .foregroundColor(.white)
                Text("OPEN")
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(cgColor: .white))
                    )
            }
            .padding(.all)
            Spacer()
        }
        .background(LinearGradient(colors: [Color(hue: 180/360, saturation: 1, brightness: 0.8), Color(hue: 200/360, saturation: 1, brightness: 0.8)], startPoint: UnitPoint.topLeading, endPoint: UnitPoint.bottomTrailing))
        .clipShape(RoundedRectangle(cornerRadius: 10))
        .shadow(radius: 5)
    }
}

struct HalfAppBannerView: View {
    @State var app: PlayApp
    @State var gradient: LinearGradient

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(app.name)
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(app.info.bundleVersion)
                    .foregroundColor(.white)
                Spacer()
                    .frame(height: 10)
                Text("Open")
                    .textCase(.uppercase)
                    .foregroundColor(.blue)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 5)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(cgColor: .white))
                    )
            }
            Spacer()
            if let img = app.icon {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 80, height: 80)
                    .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                    .shadow(radius: 10)
            }
        }
        .padding(.horizontal)
        .frame(height: 100, alignment: .leading)
        .background(RoundedRectangle(cornerRadius: 10, style: .continuous).fill(gradient))
        .shadow(radius: 5)
    }
}

struct SmallAppBannerView: View {
    @State var app: PlayApp

    var body: some View {
        HStack {
            if let img = app.icon {
                Image(nsImage: img)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 40, height: 40)
                    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
                    .shadow(radius: 10)
            }
            VStack(alignment: .leading) {
                Text(app.name)
                Text(app.info.bundleVersion)
                    .foregroundColor(.gray)
            }
            Spacer()
            Text("Open")
                .textCase(.uppercase)
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 5)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous).fill(Color(cgColor: .white))
                )
        }
        .frame(height: 50, alignment: .leading)
    }
}

struct HomeView_Preview: PreviewProvider {
    static var previews: some View {
        HomeView()
    }
}
