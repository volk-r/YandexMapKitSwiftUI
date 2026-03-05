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
	@ObservationIgnored private let searchLocationService: SearchLocationService

	@ObservationIgnored private var lastUserLocation: CLLocation? = nil

	// MARK: - Init

	override init() {
		searchLocationService = SearchLocationService()
		super.init()
		setupLocation()
		setupSearchService()
		centerMapLocation(target: YMKPoint(latitude: 0, longitude: 0))
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

	func checkLocationAndCenter() {
		guard let myLocation = lastUserLocation else { return }
		centerMapLocation(
			target: YMKPoint(
				latitude: myLocation.coordinate.latitude,
				longitude: myLocation.coordinate.longitude
			),
			animation: YMKAnimation(type: YMKAnimationType.smooth, duration: 0.5)
		)
	}

	func toggleFilter(_ filter: SearchOption) {
		searchLocationService.setFilters(option: filter)
		clearMap()
	}
}

// MARK: - Private Methods

private extension LocationManager {

	func setupLocation() {
		manager.delegate = self
		manager.requestAlwaysAuthorization()
	}

	func setupSearchService() {
		mapView.mapWindow.map.addCameraListener(with: searchLocationService)
		searchLocationService.onSearchResult = { [weak self] response in
			self?.addPlaceMarksOnMap(response: response)
		}
	}

	func centerMapLocation(target location: YMKPoint?, animation: YMKAnimation? = nil) {
		guard let location else { print("❌ Failed to get user location"); return }
		mapView.mapWindow.map.move(
			with: YMKCameraPosition(target: location, zoom: 18, azimuth: 0, tilt: 0),
			animation: animation
		)
	}

	func addUserLocationLayer() {
		let mapKit = YMKMapKit.sharedInstance()
		let userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)

		userLocationLayer.setVisibleWithOn(true)
		userLocationLayer.isHeadingModeActive = true
		userLocationLayer.setObjectListenerWith(self)
	}

	func clearMap() {
		mapView.mapWindow.map.mapObjects.clear()
	}

	func addPlaceMarksOnMap(response: YMKSearchResponse) {
		for searchResult in response.collection.children {
			if let point = searchResult.obj?.geometry.first?.point {
				// Задание координат точки
				let placemark = mapView.mapWindow.map.mapObjects.addPlacemark()
				placemark.geometry = point
				// Делаем подпись
				placemark.setTextWithText(
					searchResult.obj?.descriptionText ?? "",
					style: {
						let textStyle = YMKTextStyle()
						textStyle.size = 10.0
						textStyle.placement = .bottom
						textStyle.offset = 5.0
						return textStyle
					}()
				)
				// Настройка и добавление иконки
				placemark.setIconWith(
					UIImage(named: "SearchResult")!, // убедитесь, что иконка добавлена в Assets
					style: YMKIconStyle(
						anchor: CGPoint(x: 0, y: 0) as NSValue,
						rotationType: YMKRotationType.rotate.rawValue as NSNumber,
						zIndex: 0,
						flat: true,
						visible: true,
						scale: 1.5,
						tappableArea: nil
					)
				)
			}
		}
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
		view.arrow.setIconWith(UIImage(named:"UserArrow")!)

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

