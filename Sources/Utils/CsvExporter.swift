import Foundation

enum CsvExporter {
    static func todayYmd() -> String {
        let df = DateFormatter()
        df.dateFormat = "yyyyMMdd"
        return df.string(from: Date())
    }

    static func buildRawCsv(_ list: [FuelEntry]) -> String {
        let dfIso = DateFormatter(); dfIso.dateFormat = "yyyy-MM-dd HH:mm:ss"
        var rows: [String] = []
        rows.append("id,brand,model,fuelType,dateIso,unitPriceTlPerLt,liters,odometerKm,fullTank,totalCostTl")
        for e in list.sorted(by: { $0.date < $1.date }) {
            let dateIso = dfIso.string(from: e.date)
            let totalCost = e.unitPriceTlPerLt * e.liters
            let cols: [String] = [
                e.id.uuidString,
                csvEscape(e.brand),
                csvEscape(e.model),
                e.fuelType,
                dateIso,
                formatNumber(e.unitPriceTlPerLt),
                formatNumber(e.liters),
                formatNumber(e.odometerKm),
                String(e.fullTank),
                formatNumber(totalCost)
            ]
            rows.append(cols.joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    static func buildAnalyticsCsv(_ list: [FuelEntry]) -> String {
        let dfIso = DateFormatter(); dfIso.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let dfMonth = DateFormatter(); dfMonth.dateFormat = "yyyy-MM"
        let ordered = list.sorted(by: { $0.date < $1.date })
        var rows: [String] = []
        rows.append("id,brand,model,fuelType,dateIso,unitPriceTlPerLt,liters,odometerKm,fullTank,deltaKm,ltPer100,costPerKmTl,month")
        var prev: FuelEntry? = nil
        for e in ordered {
            let dateIso = dfIso.string(from: e.date)
            let month = dfMonth.string(from: e.date)
            var deltaKm: Double? = nil
            var ltPer100: Double? = nil
            var costPerKm: Double? = nil
            if let p = prev {
                let d = e.odometerKm - p.odometerKm
                if d > 0 {
                    deltaKm = d
                    if e.fullTank {
                        ltPer100 = (e.liters / d) * 100.0
                        costPerKm = (e.unitPriceTlPerLt * e.liters) / d
                    }
                }
            }
            let cols: [String] = [
                e.id.uuidString,
                csvEscape(e.brand),
                csvEscape(e.model),
                e.fuelType,
                dateIso,
                formatNumber(e.unitPriceTlPerLt),
                formatNumber(e.liters),
                formatNumber(e.odometerKm),
                String(e.fullTank),
                deltaKm.map(formatNumber) ?? "",
                ltPer100.map(formatNumber) ?? "",
                costPerKm.map(formatNumber) ?? "",
                month
            ]
            rows.append(cols.joined(separator: ","))
            prev = e
        }
        return rows.joined(separator: "\n")
    }

    private static func csvEscape(_ s: String) -> String {
        if s.contains(",") || s.contains("\n") || s.contains("\"") {
            return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
        }
        return s
    }

    private static func formatNumber(_ d: Double) -> String {
        let f = NumberFormatter()
        f.locale = Locale(identifier: "en_US_POSIX")
        f.minimumFractionDigits = 0
        f.maximumFractionDigits = 6
        f.minimumIntegerDigits = 1
        return f.string(from: NSNumber(value: d)) ?? String(d)
    }
}
