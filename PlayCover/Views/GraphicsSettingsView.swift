//
//  GraphicsSettingsView.swift
//  PlayCover
//
//  Created by Isaac Marovitz on 14/08/2022.
//

import SwiftUI

// swiftlint:disable:next type_body_length
struct GraphicsView: View {
    @Binding var settings: AppSettings
    @State var customWidth = 1920
    @State var customHeight = 1080
    @State var showResolutionWarning = false
    @AppStorage("settings.settings.inverseScreenValues") private var inverseScreenValues = false
    @AppStorage("settings.settings.disableTimeout") private var disableTimeout = false
    @AppStorage("settings.toggle.hideTitleBar") private var hideTitleBar = false
    @AppStorage("settings.toggle.floatingWindow") private var floatingWindow = false
    @AppStorage("settings.settings.displayRotation") private var displayRotation = 0
    static var number: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .none
        return formatter
    }

    @State var customScaler = 2.0
    static var fractionFormatter: NumberFormatter {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.maximumFractionDigits = 1
        formatter.minimumFractionDigits = 1
        formatter.decimalSeparator = "."
        return formatter
    }

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("settings.picker.iosDevice")
                    Spacer()
                    Picker("", selection: $settings.settings.iosDeviceModel) {
                        Text("iPad Pro (12.9-inch) (1st gen) | A9X | 4GB").tag("iPad6,7")
                        Text("iPad Pro (12.9-inch) (3rd gen) | A12X | 4GB").tag("iPad8,6")
                        Text("iPad Pro (12.9-inch) (5th gen) | M1 | 8GB").tag("iPad13,8")
                        Text("iPad Pro (12.9-inch) (6th gen) | M2 | 8GB").tag("iPad14,5")
                        Text("iPad Pro (13-inch) (7th gen) | M4 | 8GB").tag("iPad16,6")
                        Text("iPad Pro (13-inch) (8th gen) | M5 | 16GB").tag("iPad17,4")
                        Divider()
                        Text("iPhone 13 Pro Max | A15 | 6GB").tag("iPhone14,3")
                        Text("iPhone 14 Pro Max | A16 | 6GB").tag("iPhone15,3")
                        Text("iPhone 15 Pro Max | A17 Pro | 8GB").tag("iPhone16,2")
                        Text("iPhone 16 Pro Max | A18 Pro | 8GB").tag("iPhone17,2")
                    }
                    .frame(width: 250)
                }
                HStack {
                    if showResolutionWarning {
                        Spacer()
                        let highResIcon = Image(systemName: "exclamationmark.triangle")
                        let warning = NSLocalizedString("settings.highResolution", comment: "")

                        Text("\(highResIcon) \(warning)")
                            .font(.caption)
                    } else {
                        Spacer()
                    }
                }
                HStack {
                    Text("settings.picker.adaptiveRes")
                    Spacer()
                    Picker("", selection: $settings.settings.resolution) {
                        Text("settings.picker.adaptiveRes.0").tag(0)
                        Text("settings.picker.adaptiveRes.1").tag(1)
                        Text("1080p").tag(2)
                        Text("1440p").tag(3)
                        Text("4K").tag(4)
                        Text("settings.picker.adaptiveRes.5").tag(5)
                        Text("settings.picker.adaptiveRes.6").tag(6)
                    }
                    .frame(width: 250, alignment: .leading)
                    .help("settings.picker.adaptiveRes.help")
                }
                HStack {
                    if settings.settings.resolution == 5 {
                        Text(NSLocalizedString("settings.text.customWidth", comment: "") + ":")
                        Stepper {
                            TextField(
                                "settings.text.customWidth",
                                value: $customWidth,
                                formatter: GraphicsView.number,
                                onCommit: {
                                    Task { @MainActor in
                                        NSApp.keyWindow?.makeFirstResponder(nil)
                                    }
                                })
                                .frame(width: 125)
                        }
                        onIncrement: { customWidth += 1 }
                        onDecrement: { customWidth -= 1 }
                        Spacer()
                        Text(NSLocalizedString("settings.text.customHeight", comment: "") + ":")
                        Stepper {
                            TextField(
                                "settings.text.customHeight",
                                value: $customHeight,
                                formatter: GraphicsView.number,
                                onCommit: {
                                    Task { @MainActor in
                                        NSApp.keyWindow?.makeFirstResponder(nil)
                                    }
                                })
                                .frame(width: 125)
                        } onIncrement: {
                            customHeight += 1
                        } onDecrement: {
                            customHeight -= 1
                        }
                    } else if settings.settings.resolution >= 2 && settings.settings.resolution <= 4 {
                        Text("settings.picker.aspectRatio")
                        Spacer()
                        Picker("", selection: $settings.settings.aspectRatio) {
                            Text("4:3").tag(0)
                            Text("16:9").tag(1)
                            Text("16:10").tag(2)
                        }
                        .pickerStyle(.radioGroup)
                        .horizontalRadioGroupLayout()
                    } else if settings.settings.resolution == 6 {
                        Text("settings.picker.aspectRatio")
                        VStack(alignment: .trailing) {
                            Picker("", selection: $settings.settings.resizableAspectRatioType) {
                                Text("settings.picker.aspectRatio.free").tag(0)
                                Text("settings.picker.aspectRatio.custom").tag(1)
                                Text("4:3").tag(2)
                                Text("16:9").tag(3)
                                Text("16:10").tag(4)
                            }
                            .pickerStyle(.radioGroup)
                            .horizontalRadioGroupLayout()
                            if settings.settings.resizableAspectRatioType == 1 {
                                HStack {
                                    TextField("", value: $settings.settings.resizableAspectRatioWidth,
                                              formatter: GraphicsView.number)
                                    .frame(width: 110)
                                    Text(":")
                                    TextField("", value: $settings.settings.resizableAspectRatioHeight,
                                              formatter: GraphicsView.number)
                                    .frame(width: 110)
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .trailing)
                    } else if settings.settings.resolution == 1 {
                        let resolution = AppSettings.autoResolution()
                        Text("settings.text.detectedResolution")
                        Spacer()
                        Text("\(resolution.width) x \(resolution.height)")
                    } else {
                        Spacer()
                    }
                }
                HStack {
                    Text("settings.picker.scaler")
                    Spacer()
                    Stepper {
                        TextField(
                            "settings.text.scaler",
                            value: $customScaler,
                            formatter: GraphicsView.fractionFormatter,
                            onCommit: {
                                Task { @MainActor in NSApp.keyWindow?.makeFirstResponder(nil) }
                            })
                            .frame(width: 125)
                    } onIncrement: {
                        customScaler += 0.1
                    } onDecrement: {
                        if customScaler > 0.5 { customScaler -= 0.1 }
                    }
                }
                VStack(alignment: .leading) {
                    HStack {
                        Toggle("settings.picker.windowFix", isOn: $settings.settings.inverseScreenValues)
                            .help("settings.picker.windowFix.help")
                            .onChange(of: settings.settings.inverseScreenValues) {
                                settings.settings.windowFixMethod = 0
                            }
                        Spacer()
                        // Dropdown to choose fix method
                        Picker("", selection: $settings.settings.windowFixMethod) {
                            Text("settings.picker.windowFixMethod.0").tag(0)
                            Text("settings.picker.windowFixMethod.1").tag(1)
                        }
                        .frame(alignment: .leading)
                        .help("settings.picker.windowFixMethod.help")
                        .disabled(!settings.settings.inverseScreenValues)
                        .disabled(settings.settings.resolution != 0)
                    }
                    Spacer()
                    Toggle("settings.toggle.overrideFullScreen", isOn: $settings.settings.overrideFullScreen)
                        .help("settings.toggle.overrideFullScreen.help")
                        .disabled(settings.settings.resolution == 6)
                    Spacer()
                    HStack {
                        Text("settings.settings.displayRotation")
                        Spacer()
                        Picker("", selection: $settings.settings.displayRotation) {
                            Text("settings.settings.displayRotation.default").tag(0)
                            Text("settings.settings.displayRotation.portrait").tag(1)
                            Text("settings.settings.displayRotation.landscapeRight").tag(2)
                            Text("settings.settings.displayRotation.portraitUpsideDown").tag(3)
                            Text("settings.settings.displayRotation.flipFix").tag(4)
                        }
                        .frame(alignment: .leading)
                    }
                    Spacer()
                    Toggle("settings.toggle.disableDisplaySleep", isOn: $settings.settings.disableTimeout)
                        .help("settings.toggle.disableDisplaySleep.help")
                    Spacer()
                    Toggle("settings.toggle.hideTitleBar", isOn: $settings.settings.hideTitleBar)
                    Spacer()
                    Toggle("settings.toggle.floatingWindow", isOn: $settings.settings.floatingWindow)
                    Spacer()
                }
                Spacer()
            }
            .padding()
            .onAppear {
                customWidth = settings.settings.windowWidth
                customHeight = settings.settings.windowHeight
                customScaler = settings.settings.customScaler
            }
            .onChange(of: settings.settings.resolution) {
                setResolution()
            }
            .onChange(of: settings.settings.aspectRatio) {
                setResolution()
            }
            .onChange(of: customWidth) {
                setResolution()
            }
            .onChange(of: customHeight) {
                setResolution()
            }
            .onChange(of: customScaler) {
                setResolution()
            }
            .onChange(of: settings.settings.resizableAspectRatioType) {
                setAspectRatioForResizableWindow()
            }
        }
    }

    func setResolution() {
        var width: Int
        var height: Int

        switch settings.settings.resolution {
        // Adaptive resolution = Auto
        case 1:
            let resolution = AppSettings.autoResolution()
            width = resolution.width
            height = resolution.height
        // Adaptive resolution = 1080p
        case 2:
            height = 1080
            width = getWidthFromAspectRatio(height)
        // Adaptive resolution = 1440p
        case 3:
            height = 1440
            width = getWidthFromAspectRatio(height)
        // Adaptive resolution = 4K
        case 4:
            height = 2160
            width = getWidthFromAspectRatio(height)
        // Adaptive resolution = Custom
        case 5:
            width = customWidth
            height = customHeight
        // Adaptive resolution = Off
        default:
            height = 1080
            width = 1920
        }

        settings.settings.windowWidth = width
        settings.settings.windowHeight = height
        settings.settings.customScaler = customScaler

        showResolutionWarning = Double(width * height) * customScaler >= 2621440 * 2.0
        // Tends to crash when the number of pixels exceeds that
    }

    func getWidthFromAspectRatio(_ height: Int) -> Int {
        var widthRatio: Int
        var heightRatio: Int

        switch settings.settings.aspectRatio {
        case 0:
            widthRatio = 4
            heightRatio = 3
        case 1:
            widthRatio = 16
            heightRatio = 9
        case 2:
            widthRatio = 16
            heightRatio = 10
        default:
            widthRatio = 16
            heightRatio = 9
        }
        return (height / heightRatio) * widthRatio
    }
    func setAspectRatioForResizableWindow() {
        var widthRatio = 0
        var heightRatio = 0

        switch settings.settings.resizableAspectRatioType {
        // Aspect ratio = Free
        case 0:
            widthRatio = 0
            heightRatio = 0
        // Aspect ratio = Custom
        case 1:
            widthRatio = settings.settings.resizableAspectRatioWidth
            heightRatio = settings.settings.resizableAspectRatioHeight
        // Aspect ratio = 4:3
        case 2:
            widthRatio = 4
            heightRatio = 3
        // Aspect ratio = 16:9
        case 3:
            widthRatio = 16
            heightRatio = 9
        // Aspect ratio = 16:10
        case 4:
            widthRatio = 16
            heightRatio = 10
        default:
            widthRatio = 16
            heightRatio = 9
        }

        settings.settings.resizableAspectRatioWidth = widthRatio
        settings.settings.resizableAspectRatioHeight = heightRatio
    }
}
