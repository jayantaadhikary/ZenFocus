import Foundation
import SwiftData

@Model
class FocusTask: Identifiable, Hashable {
    @Attribute(.unique) var id: UUID
    var name: String
    var icon: String
    
    init(name: String, icon: String) {
        self.id = UUID()
        self.name = name
        self.icon = icon
    }
}
