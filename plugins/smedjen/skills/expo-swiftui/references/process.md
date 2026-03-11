# expo-swiftui — Process Reference

## Expo Modules API for Swift

The Expo Modules API replaces the legacy `RCT_EXPORT_MODULE` / `RCT_EXPORT_METHOD` pattern entirely. Modules are pure Swift classes — no Obj-C bridging header, no `.m` files.

### Minimal module

```swift
import ExpoModulesCore

public class GreeterModule: Module {
  public func definition() -> ModuleDefinition {
    Name("Greeter")

    Function("greet") { (name: String) -> String in
      "Hello, \(name)"
    }

    AsyncFunction("greetAsync") { (name: String, promise: Promise) in
      promise.resolve("Hello async, \(name)")
    }

    Constants {
      ["platform": "iOS", "version": UIDevice.current.systemVersion]
    }
  }
}
```

JS side:
```ts
import { requireNativeModule } from 'expo-modules-core';
const Greeter = requireNativeModule('Greeter');
Greeter.greet('World');           // sync
await Greeter.greetAsync('World'); // async
```

## Creating a Native iOS View

### ExpoView subclass

```swift
import ExpoModulesCore

class ColorBoxView: ExpoView {
  let label = UILabel()

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    label.textAlignment = .center
    addSubview(label)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    label.frame = bounds
  }
}
```

### Register the view in the module

```swift
View(ColorBoxView.self) {
  Prop("text") { (view: ColorBoxView, text: String) in
    view.label.text = text
  }
  Prop("color") { (view: ColorBoxView, hex: String) in
    view.backgroundColor = UIColor(hex: hex)
  }
  Events("onTap")
}
```

## SwiftUI View Integration via UIHostingController

SwiftUI views are not `UIView` subclasses. Bridge them by hosting inside `UIHostingController`:

```swift
class MapView: ExpoView {
  private var hostingController: UIHostingController<MapSwiftUIView>?

  required init(appContext: AppContext? = nil) {
    super.init(appContext: appContext)
    let root = MapSwiftUIView()
    let hc = UIHostingController(rootView: root)
    hc.view.backgroundColor = .clear
    addSubview(hc.view)
    hostingController = hc
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    hostingController?.view.frame = bounds
  }
}
```

To pass data from props into the SwiftUI view, use a shared `ObservableObject` or `@Binding` held on the `ExpoView`:

```swift
class MapViewModel: ObservableObject {
  @Published var region = MKCoordinateRegion()
}

class MapView: ExpoView {
  let viewModel = MapViewModel()

  // In Prop handler:
  // viewModel.region = newRegion
}

struct MapSwiftUIView: View {
  @ObservedObject var model: MapViewModel
  var body: some View {
    Map(coordinateRegion: $model.region)
  }
}
```

## Props and Events

### Supported prop types

`String`, `Int`, `Double`, `Bool`, `[String: Any]`, `[Any]`, `UIColor` (from hex string), `URL`. Custom types need to conform to `Convertible` from `ExpoModulesCore`.

### Firing events

```swift
// In ExpoView subclass:
@EventDispatcher var onSelect: EventDispatcher

// In module Definition():
Events("onSelect")

// Fire it:
onSelect(["id": item.id, "label": item.title])
```

## Lifecycle Management

| Hook | Where | When it fires |
|------|-------|--------------|
| `OnCreate` | Module `Definition()` | Module instantiated |
| `OnDestroy` | Module `Definition()` | Module deallocated |
| `didMoveToWindow()` | `ExpoView` | View added to/removed from window |
| `.onAppear` / `.onDisappear` | SwiftUI view | SwiftUI lifecycle within hosting controller |

For subscriptions (NotificationCenter, Combine publishers), subscribe in `OnCreate` or `didMoveToWindow` and unsubscribe in `OnDestroy` or `willMove(toSuperview: nil)`.

## Native Navigation Integration

Access the presenting view controller:

```swift
AsyncFunction("presentSheet") { (promise: Promise) in
  DispatchQueue.main.async {
    guard let vc = self.appContext?.utilities?.currentViewController() else {
      promise.reject("ERR_NO_VC", "No view controller available")
      return
    }
    let sheet = MySheetViewController()
    vc.present(sheet, animated: true)
    promise.resolve(nil)
  }
}
```

Always dispatch UI work to `DispatchQueue.main`.

## Accessing iOS APIs

Call iOS SDK APIs directly from Swift. No special setup needed unless the API requires permissions.

### Permission flow

1. Write a config plugin that adds the `NSUsageDescription` key to `Info.plist`.
2. Call `AVCaptureDevice.requestAccess(for:)` or `CLLocationManager().requestWhenInUseAuthorization()` from within the module.
3. Never edit `ios/*/Info.plist` directly — `expo prebuild` regenerates it.

### Config plugin for plist key

```js
// plugins/withCameraPermission.js
const { withInfoPlist } = require('@expo/config-plugins');

module.exports = (config) =>
  withInfoPlist(config, (mod) => {
    mod.modResults.NSCameraUsageDescription = 'This app uses the camera.';
    return mod;
  });
```

Add to `app.json` plugins array:
```json
"plugins": ["./plugins/withCameraPermission"]
```

## Testing Native Modules

- Unit test pure Swift logic separately from the Expo module wrapper.
- Integration test with a development build — Expo Go does not load custom native modules.
- Use `XCTestCase` for synchronous functions; for async, use `expectation(description:)` or Swift Concurrency test support.
- Test prop updates by calling the prop handler directly in unit tests.

## Debugging

- **Xcode console**: native logs (`print`, `os_log`) appear in the Xcode console, not Metro.
- **Breakpoints**: attach Xcode to the running app process to hit Swift breakpoints.
- **Crash symbolication**: run `xcrun atos` against the crash log with the dSYM to resolve addresses.
- **Module not found**: verify `Name("YourModule")` matches exactly the string in `requireNativeModule("YourModule")`.
- **Props not applying**: confirm the `Prop` closure signature matches the view class and that the prop name matches what JS passes.

## Anti-Patterns

**Running UI work off the main thread**: SwiftUI and UIKit updates must be on `DispatchQueue.main`. Expo module functions run on a background queue by default.

**Retaining `appContext` in the view**: `appContext` may be nil after the module is destroyed. Check for nil before use; don't store strong references.

**Editing Info.plist manually**: prebuild overwrites it. All plist changes must go through config plugins.

**Using UIKit directly when SwiftUI is preferred**: for complex iOS-native UI, SwiftUI + `UIHostingController` is maintainable. UIKit-only is fine for simple views.

**Tight coupling between SwiftUI state and Expo props**: route all prop updates through the `ExpoView` subclass, then push to the SwiftUI layer via `ObservableObject`. Direct SwiftUI `@State` manipulation from outside the view hierarchy is fragile.
