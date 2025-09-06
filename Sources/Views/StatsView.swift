import SwiftUI
import SwiftData
import Charts

struct StatsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \FuelEntry.date, order: .reverse, animation: .default) private var entries: [FuelEntry]

    // Gauge thresholds similar to Android
    private let good: Float = 5.0
    private let ok: Float = 6.0
    private let warn: Float = 6.5

    var body: some View {
        NavigationStack {
            ScrollView {
                if entries.count < 2 {
                    ContentUnavailableView(L.t("Yeterli veri yok"), systemImage: "gauge.with.dots.needle.33percent") {
                        Text(L.t("En az 2 kayıt ekleyin."))
                    }
                    .padding()
                } else {
                    VStack(spacing: 24) {
                        // Banner image (from Android drawable/banner.png)
                        Image("banner")
                            .resizable()
                            .scaledToFit()
                            .cornerRadius(12)
                            .shadow(radius: 3)

                        // Latest valid pair for current TL/km gauge
                        if let pair = preferredPair(entries) {
                            let newer = pair.0
                            let older = pair.1
                            let kmCurrent = max((newer.odometerKm - older.odometerKm), 1)
                            let ltCurrent = max(newer.liters, 0.01)
                            let ltPer100Current = Float((ltCurrent / kmCurrent) * 100)
                            GaugeCard(
                                title: L.t("TL/km"),
                                unit: L.t("TL/km"),
                                value: Float(costPerKm(ltPer100: Double(ltPer100Current), pricePerLiter: newer.unitPriceTlPerLt)),
                                min: 0,
                                max: max(Float(costPerKm(ltPer100: Double(warn), pricePerLiter: newer.unitPriceTlPerLt)) * 2, 5),
                                segments: [
                                    .init(from: 0, to: Float(costPerKm(ltPer100: Double(good), pricePerLiter: newer.unitPriceTlPerLt)), color: Color(hex: 0x0B7A6B)),
                                    .init(from: Float(costPerKm(ltPer100: Double(good), pricePerLiter: newer.unitPriceTlPerLt)), to: Float(costPerKm(ltPer100: Double(ok), pricePerLiter: newer.unitPriceTlPerLt)), color: Color(hex: 0xF9A825)),
                                    .init(from: Float(costPerKm(ltPer100: Double(ok), pricePerLiter: newer.unitPriceTlPerLt)), to: Float(costPerKm(ltPer100: Double(warn), pricePerLiter: newer.unitPriceTlPerLt)), color: Color(hex: 0xEF6C00)),
                                    .init(from: Float(costPerKm(ltPer100: Double(warn), pricePerLiter: newer.unitPriceTlPerLt)), to: max(Float(costPerKm(ltPer100: Double(warn), pricePerLiter: newer.unitPriceTlPerLt)) * 2, 5), color: Color(hex: 0xC62828))
                                ]
                            )
                        }

                        // Average lt/100km and km/lt over valid intervals
                        let ltPer100Avg = averageLtPer100(entries: entries)
                        GaugeCard(
                            title: L.t("lt/100km"),
                            unit: L.t("lt/100km"),
                            value: Float(ltPer100Avg),
                            min: 0, max: 10,
                            segments: [
                                .init(from: 0, to: good, color: Color(hex: 0x0B7A6B)),
                                .init(from: good, to: ok, color: Color(hex: 0xF9A825)),
                                .init(from: ok, to: warn, color: Color(hex: 0xEF6C00)),
                                .init(from: warn, to: 10, color: Color(hex: 0xC62828))
                            ]
                        )

                        let kmPerLt = (ltPer100Avg > 0) ? (100.0 / ltPer100Avg) : 0
                        GaugeCard(
                            title: L.t("km/lt"),
                            unit: L.t("km/lt"),
                            value: Float(kmPerLt),
                            min: 0, max: 30,
                            segments: kmPerLtSegments(good: good, ok: ok, warn: warn)
                        )

                        MonthlyChart(entries: entries)
                    }
                    .padding()
                }
            }
            .navigationTitle(L.t("tab_dashboard"))
        }
    }

    private func preferredPair(_ list: [FuelEntry]) -> (FuelEntry, FuelEntry)? {
        let sorted = list.sorted(by: { $0.date > $1.date })
        for i in 0..<(sorted.count - 1) {
            let newer = sorted[i]
            let older = sorted[i + 1]
            if newer.fullTank && older.fullTank { return (newer, older) }
        }
        guard sorted.count >= 2 else { return nil }
        return (sorted[0], sorted[1])
    }

    private func averageLtPer100(entries: [FuelEntry]) -> Double {
        let sorted = entries.sorted(by: { $0.date > $1.date })
        var values: [Double] = []
        for i in 0..<(sorted.count - 1) {
            let n = sorted[i]
            let o = sorted[i + 1]
            guard n.odometerKm > o.odometerKm else { continue }
            let km = n.odometerKm - o.odometerKm
            guard km > 0 else { continue }
            if n.fullTank && o.fullTank {
                values.append((n.liters / km) * 100.0)
            }
        }
        if values.isEmpty {
            // Fallback to most recent interval
            if sorted.count >= 2 {
                let n = sorted[0], o = sorted[1]
                let km = max(n.odometerKm - o.odometerKm, 1)
                return (n.liters / km) * 100.0
            }
            return 0
        }
        return values.reduce(0, +) / Double(values.count)
    }

    private func kmPerLtSegments(good: Float, ok: Float, warn: Float) -> [FuelGaugeView.Segment] {
        let goodMin = 100 / good
        let okMin = 100 / ok
        let warnMin = 100 / warn
        return [
            .init(from: 0, to: warnMin, color: Color(hex: 0xC62828)),
            .init(from: warnMin, to: okMin, color: Color(hex: 0xEF6C00)),
            .init(from: okMin, to: goodMin, color: Color(hex: 0xF9A825)),
            .init(from: goodMin, to: 30, color: Color(hex: 0x0B7A6B)),
        ]
    }

    private func costPerKm(ltPer100: Double, pricePerLiter: Double) -> Double {
        (ltPer100 * pricePerLiter) / 100.0
    }
}

