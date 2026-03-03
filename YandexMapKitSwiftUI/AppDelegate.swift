//
//  AppDelegate.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 03.03.2026.
//

import SwiftUI
import YandexMapsMobile

class AppDelegate: NSObject, UIApplicationDelegate {

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
	) -> Bool {
		print("App Did Launch!")
		YMKMapKit.setApiKey("Ваш API-ключ")
		// YMKMapKit.setLocale("ru_RU") // если хотим установить конкретную локаль
		YMKMapKit.sharedInstance()
		return true
	}
}
