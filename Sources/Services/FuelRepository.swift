import Foundation
import SwiftData

enum FuelType: String, CaseIterable, Identifiable {
    case BENZIN, DIZEL, LPG, ELEKTRIK
    var id: String { rawValue }
}

struct FuelRepository {
    static func insert(_ entry: FuelEntry, context: ModelContext) throws {
        context.insert(entry)
        try context.save()
    }

    static func recent(limit: Int, context: ModelContext) throws -> [FuelEntry] {
        let descriptor = FetchDescriptor<FuelEntry>(
            predicate: nil,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        var items = try context.fetch(descriptor)
        if items.count > limit { items = Array(items.prefix(limit)) }
        return items
    }

    static func all(context: ModelContext) throws -> [FuelEntry] {
        let descriptor = FetchDescriptor<FuelEntry>(
            predicate: nil,
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        return try context.fetch(descriptor)
    }

    static func remove(_ entry: FuelEntry, context: ModelContext) throws {
        context.delete(entry)
        try context.save()
    }
}
