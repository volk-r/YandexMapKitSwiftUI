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

	private(set) var alertData: AlertDataModel?

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
		// Note that application must retain strong references to both
		// cluster listener and cluster tap listener
		let collection = mapView.mapWindow.map.mapObjects.addClusterizedPlacemarkCollection(with: self)
		for searchResult in response.collection.children {
			if let point = searchResult.obj?.geometry.first?.point {
				let placemark = collection.addPlacemark()
				// Задание координат точки
				placemark.geometry = point
				// Настройка и добавление иконки
				placemark.setIconWith(UIImage(named: "SearchResult")!)
				// Установка пользовательских данных для метки
				placemark.userData = searchResult.obj
				// Добавление обработки нажатия
				placemark.addTapListener(with: self)
			}
		}
		// Placemarks won't be displayed until this method is called. It must be also called
		// to force clusters update after collection change
		collection.clusterPlacemarks(withClusterRadius: 30, minZoom: 15)
	}

	func addPlaceMarksOnMapWithTitle(response: YMKSearchResponse) {
		for searchResult in response.collection.children {
			if let point = searchResult.obj?.geometry.first?.point {
				let placemark = mapView.mapWindow.map.mapObjects.addPlacemark()
				// Задание координат точки
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

// MARK: - YMKUserLocationObjectListener

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

// MARK: - YMKClusterTapListener

extension LocationManager: YMKClusterTapListener {

	func onClusterTap(with cluster: YMKCluster) -> Bool {
		centerMapLocation(target: cluster.appearance.geometry)
		return true
	}
}

// MARK: - YMKClusterListener

extension LocationManager: YMKClusterListener {

	func onClusterAdded(with cluster: YMKCluster) {
		// We setup cluster appearance and tap handler in this method
		cluster.appearance.setIconWith(clusterImage(cluster.size))
		cluster.addClusterTapListener(with: self)
	}

	func clusterImage(_ clusterSize: UInt) -> UIImage {
		let scale = CGFloat(mapView.mapWindow.scaleFactor)
		let text = (clusterSize as NSNumber).stringValue
		let font = UIFont.systemFont(ofSize: ClusterConstants.FONT_SIZE * scale)
		let size = text.size(withAttributes: [NSAttributedString.Key.font: font])
		let textRadius = sqrt(size.height * size.height + size.width * size.width) / 2
		let internalRadius = textRadius + ClusterConstants.MARGIN_SIZE * scale
		let externalRadius = internalRadius + ClusterConstants.STROKE_SIZE * scale
		let iconSize = CGSize(width: externalRadius * 2, height: externalRadius * 2)

		UIGraphicsBeginImageContext(iconSize)
		let ctx = UIGraphicsGetCurrentContext()!

		ctx.setFillColor(UIColor.green.cgColor)
		ctx.fillEllipse(in: CGRect(
			origin: .zero,
			size: CGSize(width: 2 * externalRadius, height: 2 * externalRadius)));

		ctx.setFillColor(UIColor.white.cgColor)
		ctx.fillEllipse(in: CGRect(
			origin: CGPoint(x: externalRadius - internalRadius, y: externalRadius - internalRadius),
			size: CGSize(width: 2 * internalRadius, height: 2 * internalRadius)));

		(text as NSString).draw(
			in: CGRect(
				origin: CGPoint(x: externalRadius - size.width / 2, y: externalRadius - size.height / 2),
				size: size),
			withAttributes: [
				NSAttributedString.Key.font: font,
				NSAttributedString.Key.foregroundColor: UIColor.black])
		let image = UIGraphicsGetImageFromCurrentImageContext()!

		return image
	}

	private enum ClusterConstants {
		static let PLACEMARKS_NUMBER = 2000
		static let FONT_SIZE: CGFloat = 15
		static let MARGIN_SIZE: CGFloat = 3
		static let STROKE_SIZE: CGFloat = 3
	}
}

// MARK: - YMKLayersGeoObjectTapListener

extension LocationManager: YMKMapObjectTapListener {

	func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
		guard let geoObject = mapObject.userData as? YMKGeoObject else {
			return true
		}

		let type: GeoObjectType

		if let toponym = (
			geoObject.metadataContainer
				.getItemOf(YMKSearchToponymObjectMetadata.self) as? YMKSearchToponymObjectMetadata
		) {
			type = .toponym(address: toponym.address.formattedAddress)
		} else if let business = (
			geoObject.metadataContainer
				.getItemOf(YMKSearchBusinessObjectMetadata.self) as? YMKSearchBusinessObjectMetadata
		) {
			type = .business(
				name: business.name,
				workingHours: business.workingHours?.text,
				categories: business.categories.map { $0.name }.joined(separator: ", "),
				phones: business.phones.map { $0.formattedNumber }.joined(separator: ", "),
				link: business.links.first?.link.href
			)
		} else {
			type = .undefined
		}

		let title = geoObject.name ?? "Unnamed"
		let description = geoObject.descriptionText ?? "No description"
		let location = geoObject.geometry.first?.point
		let uri = (
			geoObject.metadataContainer.getItemOf(YMKUriObjectMetadata.self) as? YMKUriObjectMetadata
		)?.uris.first?.value

		var message = description + "\n"
		if let location = location {
			message += "Location: (\(location.latitude), \(location.longitude))" + "\n"
		}
		if let uri = uri {
			message += "URI: \(uri)" + "\n"
		}

		switch type {
		case .toponym(let address):
			message += """
			Type: Toponym
			Address: \(address)
			"""
		case let .business(name, workingHours, categories, phones, link):
			message += """
			Type: Business
			Name: \(name)
			Working hours: \(workingHours ?? "No info")
			Categories: \(categories ?? "No info")
			Phones: \(phones ?? "No info")
			Link: \(link ?? "No info")
			"""
		case .undefined:
			message += "Undefined type"
		}

		alertData = AlertDataModel(title: title, message: message)

		return true
	}

	// MARK: - Private nesting

	enum GeoObjectType {
		case toponym(address: String)
		case business(
			name: String,
			workingHours: String?,
			categories: String?,
			phones: String?,
			link: String?
		)
		case undefined
	}
}