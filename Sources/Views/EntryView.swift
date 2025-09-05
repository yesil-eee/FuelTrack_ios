import SwiftUI
import SwiftData

struct EntryView: View {
    @Environment(\.modelContext) private var context
    @State private var brand: String = UserDefaults.standard.string(forKey: "brand") ?? ""
    @State private var model: String = UserDefaults.standard.string(forKey: "model") ?? ""
    @State private var fuelType: FuelType = {
        let saved = UserDefaults.standard.string(forKey: "fuelType") ?? "DIZEL"
        return FuelType(rawValue: saved.uppercased()) ?? .DIZEL
    }()
    @State private var unitPrice: String = String(UserDefaults.standard.double(forKey: "unitPriceTlPerLt").nonZeroOr(53))
    @State private var liters: String = ""
    @State private var odometer: String = ""
    @State private var fullTank: Bool = false
    @State private var date: Date = Date()

    @State private var showShareSheet = false
    @State private var itemsToShare: [Any] = []

    private var formatter: DateFormatter {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df
    }

    private var vehicleTitle: String {
        if !brand.isEmpty && !model.isEmpty { return "Araç: \(brand) \(model)" }
        if !brand.isEmpty { return "Araç: \(brand)" }
        if !model.isEmpty { return "Araç: \(model)" }
        return "Araç: -"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Araç")) {
                    TextField("Marka", text: $brand)
                        .onChange(of: brand) { UserDefaults.standard.set(brand, forKey: "brand") }
                    TextField("Model", text: $model)
                        .onChange(of: model) { UserDefaults.standard.set(model, forKey: "model") }
                    Text(vehicleTitle).foregroundStyle(.secondary)
                }
                Section(header: Text("Yakıt")) {
                    Picker("Yakıt Tipi", selection: $fuelType) {
                        ForEach(FuelType.allCases) { ft in
                            Text(ft.rawValue.capitalized)
                                .tag(ft)
                        }
                    }
                    .onChange(of: fuelType) { UserDefaults.standard.set(fuelType.rawValue, forKey: "fuelType") }

                    TextField("Birim Fiyat (TL/L)", text: $unitPrice)
                        .keyboardType(.decimalPad)
                        .onChange(of: unitPrice) {
                            if let v = Double(unitPrice) { UserDefaults.standard.set(v, forKey: "unitPriceTlPerLt") }
                        }
                    TextField("Litre", text: $liters).keyboardType(.decimalPad)
                    TextField("Kilometre", text: $odometer).keyboardType(.decimalPad)
                    Toggle("Full Depo", isOn: $fullTank)
                }
                Section(header: Text("Tarih")) {
                    DatePicker("Tarih Seç", selection: $date, displayedComponents: .date)
                    Text("Tarih: \(formatter.string(from: date))")
                }
                Section {
                    Button("Kaydet") { saveEntry() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Kayıt")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exportCsv()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: itemsToShare)
        }
    }

    private func saveEntry() {
        let entry = FuelEntry(
            brand: brand,
            model: model,
            fuelType: fuelType.rawValue,
            date: date,
            unitPriceTlPerLt: Double(unitPrice) ?? 0,
            liters: Double(liters) ?? 0,
            odometerKm: Double(odometer) ?? 0,
            fullTank: fullTank
        )
        do {
            try FuelRepository.insert(entry, context: context)
        } catch {
            print("Insert error: \(error)")
        }
    }

    private func exportCsv() {
        do {
            let all = try FuelRepository.all(context: context)
            let raw = CsvExporter.buildRawCsv(all)
            let analytics = CsvExporter.buildAnalyticsCsv(all)
            let dir = FileManager.default.temporaryDirectory
            let rawUrl = dir.appendingPathComponent("fuel_entries_raw-\(CsvExporter.todayYmd()).csv")
            let analyticsUrl = dir.appendingPathComponent("fuel_entries_analytics-\(CsvExporter.todayYmd()).csv")
            try raw.data(using: .utf8)?.write(to: rawUrl)
            try analytics.data(using: .utf8)?.write(to: analyticsUrl)
            itemsToShare = [rawUrl, analyticsUrl]
            showShareSheet = true
        } catch {
            print("CSV export error: \(error)")
        }
    }
}

private extension Double {
    func nonZeroOr(_ fallback: Double) -> Double { self == 0 ? fallback : self }
}

struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    EntryView()
        .modelContainer(for: FuelEntry.self, inMemory: true)
}
