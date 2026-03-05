//
//  SearchLocationService.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 05.03.2026.
//

import Foundation
import YandexMapsMobile

final class SearchLocationService: NSObject, YMKMapCameraListener {

	// MARK: - Public Properties

	var onSearchResult: ((YMKSearchResponse) -> Void)?

	// MARK: - Private Properties

	private let searchManager: YMKSearchManager

	private var searchSession: YMKSearchSession?

	private var filters: Set<SearchOption> = []

	// MARK: - Init

	init(
		searchManager: YMKSearchManager = YMKSearchFactory.instance().createSearchManager(with: .combined)
	) {
		self.searchManager = searchManager
	}

	// MARK: - Public Methods

	func setFilters(option: SearchOption) {
		if filters.contains(option) {
			filters.remove(option)
		} else {
			filters.insert(option)
		}
	}

	func onCameraPositionChanged(
		with map: YMKMap,
		cameraPosition: YMKCameraPosition,
		cameraUpdateReason: YMKCameraUpdateReason,
		finished: Bool
	) {
		guard finished else { return }
		guard !filters.isEmpty else { return }

		let responseHandler = {(searchResponse: YMKSearchResponse?, error: Error?) -> Void in
			if let response = searchResponse {
				self.onSearchResponse(response)
			} else {
				self.onSearchError(error!)
			}
		}

		searchSession = searchManager.submit(
			withText: filters.map { $0.rawValue }.joined(separator: ", "),
			geometry: YMKVisibleRegionUtils.toPolygon(with: map.visibleRegion),
			searchOptions: YMKSearchOptions(),
			responseHandler: responseHandler
		)
	}

	func onSearchResponse(_ response: YMKSearchResponse) {
		onSearchResult?(response)
	}

	func onSearchError(_ error: Error) {
		let searchError = (error as NSError).userInfo[YRTUnderlyingErrorKey] as! YRTError
		var errorMessage = "Unknown error"
		if searchError.isKind(of: YRTNetworkError.self) {
			errorMessage = "Network error"
		} else if searchError.isKind(of: YRTRemoteError.self) {
			errorMessage = "Remote server error"
		}
		print("❌ ERROR: \(errorMessage)")
	}
}
