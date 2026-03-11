# expo-jetpack-compose — Process Reference

## Expo Modules API for Kotlin

The Expo Modules API replaces the legacy `ReactPackage` / `@ReactMethod` pattern. Modules are pure Kotlin classes — no Java, no manual package registration.

### Minimal module

```kotlin
import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition

class GreeterModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("Greeter")

    Function("greet") { name: String ->
      "Hello, $name"
    }

    AsyncFunction("greetAsync") { name: String ->
      "Hello async, $name"
    }

    Constants(
      "platform" to "Android",
      "version" to android.os.Build.VERSION.RELEASE
    )
  }
}
```

JS side:
```ts
import { requireNativeModule } from 'expo-modules-core';
const Greeter = requireNativeModule('Greeter');
Greeter.greet('World');
await Greeter.greetAsync('World');
```

## Creating a Native Android View with Compose

### ExpoView subclass

```kotlin
import android.content.Context
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.*
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import expo.modules.kotlin.AppContext
import expo.modules.kotlin.views.ExpoView

class ColorBoxView(context: Context, appContext: AppContext) : ExpoView(context, appContext) {
  var text: String = ""
    set(value) { field = value; render() }

  private val composeView = ComposeView(context).also { cv ->
    cv.setViewCompositionStrategy(ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed)
    addView(cv, LayoutParams(LayoutParams.MATCH_PARENT, LayoutParams.MATCH_PARENT))
  }

  init { render() }

  private fun render() {
    composeView.setContent {
      MaterialTheme {
        Text(text = text)
      }
    }
  }
}
```

### Register the view in the module

```kotlin
View(ColorBoxView::class) {
  Prop("text") { view: ColorBoxView, text: String ->
    view.text = text
  }
  Events("onTap")
}
```

## Gradle Configuration

Jetpack Compose requires the Kotlin compiler extension plugin. In the module's `android/build.gradle`:

```groovy
android {
  buildFeatures {
    compose true
  }
  composeOptions {
    kotlinCompilerExtensionVersion '1.5.11' // must match Kotlin version
  }
}

dependencies {
  def composeBom = platform('androidx.compose:compose-bom:2024.05.00')
  implementation composeBom
  implementation 'androidx.compose.material3:material3'
  implementation 'androidx.compose.ui:ui'
  implementation 'androidx.compose.ui:ui-tooling-preview'
  debugImplementation 'androidx.compose.ui:ui-tooling'
}
```

The Kotlin compiler extension version must be compatible with the Kotlin version used in the project. Check the [Compose to Kotlin compatibility map](https://developer.android.com/jetpack/androidx/releases/compose-kotlin).

In managed workflow, use a config plugin to apply these Gradle changes — never edit `android/` directly.

## Props and Events

### Supported prop types

`String`, `Int`, `Double`, `Boolean`, `Map<String, Any>`, `List<Any>`. Custom types must implement `expo.modules.kotlin.types.Convertible`.

### Firing events

```kotlin
// In ExpoView subclass:
val onSelect by EventDispatcher()

// In module Definition():
Events("onSelect")

// Fire it (from any method on the view):
onSelect(mapOf("id" to item.id, "label" to item.title))
```

Events must be fired on the main thread. Wrap background calls:

```kotlin
mainQueue.launch { onSelect(mapOf("result" to value)) }
```

## Lifecycle Management

| Hook | Where | When it fires |
|------|-------|--------------|
| `OnCreate` | Module `definition()` | Module instantiated |
| `OnDestroy` | Module `definition()` | Module garbage collected |
| `onAttachedToWindow()` | `ExpoView` | View attached to window |
| `onDetachedFromWindow()` | `ExpoView` | View detached |
| `LaunchedEffect` | Composable | Compose side effects on key change |
| `DisposableEffect` | Composable | Cleanup on key change or composition exit |

For coroutines in the module, use the `moduleCoroutineScope` provided by the module context.

## Android-Specific APIs

Call Android SDK APIs directly. For APIs requiring permissions, the flow is:

1. Declare the permission in `AndroidManifest.xml` via a config plugin.
2. Request the permission at runtime using `ActivityCompat.requestPermissions` or the Jetpack `registerForActivityResult` API.
3. Never edit `android/app/src/main/AndroidManifest.xml` directly — config plugins manage it.

### Config plugin for manifest permissions

```js
// plugins/withCameraPermission.js
const { withAndroidManifest } = require('@expo/config-plugins');

module.exports = (config) =>
  withAndroidManifest(config, (mod) => {
    const manifest = mod.modResults.manifest;
    if (!manifest['uses-permission']) manifest['uses-permission'] = [];
    manifest['uses-permission'].push({
      $: { 'android:name': 'android.permission.CAMERA' }
    });
    return mod;
  });
```

## Testing Native Modules

- Unit test pure Kotlin logic separately from the Expo module wrapper using JUnit.
- Integration test with a development build — Expo Go does not load custom native modules.
- For Compose UI, use `ComposeTestRule` from `androidx.compose.ui:ui-test-junit4`.
- Test prop updates by calling the setter directly in unit tests.

```kotlin
@get:Rule val composeTestRule = createComposeRule()

@Test
fun rendersLabel() {
  composeTestRule.setContent { MyComposable(label = "Hello") }
  composeTestRule.onNodeWithText("Hello").assertIsDisplayed()
}
```

## Debugging

- **Logcat**: Kotlin `Log.d("MyModule", "message")` and `println()` output to Logcat, not Metro.
- **Android Studio debugger**: attach to the running process to hit Kotlin breakpoints.
- **Layout Inspector**: inspect the Compose node tree in Android Studio for layout issues.
- **Module not found**: verify `Name("YourModule")` matches exactly the string in `requireNativeModule("YourModule")`.
- **Props not applying**: confirm the `Prop` closure types match the view property and that names match what JS passes.
- **Compose not rendering**: check that `setViewCompositionStrategy` is set — without it, the `ComposeView` may dispose prematurely.

## Anti-Patterns

**Running UI work off the main thread**: Compose and all Android UI updates must run on the main thread. Module functions run on a background thread by default. Wrap UI calls with `Handler(Looper.getMainLooper()).post {}` or `mainQueue.launch {}`.

**Calling setContent on every prop change in a tight loop**: `setContent {}` triggers full recomposition. Prefer mutable state holders (`mutableStateOf`) inside the composable so Compose can diff and recompose only affected nodes.

**Editing android/ files manually**: `expo prebuild` regenerates `AndroidManifest.xml`, `build.gradle`, and `settings.gradle`. All modifications must go through config plugins.

**Keeping a strong reference to Context beyond the view lifetime**: leads to memory leaks. Use `WeakReference<Context>` if you must hold context outside the view lifecycle.

**Missing Compose BOM**: manually specifying Compose artifact versions without the BOM leads to version conflicts across `material3`, `ui`, and `foundation`. Always use the BOM for consistency.
