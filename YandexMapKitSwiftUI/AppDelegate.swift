//
//  AppDelegate.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 03.03.2026.
//

import SwiftUI
import YandexMapsMobile

class AppDelegate: NSObject, UIApplicationDelegate {

	let MAPKIT_API_KEY = "YOUR_API_KEY"

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
	) -> Bool {
		YMKMapKit.setApiKey(MAPKIT_API_KEY)
		// YMKMapKit.setLocale("ru_RU") // если хотим установить конкретную локаль
		YMKMapKit.sharedInstance()
		return true
	}
}
