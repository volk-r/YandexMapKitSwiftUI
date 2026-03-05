//
//  ButtonMap.swift
//  YandexMapKitSwiftUI
//
//  Created by Roman Romanov on 05.03.2026.
//

import SwiftUI

struct ButtonMap: View {

	let type: ButtonMapType
	let action: @MainActor () -> Void

	@State private var isEnabled: Bool = false

	var body: some View {
		Button(action: {
			action()

			if type != .location {
				isEnabled.toggle()
			}
		}) {
			Image(systemName: type.icon)
				.resizable()
				.frame(width: 34, height: 34)
				.foregroundColor(.black)
		}
		.frame(width: 30, height: 30)
		.padding()
		.background(isEnabled ? Color.blue.opacity(0.3) : Color.gray.opacity(0.2))
		.clipShape(RoundedRectangle(cornerRadius: 15))
	}
}
