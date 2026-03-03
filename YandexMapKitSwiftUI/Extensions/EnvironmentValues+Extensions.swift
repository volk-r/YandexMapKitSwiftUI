//
//  EnvironmentValues+Extensions.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 03.03.2026.
//

import SwiftUI

private struct LocationManagerKey: EnvironmentKey {
	static let defaultValue: LocationManager = LocationManager()
}

extension EnvironmentValues {
	var locationManager: LocationManager {
		get { self[LocationManagerKey.self] }
		set { self[LocationManagerKey.self] = newValue }
	}
}
