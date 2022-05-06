//
//  Analytics.swift
//  PlayCover
//

import Foundation
import AppCenter
import AppCenterAnalytics
import AppCenterCrashes

final class AnalyticsService {
    
    static let shared = AnalyticsService()
    
    private init() {}
    
    func start() {
        AppCenter.start(withAppSecret: "b2814ea4-0672-47c0-8968-ae2686010e95", services:[
          Analytics.self,
          Crashes.self
        ])
    }
    
    func logAppInstall(_ packageName : String) {
        Analytics.trackEvent("App installed", withProperties: ["id" : packageName])
    }
    
    func logAppLaunch(_ packageName : String) {
        Analytics.trackEvent("App launched", withProperties: ["id" : packageName])
    }
    
}
