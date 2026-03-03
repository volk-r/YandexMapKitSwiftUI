//
//  MapView.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 03.03.2026.
//

import SwiftUI

struct MapView: View {

	@State var locationManager = LocationManager()

	var body: some View {
		ZStack{
			YandexMapView()
				.ignoresSafeArea()
				.environment(\.locationManager, locationManager)
		}
		.task {
			await locationManager.currentUserLocation()
		}
	}
}
