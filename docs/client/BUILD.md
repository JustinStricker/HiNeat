# Build Guide

## Prerequisites

- JDK 21 (Temurin recommended)
- Android Studio / IntelliJ IDEA
- Xcode (for iOS builds)
- Node.js (for web builds)

## Android

```shell
./gradlew :app:composeApp:assembleDebug
```

Install the APK on device/emulator via `adb install`.

## Desktop (JVM)

```shell
./gradlew :app:composeApp:run
```

Build distributable packages:

| Format | Command |
|--------|---------|
| DMG (macOS) | `./gradlew :app:composeApp:packageDmg` |
| MSI (Windows) | `./gradlew :app:composeApp:packageMsi` |
| DEB (Linux) | `./gradlew :app:composeApp:packageDeb` |

## Web (WasmJS)

Development server:

```shell
./gradlew :app:composeApp:wasmJsBrowserDevelopmentRun
```

Production build:

```shell
./gradlew :app:composeApp:wasmJsBrowserDistribution
```

Output: `app/composeApp/build/dist/wasmJs/productionExecutable/`

## iOS

Open `app/iosApp/` in Xcode, select a simulator or device, and run.

Or build the framework:

```shell
./gradlew :app:composeApp:iosSimulatorArm64MainKotlinNativeCompile
```

## Server

```shell
./gradlew :app:server:run
```

The server starts on port 8080 by default. Override with `SERVER_PORT` env var.

## Common Issues

- **Room KSP processing fails**: Clean build — `./gradlew clean`
- **iOS build fails**: Ensure Xcode is installed and run `pod install` if needed
- **Web build slow**: Use `--no-daemon` flag or increase JVM heap in `gradle.properties`
