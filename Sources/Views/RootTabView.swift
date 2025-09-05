import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            StatsView()
                .tabItem {
                    VStack {
                        Image("analytics")
                        Text("Gösterge")
                    }
                }
            EntryView()
                .tabItem {
                    VStack {
                        Image("reg_2")
                        Text("Kayıt")
                    }
                }
            ArchiveView()
                .tabItem {
                    VStack {
                        Image("archive")
                        Text("Arşiv")
                    }
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: FuelEntry.self, inMemory: true)
}
