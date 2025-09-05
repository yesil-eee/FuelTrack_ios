# FuelTrack iOS (SwiftUI + SwiftData)

This is the iOS implementation plan and starter code for the existing Android app at `c:/yesileee/fueltrack/`.

The iOS target mirrors the Android features:
- Entry tab: create fuel entries with date, unit price (TL/L), liters, odometer, fuel type, full tank.
- Archive tab: list recent entries and delete.
- Stats tab: gauges for lt/100km, km/lt, TL/km and a monthly TL/km bar chart.
- CSV export: raw and analytics CSV.

## Prerequisites (build/run)
- macOS (Sonoma or newer recommended)
- Xcode 15 or newer
- iOS 17 SDK (for SwiftData and Swift Charts). If you need iOS 16 support, we can switch to Core Data and manual charts.

You are on Windows now, so you won’t be able to build/run here. But you can view and edit the source. Build on a Mac following the steps below.

## Build without owning a Mac (CI on GitHub)
We added GitHub Actions + XcodeGen so you can verify the project builds on GitHub’s macOS runners:

1) Create a new GitHub repository (e.g., `yesileee/FuelTrack_ios`). Leave it empty (no README).
2) Locally push this folder to that remote (commands below).
3) The workflow at `.github/workflows/ios-build.yml` will generate the Xcode project and build for the iOS Simulator.

Push commands (from the `FuelTrack_ios/` directory):
```
git init
git add .
git commit -m "Init iOS (SwiftUI+SwiftData) with XcodeGen and CI"
git branch -M main
git remote add origin https://github.com/yesileee/FuelTrack_ios.git
git push -u origin main
```

Artifacts will be uploaded to the Actions run page. You can also inspect logs to ensure it compiles.

## How to open/build on macOS
1. Copy or open this folder `FuelTrack_ios/` on your Mac.
2. Create an Xcode project (App, SwiftUI, Swift, include SwiftData) named `FuelTrack` and choose this folder as the location.
   - When Xcode creates default files, replace them with the files inside `FuelTrack_ios/` (or add these files to the project).
   - Make sure `Bundle Identifier` is unique and iOS Deployment Target is 17.0+ (or adjust files for lower targets).
3. Add the files under `Sources/` into the project (use “Add Files to ‘FuelTrack’…” in Xcode):
   - `FuelTrackApp.swift`
   - `Models/FuelEntry.swift`
   - `Services/FuelRepository.swift`
   - `Views/EntryView.swift`
   - `Views/ArchiveView.swift`
   - `Views/StatsView.swift`
   - `Views/FuelGaugeView.swift`
   - `Utils/CsvExporter.swift`
4. Run on Simulator or a device.

## Data model mapping
Android Room entity `FuelEntry` -> SwiftData `@Model FuelEntry` with fields:
- id (auto)
- brand, model, fuelType (String)
- dateUtcMillis (Date)
- unitPriceTlPerLt (Double)
- liters (Double)
- odometerKm (Double)
- fullTank (Bool)

DAO methods are mirrored in `FuelRepository` using SwiftData queries.

## Notes
- Custom gauge view is implemented with SwiftUI Canvas drawing, similar color/segment logic to Android `FuelGaugeView`.
- Monthly TL/km chart uses Swift Charts.
- CSV export returns text; use `ShareLink` or `UIDocumentPicker` to save from the Entry view’s toolbar.

## Localization (TR + EN)
- Localization files are under `Sources/Resources/Localization/` (`tr.lproj`, `en.lproj`).
- To fully localize UI strings, replace hard-coded text in SwiftUI with `NSLocalizedString` keys and add them to `Localizable.strings`.

## App Icon
- Place a 1024x1024 PNG named `Icon-1024.png` into `Sources/Resources/Assets.xcassets/AppIcon.appiconset/`.
- CI will auto-generate required sizes via `sips` on macOS runners.

If you prefer a generated Xcode project, we can add XcodeGen/Tuist configs so you can generate the `.xcodeproj` on macOS.
