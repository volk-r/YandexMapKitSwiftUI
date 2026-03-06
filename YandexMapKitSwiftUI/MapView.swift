//
//  MapView.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 03.03.2026.
//

import SwiftUI

struct MapView: View {

	@State var locationManager = LocationManager()

	@State private var alert: AlertDataModel?

	var body: some View {
		ZStack{
			YandexMapView()
				.ignoresSafeArea()
				.environment(\.locationManager, locationManager)

			mapButtonsView
		}
		.onAppear {
			Task {
				await locationManager.currentUserLocation()
			}
		}
		.onChange(of: locationManager.alertData) {
			alert = locationManager.alertData
		}
		.alert(item: $alert) { data in
			Alert(
				title: Text(data.title),
				message: Text(data.message),
				dismissButton: .default(Text("OK")) {
					alert = nil
				}
			)
		}
	}
}

private extension MapView {

	var mapButtonsView: some View {
		VStack {
			HStack {
				Spacer()
				VStack {
					ButtonMap(type: .department) {
						locationManager.toggleFilter(.department)
					}
					.padding(.top, 20)

					ButtonMap(type: .atm) {
						locationManager.toggleFilter(.atm)
					}
					.padding(.top, 5)

					ButtonMap(type: .location) {
						locationManager.checkLocationAndCenter()
					}
					.padding(.top, 20)
				}
				.padding(.trailing, 20)
			}
			Spacer()
		}
	}
}
