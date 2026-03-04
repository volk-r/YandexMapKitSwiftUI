//
//  LocationManager.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 03.03.2026.
//

import Foundation
import CoreLocation
import YandexMapsMobile

@Observable
final class LocationManager: NSObject {

	// MARK: - Public Properties

	let mapView = YMKMapView()

	// MARK: - Private Properties

	@ObservationIgnored private let manager = CLLocationManager()

	@ObservationIgnored private var lastUserLocation: CLLocation? = nil

	override init() {
		super.init()
		setupLocation()
	}

	// MARK: - Public Methods

	func currentUserLocation() async {
		while !Task.isCancelled {
			if lastUserLocation != nil {
				addUserLocationLayer()
				checkLocationAndCenter()
				return
			}
			try? await Task.sleep(nanoseconds: 100_000_000)
		}
	}
}

// MARK: - Private Methods

private extension LocationManager {

	func setupLocation() {
		manager.delegate = self
		manager.requestAlwaysAuthorization()
	}

	func checkLocationAndCenter() {
		guard let myLocation = lastUserLocation else { return }
		centerMapLocation(
			target: YMKPoint(
				latitude: myLocation.coordinate.latitude,
				longitude: myLocation.coordinate.longitude
			),
			map: mapView
		)
	}

	func centerMapLocation(target location: YMKPoint?, map: YMKMapView) {
		guard let location else { print("Failed to get user location"); return }
		map.mapWindow.map.move(
			with: YMKCameraPosition(target: location, zoom: 18, azimuth: 0, tilt: 0),
			animation: YMKAnimation(type: YMKAnimationType.smooth, duration: 0.5)
		)
	}

	func addUserLocationLayer() {
		let scale = CGFloat(mapView.mapWindow.scaleFactor)
		let mapKit = YMKMapKit.sharedInstance()
		let userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)

		userLocationLayer.setVisibleWithOn(true)
		userLocationLayer.isHeadingModeActive = true
		userLocationLayer.setAnchorWithAnchorNormal(
			CGPoint(
				x: 0.5 * mapView.frame.size.width * scale,
				y: 0.5 * mapView.frame.size.height * scale
			),
			anchorCourse: CGPoint(
				x: 0.5 * mapView.frame.size.width * scale,
				y: 0.83 * mapView.frame.size.height * scale
			)
		)
		userLocationLayer.setObjectListenerWith(self)
	}
}

// MARK: - CLLocationManagerDelegate

extension LocationManager: CLLocationManagerDelegate {

	func locationManager(
		_ manager: CLLocationManager,
		didChangeAuthorization status: CLAuthorizationStatus
	) {
		if status == .authorizedWhenInUse {
			self.manager.startUpdatingLocation()
		}
	}

	func locationManager(
		_ manager: CLLocationManager,
		didUpdateLocations locations: [CLLocation]
	) {
		// Notify listeners that the user has a new location
		lastUserLocation = locations.last
	}
}

extension LocationManager: YMKUserLocationObjectListener {

	func onObjectAdded(with view: YMKUserLocationView) {
		view.arrow.setIconWith(UIImage(systemName: "location.north.fill")!)

		let pinPlacemark = view.pin.useCompositeIcon()

		pinPlacemark.setIconWithName(
			"mappin",
			image: UIImage(systemName: "mappin")!,
			style: YMKIconStyle(
				anchor: CGPoint(x: 0.5, y: 0.5) as NSValue,
				rotationType: YMKRotationType.rotate.rawValue as NSNumber,
				zIndex: 0,
				flat: true,
				visible: true,
				scale: 1.5,
				tappableArea: nil
			)
		)
		view.accuracyCircle.fillColor = UIColor.green.withAlphaComponent(0.1)
		view.accuracyCircle.strokeColor = UIColor.green.withAlphaComponent(0.5)
		view.accuracyCircle.strokeWidth = 0.5
	}
	
	func onObjectRemoved(with view: YMKUserLocationView) {}
	
	func onObjectUpdated(with view: YMKUserLocationView, event: YMKObjectEvent) {}
}

