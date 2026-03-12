# Внедряем Yandex MapKit SDK в SwiftUI приложение

Пошаговый план создания демо приложения на SwiftUI с использованием Yandex MapKit SDK.

<img width="963" height="301" alt="header" src="https://github.com/user-attachments/assets/b38ca767-b9ac-4531-8e7d-c29895803041" />

## Добавляем карты в проект

Для начала необходимо установить библиотеку в проект (через CocoaPods и получить ключ у Яндекса, для ознакомления с установкой прикрепляю ссылку.

> https://yandex.ru/maps-api/docs/mapkit/ios/generated/getting_started.html

Нужно учесть, что есть две версии библиотеки: lite и full, подробнее про разницу между этими версиями можно почитать на официальном сайте или наглядно посмотреть в офф демке. Мы будем ставить сразу full-версию, так как воспользуемся функцией поиска (которой нет в lite версии) в процессе написания Demo приложения.

После установки библиотеки открываем наш **YandexMapKitSwiftUI.xcworkspace**

Далее создаем класс AppDelegate, подробнее как реализовать этот класс в SwiftUI проекте можно посмотреть [здесь](https://paigeshin1991.medium.com/how-to-set-up-your-swiftui-project-with-appdelegate-and-scenedelegate-64cf5566e1e7).

В классе AppDelegate импортируем библиотеку Яндекса и устанавливаем ваш API ключ из кабинета разработчика Яндекса.

```swift
import SwiftUI
import YandexMapsMobile

class AppDelegate: NSObject, UIApplicationDelegate {

	let MAPKIT_API_KEY = "YOUR_API_KEY"

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
	) -> Bool {
		YMKMapKit.setApiKey(MAPKIT_API_KEY)
		// YMKMapKit.setLocale("ru_RU") // если хотим установить конкретную локаль
		YMKMapKit.sharedInstance()
		return true
	}
}
```

Затем идем в таргет проекта -> Info и **прописываем Privacy**

<img width="1052" height="180" alt="1" src="https://github.com/user-attachments/assets/f440fe39-d412-4006-92d2-41b13f66adc7" />

Готово! Теперь можно использовать Yandex MapKit SDK в проекте.

## Работа с картой

Создадим класс LocationManager, в который импортируем следующее:

```swift
import Foundation
import CoreLocation
import YandexMapsMobile
```

LocationManager будет отвечать за всю (спойлер: почти за всю) логику взаимодействия с картами, объявим в нем саму карту и приватную переменную manager, которая наследуется от класса CLLocationManager, для работы с местоположением пользователя:

```swift
@Observable
final class LocationManager: NSObject {

    // Манипуляции для запуска карт на симуляторе (но есть нюанс, о нем ниже)
    #if targetEnvironment(simulator) && arch(arm64)
	let mapView: YMKMapView = {
		let mapView = YMKMapView(frame: .zero, vulkanPreferred: true)!
		mapView.mapWindow.map.mapType = .map
		return mapView
	}()
	#else
	let mapView = YMKMapView()
	#endif

	@ObservationIgnored private let manager = CLLocationManager()

	override init() {
		super.init()
	}
}
```

Унаследуем класс от протокола CLLocationManagerDelegate (будем делать через Extension), в init() установим делегата объявленного менеджера и запросим разрешение на отслеживание геопозиции. Метод будет максимально простым, так как сейчас нас интересует только получение возможности отслеживания, без излишеств.

```swift
final class LocationManager: NSObject

	override init() {
		super.init()
		setupLocation()
	}
	...
}

private extension LocationManager {

	func setupLocation() {
		manager.delegate = self
		manager.requestAlwaysAuthorization()
	}
}
```

Далее реализуем в классе LocationManager функцию делегата для проверки статуса и начала использования геопозиции:

```swift
extension LocationManager: CLLocationManagerDelegate {

	func locationManager(
		_ manager: CLLocationManager,
		didChangeAuthorization status: CLAuthorizationStatus
	) {
		if status == .authorizedWhenInUse {
			self.manager.startUpdatingLocation()
		}
	}
}
```

Затем создадим переменную, в которую будем записывать последнее местоположение пользователя:

```swift
@ObservationIgnored private var lastUserLocation: CLLocation? = nil
```

Реализуем функцию протокола CLLocationManagerDelegate для того, чтобы слушать изменение местоположения пользователя и записывать это значение в переменную:

```swift
extension LocationManager: CLLocationManagerDelegate {
	...
	func locationManager(
		_ manager: CLLocationManager,
		didUpdateLocations locations: [CLLocation]
	) {
		 lastUserLocation = locations.last
	}
}
```

Начальная подготовка завершена, теперь перейдем к написанию визуальной части приложения.

## Написание UI части

Так как Yandex MapKit работает из коробки только с UIKit и работы с SwiftUI не предусмотрено, нам нужно создать обертку YandexMapView, которая будет наследоваться от протокола UIViewRepresentable

Для этого объявим Enviroment переменную класса LocationManager и реализуем функцию makeUIView(), в которой вернем как View ранее созданную mapView в классе LocationManager

```swift
import SwiftUI
import YandexMapsMobile

struct YandexMapView: UIViewRepresentable {

	@Environment(\.locationManager) var locationManager

	func makeUIView(context: Context) -> YMKMapView {
		return locationManager.mapView
	}

	func updateUIView(_ mapView: YMKMapView, context: Context) {}
}
```

Создадим кастомный EnvironmentKey, чтобы передавать объект через .environment

```swift
import SwiftUI

private struct LocationManagerKey: EnvironmentKey {
    static let defaultValue: LocationManager = LocationManager()
}

extension EnvironmentValues {
    var locationManager: LocationManager {
        get { self[LocationManagerKey.self] }
        set { self[LocationManagerKey.self] = newValue }
    }
}
```

Далее создадим структуру MapView и положим в нее ZStack c YandexMapView. Также объявим экземпляр класса LocationManager. Тут используется Task, по той причине, что нам нужно дождаться, чтобы **lastUserLocation стала != nil**, это происходит не сразу, решать это можно по-разному, я предпочел сделать таким образом:

```swift
import SwiftUI

struct MapView: View {

	@State var locationManager = LocationManager()

	var body: some View {
		ZStack{
			YandexMapView()
				.ignoresSafeArea()
				.environment(\.locationManager, locationManager)
		}
		.onAppear {
			Task {
				await locationManager.currentUserLocation()
			}
		}
	}
}
```

Теперь нужно написать сам метод currentUserLocation для получения текущей локации юзера для этого вернемся в LocationManager. Метод будет выглядеть так:

```swift
func currentUserLocation() async {
    while !Task.isCancelled {
        if lastUserLocation != nil {
            checkLocationAndCenter()
            return
        }
        try? await Task.sleep(nanoseconds: 100_000_000)
    }
}
```

Также создадим вспомогательный метод checkLocationAndCenter для проверки текущей геопозиции пользователя, она будет брать lastUserLocation и передавать в метод centerMapLocation.

```swift
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
```

Нам понадобится и сам метод centerMapLocation. На вход он будет принимать параметр target, в который будем передавать долготу и широту, и параметр animation, который принимает анимацию (дальше будет пояснение, почему анимация нужна не всегда), mapView у нас объявлена в классе, поэтому ее используем как есть.

```swift
func centerMapLocation(target location: YMKPoint?, animation: YMKAnimation? = nil) {
    guard let location else { print("Failed to get user location"); return }
    mapView.mapWindow.map.move(
        with: YMKCameraPosition(target: location, zoom: 18, azimuth: 0, tilt: 0),
        animation: animation
    )
}
```

А теперь вишенка на торте, при инициализации LocationManager нужно установить начальное положение камеры, так как на момент инициализации у нас нет точки отсчета, то возьмем точку отсчета **YMKPoint(latitude: 0, longitude: 0)**. Сделать эту манипцуляцию необходимо для того, чтобы при открытии экрана наша камера корректно зумилась к нужной нам точке и делать это нужно именно без анимации, иначе зум к точке может часто не срабататывать.

```swift
override init() {
    super.init()
    setupLocation()
    centerMapLocation(target: YMKPoint(latitude: 0, longitude: 0))
}
```

Готово, теперь у нас есть View с картой, которую можно встраивать куда необходимо.

## Добавляем иконку местоположения пользователя на карту

Теперь хочется как-то обозначить положение пользователя на карте, чтобы мы могли понимать, где же он все-таки находится, а не видеть просто пустую карту. Для того, чтобы установить иконку пользователя на view с картой, нужно добавить на карту слой с user location icon, добавим следующий приватный метод **addUserLocationLayer** в наш LocationManager

```swift
func addUserLocationLayer() {
    let mapKit = YMKMapKit.sharedInstance()
    let userLocationLayer = mapKit.createUserLocationLayer(with: mapView.mapWindow)

    userLocationLayer.setVisibleWithOn(true)
    userLocationLayer.isHeadingModeActive = true
    userLocationLayer.setObjectListenerWith(self)
}
```

и подпишем его на **YMKUserLocationObjectListener** протокол

```swift
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
```

теперь осталось обновить наш метод currentUserLocation

```swift
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
```

Ура! На карте появилась точка с местоположением пользователя.

<img width="247" height="490" alt="2" src="https://github.com/user-attachments/assets/d823e827-8a1a-4bc0-aa2c-a004baa4b483" />

## Добавляем кастомные точки на карту

Теперь добавим кастомные точки на карту, для этого воспользуемся функцией поиска самой библиотеки Mapkit SDK. Поиск сделаем хардкорный и хардкодный. Сначала поработаем с UI, добавим на экран кнопки поиска отделений и банкоматов, а также кнопку перехода к текущей позиции пользователя. Сделаем общую кнопку с несколькими состояниями:

```swift
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
```

Добавим кнопки на экран с картой, то есть обновим наш MapView.

```swift
struct MapView: View {

	@State var locationManager = LocationManager()

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
```

Теперь добавим сервис для поиска, сделаем 2 опции поиска:

```swift
enum SearchOption: String {
	case department = "отп банк банкомат"
	case atm = "отп банк отделение"
}
```

следом напишем сам сервис для поиска данных наших точек:

```swift
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
```

Ошибки будем просто принтить в консоль, для нашего Demo это сейчас не принципиально. Осталось интегрировать сервис поиска в LocationManager. Все делаем по лайту, без протоколов и т.д. для простоты восприятия:

```swift
@ObservationIgnored private let searchLocationService: SearchLocationService

// иконка для наших кастомных точек
// убедитесь, что иконка добавлена в Assets!
@ObservationIgnored private let placemarkIcon = UIImage(named: "SearchResult")

override init() {
    searchLocationService = SearchLocationService()
    super.init()
    setupLocation()
    setupSearchService()
    centerMapLocation(target: YMKPoint(latitude: 0, longitude: 0))
}
```

Метод для переключения фильтров для поиска и очистки карты от старых точек:

```swift
func toggleFilter(_ filter: SearchOption) {
    searchLocationService.setFilters(option: filter)
    clearMap()
}

func clearMap() {
    mapView.mapWindow.map.mapObjects.clear()
}
```

Также обеспечим в LocationManager обратную связь от SearchLocationService в методе setupSearchService:

```swift
func setupSearchService() {
    mapView.mapWindow.map.addCameraListener(with: searchLocationService)
    searchLocationService.onSearchResult = { [weak self] response in
        self?.addPlaceMarksOnMap(response: response)
    }
}
```

Еще нам понадобится метод для добавления точки на карту

```swift
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
				placemarkIcon,
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
```

Готово! Теперь переключением соотвествующих кнопок на экране мы можем показывать и скрывать на карте результаты поиска.

<img width="247" height="490" alt="3" src="https://github.com/user-attachments/assets/856d5221-368f-487e-b109-ddfe34a63781" />

## Работа со множеством точек (кластеризация)

Чтобы визуально не нагружать карту, можно применить кластеризацию точек, то есть схлопнуть несколько точек под одной иконкой. Для этого точки на карту будем добавлять не как отдельные объекты, а положим их в кластер. Подменим в LocationManager код метода **addPlaceMarksOnMap**. Сейчас я пошел по-простому пути, в целом, добавлять можно точки можно точно также как и в первой версии addPlaceMarksOnMap, только добавлять нужно в кластер, чуть позже вернемся к этой версии.

```swift
...
let collection = mapView.mapWindow.map.mapObjects.addClusterizedPlacemarkCollection(with: self)
...
let placemark = collection.addPlacemark()
placemark.geometry = point
...
// ВАЖНО: нужно не забыть зафорсить рендеринг кластера
collection.clusterPlacemarks(withClusterRadius: 60, minZoom: 15)
```

Итак, обновленный метод addPlaceMarksOnMap сейчас выглядит так:

```swift
func addPlaceMarksOnMap(response: YMKSearchResponse) {
    var points = [YMKPoint]()
    for searchResult in response.collection.children {
        if let point = searchResult.obj?.geometry.first?.point {
            points.append(point)
        }
    }
    let collection = mapView.mapWindow.map.mapObjects.addClusterizedPlacemarkCollection(with: self)
    collection.addPlacemarks(
        with: points,
        image: placemarkIcon,
        style: YMKIconStyle()
    )
    collection.clusterPlacemarks(withClusterRadius: 60, minZoom: 15)
}
```

Дальше нужно подписаться под 2 протокола, первый **YMKClusterTapListener** c методом onClusterTap, где будем обрабатывать тап по кластеру, я сделал просто переход к центру кластера

```swift
extension LocationManager: YMKClusterTapListener {

	func onClusterTap(with cluster: YMKCluster) -> Bool {
		centerMapLocation(target: cluster.appearance.geometry)
		return true
	}
}
```

и второй **YMKClusterListener** - где настроим привязку к YMKClusterTapListener и зададим внешний вид иконки кластера с помощью метода clusterImage

```swift
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
		let sizeDelta: CGFloat = 2.1
		let iconSize = CGSize(
			width: externalRadius * sizeDelta,
			height: externalRadius * sizeDelta
		)
		UIGraphicsBeginImageContext(iconSize)
		let ctx = UIGraphicsGetCurrentContext()!

		ctx.setFillColor(UIColor.green.cgColor)
		ctx.fillEllipse(in: CGRect(
			origin: .zero,
			size: CGSize(
				width: sizeDelta * externalRadius,
				height: sizeDelta * externalRadius
			)
		))

		ctx.setFillColor(UIColor.white.cgColor)
		ctx.fillEllipse(in: CGRect(
			origin: CGPoint(
				x: externalRadius - internalRadius,
				y: externalRadius - internalRadius
			),
			size: CGSize(
				width: sizeDelta * internalRadius,
				height: sizeDelta * internalRadius
			)
		))

		(text as NSString).draw(
			in: CGRect(
				origin: CGPoint(
					x: externalRadius - size.width / sizeDelta,
					y: externalRadius - size.height / sizeDelta
				),
				size: size
			),
			withAttributes: [
				NSAttributedString.Key.font: font,
				NSAttributedString.Key.foregroundColor: UIColor.black
			]
		)
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
```

Эти манипуляции позволили нам получить карту визуально не перегруженную множеством точек.

<img width="247" height="490" alt="4" src="https://github.com/user-attachments/assets/4d8754ad-61e2-4c4f-b6ef-0e03c6f867ff" />

Однако, возникли некоторые проблемы с рендерингом, порой иконка(и) точки перекрывае(ю)т иконку кластера

<img width="247" height="490" alt="5" src="https://github.com/user-attachments/assets/d8d0dfed-381e-434b-a331-c01558a34f6c" />

Решение нашлось (жаль, что не сразу!). **Внимание! Очень важно следить за zIndex** ваших точек, чтобы иконки не перекрывали друг друга, иконка кластера, конечно же, должна иметь значение выше, чем у обычных точек. Подправим метод **onClusterAdded**:

```swift
func onClusterAdded(with cluster: YMKCluster) {
    let iconStyle = YMKIconStyle()
    iconStyle.zIndex = 10
    cluster.appearance.setIconWith(clusterImage(cluster.size), style: iconStyle)
    cluster.addClusterTapListener(with: self)
}
```

Супер! Иконка кластера теперь не перекрывается иконками обычных точек.

## Добавляем пользовательские данные к кастомным точкам

Карта есть, кастомные точки на месте, кластеризация присутствует, а что же это за точки такие, как понять? Добавим к каждой точке пояснительную записку! Для простоты реализации просто выведем информацию о точке из данных самих карт и покажем все это в алерте.

Первым делом добавим модель для нашего алерта:

```swift
struct AlertDataModel: Identifiable, Equatable {
	let id = UUID()
	let title: String
	let message: String
}
```

и **подготовим MapView для показа алерта** – добавим переменную и сам алерт:

```swift
@State private var alert: AlertDataModel?

...

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
```

Теперь научим LocationManager передавать информацию в MapView, для этого вернемся к методу **addPlaceMarksOnMap** и доработаем его:

```swift
func addPlaceMarksOnMap(response: YMKSearchResponse) {
    let collection = mapView.mapWindow.map.mapObjects.addClusterizedPlacemarkCollection(with: self)
    for searchResult in response.collection.children {
        if let point = searchResult.obj?.geometry.first?.point {
            let placemark = collection.addPlacemark()
            // Задание координат точки
            placemark.geometry = point
            // Настройка и добавление иконки
            placemark.setIconWith(placemarkIcon)
            // Установка пользовательских данных для метки
            placemark.userData = searchResult.obj
            // Добавление обработки нажатия
            placemark.addTapListener(with: self)
        }
    }
    collection.clusterPlacemarks(withClusterRadius: 30, minZoom: 15)
}
```

И вот тут я наткнулся на интересную штуку, при зуме появлялись артефакты – несколько перекрывающих друг друга иконок кластеров, решил это таким образом – добавил переменную для запоминания последнего кластера:

```swift
@ObservationIgnored private var clusterCollection: YMKClusterizedPlacemarkCollection? {
    didSet {
        guard let oldValue, oldValue.isValid else { return }
        // очищаем старый кластер, чтобы не было артефактов на карте
        oldValue.clear()
        oldValue.parent.remove(with: oldValue)
    }
}
```

и обновил метод addPlaceMarksOnMap:

```swift
func addPlaceMarksOnMap(response: YMKSearchResponse) {
    clusterCollection = mapView.mapWindow.map.mapObjects.addClusterizedPlacemarkCollection(with: self)
    guard let collection = clusterCollection else { return }
    ...
}
```

Вероятно, есть и другое решение этой проблемы, пошел по быстрому пути.

Теперь нужно обработать нажатие на метки, в этом нам поможет протокол **YMKMapObjectTapListener**

```swift
extension LocationManager: YMKMapObjectTapListener {

	func onMapObjectTap(with mapObject: YMKMapObject, point: YMKPoint) -> Bool {
		guard let geoObject = mapObject.userData as? YMKGeoObject else {
			return true
		}

		// Скейлим иконку кастомной точки
		if let placemark = mapObject as? YMKPlacemarkMapObject {
			let iconStyle = YMKIconStyle()
			iconStyle.anchor = NSValue(cgPoint: CGPoint(x: 0.5, y: 0.5))
			iconStyle.scale = 2.0
			// Выставляем приоритет над обычными иконками
			iconStyle.zIndex = 1
			placemark.setIconWith(placemarkIcon, style: iconStyle)
			// Возвращаем обычный размер иконки точке, выбранной перед этим
			if lastTappedPlacemark != placemark {
				cleanLastTappedPlacemark()
			}
			lastTappedPlacemark = placemark
			// Не забываем снять выделение с ранее выделенного объекта на карте
			mapView.mapWindow.map.deselectGeoObject()
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

	private func cleanLastTappedPlacemark() {
		guard let isValid = lastTappedPlacemark?.isValid, isValid else { return }
		lastTappedPlacemark?.setIconWith(placemarkIcon)
	}

	// MARK: - Private nesting

	private enum GeoObjectType {
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
```

Отлично! Теперь мы знаем гораздо больше о том, что же мы такое нашли на карте!

<img width="247" height="490" alt="6" src="https://github.com/user-attachments/assets/2e7e89ea-0cff-422c-a9cb-d3983f5fc1ef" />
<img width="247" height="490" alt="7" src="https://github.com/user-attachments/assets/ba3b2136-f1cc-4396-81b5-87af6224f979" />

## Делаем карту интерактивной

Yandex MapKit SDK также дает возможность сделать карту более живой. Чтобы сделать карту интерактивной нужно всего лишь добавить слушателей и подписаться на пару протоколов **YMKLayersGeoObjectTapListener** и **YMKMapInputListener**:

```swift
final class LocationManager: NSObject {
    ...
    override init() {
		...
		setupSelectionListeners()
	}

	private func setupSelectionListeners() {
		mapView.mapWindow.map.addTapListener(with: self)
		mapView.mapWindow.map.addInputListener(with: self)
	}
...
}

// MARK: - YMKLayersGeoObjectTapListener

extension LocationManager: YMKLayersGeoObjectTapListener {

	func onObjectTap(with event: YMKGeoObjectTapEvent) -> Bool {
		// не забываем снять выделение с нашей кастомной точки!
		cleanLastTappedPlacemark()
		let event = event
		let metadata = event.geoObject.metadataContainer.getItemOf(YMKGeoObjectSelectionMetadata.self)
		if let selectionMetadata = metadata as? YMKGeoObjectSelectionMetadata {
			mapView.mapWindow.map.selectGeoObject(withSelectionMetaData:selectionMetadata)
			return true
		}
		return false
	}
}

// MARK: - YMKMapInputListener

extension LocationManager: YMKMapInputListener {

	func onMapTap(with map: YMKMap, point: YMKPoint) {
		cleanLastTappedPlacemark()
		mapView.mapWindow.map.deselectGeoObject()
	}
	
	func onMapLongTap(with map: YMKMap, point: YMKPoint) {}
}
```

Готово!

<img width="247" height="490" alt="8" src="https://github.com/user-attachments/assets/f9653892-f441-4b32-ad88-47a08ffe5695" />
<img width="247" height="490" alt="9" src="https://github.com/user-attachments/assets/b167e0b5-fd44-48aa-96d5-6be2ae7bbae4" />
<img width="247" height="490" alt="10" src="https://github.com/user-attachments/assets/b4419ae0-a954-4ecf-b695-7dc7c7edbadb" />

> [!IMPORTANT]
> **Нюанс** (о котором я упомянул в самом начале, в комментарии к запуску карт на симуляторе): **интерактивность всей карты работает только на реальном устройстве**, на симуляторе придется ограничиться интерактивностью ваших кастомных точек.

Любая точка карте становится кликабельной, можно кликнуть на любой ярлык или даже здание. Вся магия интерактивности в одном флаконе! Что дальше делать с этой интерактивностью уже вопрос лишь вашей фантазии.

## Заключение

MapKit SDK Яндекс Карт для iOS штука интересная и крутая, особенно для России. При этом стоит отметить, что документация – это отдельный вид приключения, некоторые компоненты и вовсе не описаны, чтобы понять по ней как что-то сделать приходится долго рыться на сайте, в коде и эксперементировать - однако, это все же сильно лучше, чем дока и сама реализация у Яндекс.Расписания, там просто кошмар, консистентности никакой. Еще стоит отметить, что наглядных и тем более нормально описанных примеров тоже немного. Про видео туториалы и говорить не приходится, лучший туториал дока :), скажете вы и ... не факт! Можно сравнить сколько информации и вариантов видео можно найти про MapKit от Apple и сколько про MapKit SDK от Яндекс. Чуть больше, чем ноль? Возможно, я просто плохо искал.

**Итоги**. Интеграция Яндекс MapKit SDK в SwiftUI вполне выполнимая задача. Однако, с моей точки зрения, ложкой дегтя, конечно, тут является малое количество описанных примеров, проблемы с запуском карт на симуляторе (сильно в эту сторону я не зарубался) и CocoaPods – пора бы уже подумать над переходом на SPM!
