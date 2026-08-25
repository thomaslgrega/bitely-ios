import Foundation
import SwiftData

@Model
class ShoppingListItem: Identifiable {
    @Attribute(.unique) var id = UUID()
    var name: String
    var measurement: String
    var purchased: Bool = false

    init(name: String, measurement: String) {
        self.name = name
        self.measurement = measurement
    }
}