private struct GaugeCard: View {
    let title: String
    let unit: String
    let value: Float
    let min: Float
    let max: Float
    let segments: [FuelGaugeView.Segment]

    var body: some View {
        VStack(alignment: .leading) {
            Text(title).font(.headline)
            FuelGaugeView(minValue: min, maxValue: max, value: value, unitLabel: unit, segments: segments)
                .frame(height: 220)
                .padding(.top, 4)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct MonthlyChart: View {
    let entries: [FuelEntry]

    struct Point: Identifiable { let id = UUID(); let month: String; let cost: Double }

    var points: [Point] {
        let sorted = entries.sorted(by: { $0.date > $1.date })
        var raw: [Point] = []
        let df = DateFormatter(); df.dateFormat = "yyyy-MM"
        for i in 0..<(sorted.count - 1) {
            let n = sorted[i]; let o = sorted[i + 1]
            guard n.fullTank && o.fullTank else { continue }
            guard n.odometerKm > o.odometerKm else { continue }
            let km = n.odometerKm - o.odometerKm
            guard km > 0 else { continue }
            let ltPer100 = (n.liters / km) * 100
            let costPerKm = (ltPer100 * n.unitPriceTlPerLt) / 100
            raw.append(.init(month: df.string(from: n.date), cost: costPerKm))
        }
        if raw.isEmpty {
            for i in 0..<(sorted.count - 1) {
                let n = sorted[i]; let o = sorted[i + 1]
                guard n.odometerKm > o.odometerKm else { continue }
                let km = n.odometerKm - o.odometerKm
                guard km > 0 else { continue }
                let ltPer100 = (n.liters / km) * 100
                let costPerKm = (ltPer100 * n.unitPriceTlPerLt) / 100
                raw.append(.init(month: df.string(from: n.date), cost: costPerKm))
            }
        }
        let grouped = Dictionary(grouping: raw, by: { $0.month }).mapValues { arr in
            arr.map { $0.cost }.reduce(0, +) / Double(arr.count)
        }
        return grouped.keys.sorted().map { .init(month: $0, cost: grouped[$0] ?? 0) }
    }

    var body: some View {
        VStack(alignment: .leading) {
            Text("Aylık TL/km").font(.headline)
            Chart(points) { p in
                BarMark(
                    x: .value("Ay", p.month),
                    y: .value("TL/km", p.cost)
                )
                .foregroundStyle(colorForCost(p.cost))
            }
            .frame(height: 240)
        }
        .padding()
        .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func colorForCost(_ cost: Double) -> Color {
        switch cost {
        case ..<0: return Color(hex: 0x0B7A6B)
        case 0..<2.5:
            let t = cost / 2.5
            return Color(hex: 0x0B7A6B).lerp(to: Color(hex: 0x2196F3), t: t)
        case 2.5:
            return Color(hex: 0x2196F3)
        case 2.5..<5:
            let t = (cost - 2.5) / 2.5
            return Color(hex: 0x2196F3).lerp(to: Color(hex: 0xC62828), t: t)
        default:
            return Color(hex: 0xC62828)
        }
    }
}

private extension Color {
    init(hex: Int) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255.0,
            green: Double((hex >> 8) & 0xFF) / 255.0,
            blue: Double(hex & 0xFF) / 255.0,
            opacity: 1
        )
    }
    func lerp(to other: Color, t: Double) -> Color {
        let t = max(0, min(1, t))
        let c1 = UIColor(self); let c2 = UIColor(other)
        var r1: CGFloat = 0, g1: CGFloat = 0, b1: CGFloat = 0, a1: CGFloat = 0
        var r2: CGFloat = 0, g2: CGFloat = 0, b2: CGFloat = 0, a2: CGFloat = 0
        c1.getRed(&r1, green: &g1, blue: &b1, alpha: &a1)
        c2.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        return Color(red: Double(r1 + (r2 - r1) * t), green: Double(g1 + (g2 - g1) * t), blue: Double(b1 + (b2 - b1) * t), opacity: Double(a1 + (a2 - a1) * t))
    }
}

#Preview {
    StatsView()
        .modelContainer(for: FuelEntry.self, inMemory: true)
}
