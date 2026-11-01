//
//  AppEnvironment.swift
//  PlayCover
//

import SwiftUI

/// Composition root: builds every long-lived store and service once, passes each its dependencies, and
/// hands them to SwiftUI through `.environment(_:)`.
///
/// Each type's `static shared` only forwards here, for code outside the view tree (installers, AppKit
/// callbacks). Initializers must stay free of side effects and must not touch any `shared`; launch work
/// belongs in `bootstrap()`.
@MainActor
final class AppEnvironment {
    static let shared = AppEnvironment()

    let alerts: AlertPresenter
    let log: Log
    let installPreferences: InstallPreferences
    let uninstallPreferences: UninstallPreferences
    let keyCoverPreferences: KeyCoverPreferences
    let keyCover: KeyCoverService
    let modifierKeys: ModifierKeyObserver
    let urlObservable: URLObservable
    let toasts: ToastVM
    let install: InstallVM
    let download: DownloadVM
    let apps: AppsVM
    let store: StoreVM
    let integrity: AppIntegrity

    private var isBootstrapped = false

    init(defaults: UserDefaults = .standard) {
        alerts = AlertPresenter()
        log = Log(alerts: alerts)
        installPreferences = InstallPreferences(defaults: defaults)
        uninstallPreferences = UninstallPreferences(defaults: defaults)
        keyCoverPreferences = KeyCoverPreferences(defaults: defaults)
        keyCover = KeyCoverService(preferences: keyCoverPreferences, alerts: alerts)
        modifierKeys = ModifierKeyObserver()
        urlObservable = URLObservable()
        toasts = ToastVM()
        install = InstallVM()
        download = DownloadVM()
        apps = AppsVM()
        store = StoreVM()
        integrity = AppIntegrity()
    }

    /// Launch-time side effects, in order: library folders and PlayTools, then the library scan, then
    /// the network fetch of sources. Safe to call more than once.
    func bootstrap() {
        guard !isBootstrapped else { return }
        isBootstrapped = true
        apps.bootstrap()
        store.bootstrap()
    }
}

extension View {
    /// Injects every store and service from `environment` into this view hierarchy.
    func appEnvironment(_ environment: AppEnvironment = .shared) -> some View {
        self
            .environment(environment.installPreferences)
            .environment(environment.uninstallPreferences)
            .environment(environment.keyCoverPreferences)
            .environment(environment.keyCover)
            .environment(environment.modifierKeys)
            .environment(environment.urlObservable)
            .environment(environment.toasts)
            .environment(environment.install)
            .environment(environment.download)
            .environment(environment.apps)
            .environment(environment.store)
            .environment(environment.integrity)
    }
}
