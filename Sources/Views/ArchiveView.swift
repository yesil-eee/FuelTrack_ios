import SwiftUI
import SwiftData

struct ArchiveView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FuelEntry.date, order: .reverse, animation: .default) private var entries: [FuelEntry]

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView("Kayıt Yok", systemImage: "tray") {
                        Text("Eklenen son 10 kayıt burada görünecek.")
                    }
                } else {
                    List {
                        ForEach(entries.prefix(10)) { e in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(e.brand).bold()
                                    Text(e.model).foregroundStyle(.secondary)
                                    Spacer()
                                    Text(dateFormatter.string(from: e.date)).foregroundStyle(.secondary)
                                }
                                HStack(spacing: 16) {
                                    Label(String(format: "%.2f TL/L", e.unitPriceTlPerLt), systemImage: "turkishlirasign")
                                    Label(String(format: "%.2f L", e.liters), systemImage: "fuelpump")
                                    Label(String(format: "%.0f km", e.odometerKm), systemImage: "speedometer")
                                    if e.fullTank { Label("Full", systemImage: "gauge") }
                                }
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            }
                        }
                        .onDelete(perform: delete)
                    }
                }
            }
            .navigationTitle("Arşiv")
        }
    }

    private func delete(at offsets: IndexSet) {
        for index in offsets {
            guard index < entries.count else { continue }
            let entry = entries[index]
            do {
                try FuelRepository.remove(entry, context: context)
            } catch { print("Delete error: \(error)") }
        }
    }
}

private let dateFormatter: DateFormatter = {
    let df = DateFormatter()
    df.dateFormat = "dd.MM.yyyy"
    return df
}()

#Preview {
    ArchiveView()
        .modelContainer(for: FuelEntry.self, inMemory: true)
}
