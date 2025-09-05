import SwiftUI
import SwiftData

@main
struct FuelTrackApp: App {
    var body: some Scene {
        WindowGroup {
            RootTabView()
        }
        .modelContainer(for: FuelEntry.self)
    }
}
