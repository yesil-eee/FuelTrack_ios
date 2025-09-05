import Foundation
import SwiftData

@Model
final class FuelEntry {
    @Attribute(.unique) var id: UUID
    var brand: String
    var model: String
    var fuelType: String // BENZIN, DIZEL, LPG, ELEKTRIK
    var date: Date
    var unitPriceTlPerLt: Double
    var liters: Double
    var odometerKm: Double
    var fullTank: Bool

    init(
        id: UUID = UUID(),
        brand: String,
        model: String,
        fuelType: String,
        date: Date,
        unitPriceTlPerLt: Double,
        liters: Double,
        odometerKm: Double,
        fullTank: Bool
    ) {
        self.id = id
        self.brand = brand
        self.model = model
        self.fuelType = fuelType
        self.date = date
        self.unitPriceTlPerLt = unitPriceTlPerLt
        self.liters = liters
        self.odometerKm = odometerKm
        self.fullTank = fullTank
    }
}
