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
	
	func application(
		_ application: UIApplication,
		configurationForConnecting connectingSceneSession: UISceneSession,
		options: UIScene.ConnectionOptions
	) -> UISceneConfiguration {
		let sceneConfig: UISceneConfiguration = UISceneConfiguration(
			name: nil,
			sessionRole: connectingSceneSession.role
		)
		sceneConfig.delegateClass = SceneDelegate.self
		return sceneConfig
	}
}
