import Foundation
import Combine

class BoardList: NSObject, ObservableObject, Identifiable, Codable {
    
    private(set) var id = UUID()
    var boardID: UUID
    private var cancellables = Set<AnyCancellable>()
    
    @Published var name: String
    @Published var cards: [Card]
    
    enum CodingKeys: String, CodingKey {
        case id, boardId, name, cards
    }
    
    init(name: String, cards: [Card] = [], boardID: UUID) {
        self.name = name
        self.cards = cards
        self.boardID = boardID
        super.init()
        cards.forEach(observeCard)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.boardID = try container.decode(UUID.self, forKey: .boardId)
        self.name = try container.decode(String.self, forKey: .name)
        self.cards = try container.decode([Card].self, forKey: .cards)
        super.init()
        cards.forEach(observeCard)
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(boardID, forKey: .boardId)
        try container.encode(name, forKey: .name)
        try container.encode(cards, forKey: .cards)
    }
    
    private func observeCard(_ card: Card) {
        card.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    func addNewCardWithContent(_ content: String) {
        let newCard = Card(content: content, boardListId: id)
        observeCard(newCard)
        
        DispatchQueue.main.async { [weak self] in
            guard let self = self else { return }
            self.objectWillChange.send()
            self.cards.append(newCard)
            
            let updatedCards = self.cards
            self.cards = updatedCards
        }
    }
    
    func cardIndex(id: UUID) -> Int? {
        cards.firstIndex { $0.id == id }
    }
    
    func removeCard(_ card: Card) {
        guard let cardIndex = cardIndex(id: card.id) else { return }
        objectWillChange.send()
        cards.remove(at: cardIndex)
    }
    
    func moveCards(fromOffsets offsets: IndexSet, toOffset offset: Int) {
        objectWillChange.send()
        cards.move(fromOffsets: offsets, toOffset: offset)
    }
}

extension BoardList: NSItemProviderWriting {
    
    static let typeIdentifier = "com.alfianlosari.TrelloClone.BoardList"
    
    static var writableTypeIdentifiersForItemProvider: [String] {
        [typeIdentifier]
    }
    
    func loadData(withTypeIdentifier typeIdentifier: String, forItemProviderCompletionHandler completionHandler: @escaping (Data?, Error?) -> Void) -> Progress? {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            completionHandler(try encoder.encode(self), nil)
        } catch {
            completionHandler(nil, error)
        }
        return nil
    }
}

extension BoardList: NSItemProviderReading {
    
    static var readableTypeIdentifiersForItemProvider: [String] {
        [typeIdentifier]
    }
    
    static func object(withItemProviderData data: Data, typeIdentifier: String) throws -> Self {
        try JSONDecoder().decode(Self.self, from: data)
    }
}
