//
//  AlertDataModel.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 06.03.2026.
//

import Foundation

struct AlertDataModel: Identifiable, Equatable {
	let id = UUID()
	let title: String
	let message: String
}
