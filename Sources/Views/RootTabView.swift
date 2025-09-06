import SwiftUI
import SwiftData

struct RootTabView: View {
    var body: some View {
        TabView {
            StatsView()
                .tabItem {
                    VStack {
                        Image("analytics").renderingMode(.original)
                        Text(L.t("tab_dashboard"))
                    }
                }
            EntryView()
                .tabItem {
                    VStack {
                        Image("reg_2").renderingMode(.original)
                        Text(L.t("tab_entry"))
                    }
                }
            ArchiveView()
                .tabItem {
                    VStack {
                        Image("archive").renderingMode(.original)
                        Text(L.t("tab_archive"))
                    }
                }
        }
    }
}

#Preview {
    RootTabView()
        .modelContainer(for: FuelEntry.self, inMemory: true)
}
