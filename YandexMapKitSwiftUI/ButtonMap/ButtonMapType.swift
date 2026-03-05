//
//  ButtonMapType.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 05.03.2026.
//

import Foundation

enum ButtonMapType {
	case department
	case atm
	case location

	var icon: String {
		switch self {
		case .department:
			return "rublesign.bank.building.fill"
		case .atm:
			return "creditcard.circle.fill"
		case .location:
			return "location.circle.fill"
		}
	}
}
