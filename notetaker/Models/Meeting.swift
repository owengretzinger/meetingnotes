import Foundation

struct Meeting: Codable, Identifiable, Hashable {
    let id: UUID
    let date: Date
    var transcript: String
    var userNotes: String
    var generatedNotes: String
    
    init(id: UUID = UUID(), 
         date: Date = Date(), 
         transcript: String = "", 
         userNotes: String = "", 
         generatedNotes: String = "") {
        self.id = id
        self.date = date
        self.transcript = transcript
        self.userNotes = userNotes
        self.generatedNotes = generatedNotes
    }
} 