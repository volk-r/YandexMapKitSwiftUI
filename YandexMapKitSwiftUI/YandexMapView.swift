//
//  YandexMapView.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 03.03.2026.
//

import SwiftUI
import YandexMapsMobile

struct YandexMapView: UIViewRepresentable {

	@Environment(\.locationManager) var locationManager

	func makeUIView(context: Context) -> YMKMapView {
		return locationManager.mapView
	}

	func updateUIView(_ mapView: YMKMapView, context: Context) {}
}
