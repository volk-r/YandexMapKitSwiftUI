# YandexMapKitSwiftUI
Yandex MapKit SDK SwiftUI Demo application

## Build locally

1. Clone the repository:
    ```sh
    git clone https://github.com/yandex/mapkit-ios-demo.git
    ```

2. Execute the following command in your project's directory to install dependencies:
    ```sh
    pod install
    ```

3. MapKit SDK demo application require __API key__. You can get a free MapKit __API key__ in the [Get the MapKit API Key](https://yandex.ru/dev/mapkit/doc/en/ios/generated/getting_started#key) documentation.


4. Open the [`AppDelegate.swift`](YandexMapKitSwiftUI/AppDelegate.swift) and edit the `MAPKIT_API_KEY` constant declaration, setting its value with your __API key__ in place of the `YOUR_API_KEY` placeholder:

    ```swift
    let MAPKIT_API_KEY = "YOUR_API_KEY"
    ```

    You can as well store this __API key__ in your project's build settings and `Info.plist` file.

5. Build and run in Xcode.

## Sample overview
