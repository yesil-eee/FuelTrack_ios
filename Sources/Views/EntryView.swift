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

    @State private var showSavedAlert = false

    private var vehicleTitle: String {
        let prefix = L.t("vehicle_prefix")
        let dash = L.t("dash")
        if !brand.isEmpty && !model.isEmpty { return "\(prefix): \(brand) \(model)" }
        if !brand.isEmpty { return "\(prefix): \(brand)" }
        if !model.isEmpty { return "\(prefix): \(model)" }
        return "\(prefix): \(dash)"
    }

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text(L.t("section_vehicle"))) {
                    TextField(L.t("Marka"), text: $brand)
                        .onChange(of: brand) { UserDefaults.standard.set(brand, forKey: "brand") }
                    TextField(L.t("Model"), text: $model)
                        .onChange(of: model) { UserDefaults.standard.set(model, forKey: "model") }
                    Text(vehicleTitle).foregroundStyle(.secondary)
                }
                Section(header: Text(L.t("section_fuel"))) {
                    Picker(L.t("Yakıt Tipi"), selection: $fuelType) {
                        ForEach(FuelType.allCases) { ft in
                            Text(ft.rawValue.capitalized)
                                .tag(ft)
                        }
                    }
                    .onChange(of: fuelType) { UserDefaults.standard.set(fuelType.rawValue, forKey: "fuelType") }

                    TextField(L.t("Birim Fiyat (TL/L)"), text: $unitPrice)
                        .keyboardType(.decimalPad)
                        .onChange(of: unitPrice) {
                            if let v = Double(unitPrice) { UserDefaults.standard.set(v, forKey: "unitPriceTlPerLt") }
                        }
                    TextField(L.t("Litre"), text: $liters).keyboardType(.decimalPad)
                    TextField(L.t("Kilometre"), text: $odometer).keyboardType(.decimalPad)
                    Toggle(L.t("Full Depo"), isOn: $fullTank)
                }
                Section(header: Text(L.t("section_date"))) {
                    DatePicker(L.t("Tarih Seç"), selection: $date, displayedComponents: .date)
                    Text(String(format: L.t("Tarih: %@"), formatter.string(from: date)))
                }
                Section {
                    Button(L.t("btn_save")) { saveEntry() }
                        .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle(L.t("tab_entry"))
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        exportCsv()
                    } label: {
                        Image(systemName: "square.and.arrow.up").accessibilityLabel(L.t("share"))
                    }
                }
            }
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(activityItems: itemsToShare)
        }
        .alert(L.t("saved_title"), isPresented: $showSavedAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(L.t("saved_msg"))
        }
    }

    private func saveEntry() {
        guard let price = Double(unitPrice), let litersVal = Double(liters), let odometerVal = Double(odometer) else { return }
        let entry = FuelEntry(
            brand: brand,
            model: model,
            fuelType: fuelType.rawValue,
            date: date,
            unitPriceTlPerLt: price,
            liters: litersVal,
            odometerKm: odometerVal,
            fullTank: fullTank
        )
        do {
            try FuelRepository.insert(entry, context: context)
            clearInputs()
            showSavedAlert = true
        } catch {
            print("Save error: \(error)")
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
