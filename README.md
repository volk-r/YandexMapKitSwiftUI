# YandexMapKitSwiftUI
SwiftUI Application with Yandex MapKit SDK

## Step-by-step guide

[Внедряем Yandex MapKit SDK в SwiftUI приложение. Пишем Demo проект](https://habr.com/ru/sandbox/275752/)

## Build locally

1. Clone the repository:
    ```sh
    git clone https://github.com/volk-r/YandexMapKitSwiftUI.git
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

<img width="315" height="625" alt="3" src="https://github.com/user-attachments/assets/7314de1f-323f-4f29-a84c-b4c69779e2ba" />
<img width="315" height="625" alt="6" src="https://github.com/user-attachments/assets/d4600fa2-5677-4d5d-a558-b654b2f87313" />
<img width="315" height="625" alt="7" src="https://github.com/user-attachments/assets/d898634b-d802-46a6-a754-bdcef7775428" />
<img width="315" height="625" alt="10" src="https://github.com/user-attachments/assets/64df060c-4336-4cd8-bddf-ae319c41f29f" />
<img width="315" height="625" alt="8" src="https://github.com/user-attachments/assets/47dc5284-c4ed-495e-9def-8250d15f70b7" />
<img width="315" height="625" alt="4" src="https://github.com/user-attachments/assets/fe810691-36ed-44e2-b564-dcf259c97fb2" />

