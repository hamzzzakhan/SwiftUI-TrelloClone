import Foundation
import Combine

class Board: ObservableObject, Identifiable, Codable {
    
    private(set) var id = UUID()
    @Published var name: String
    @Published var lists: [BoardList]
    private var cancellables = Set<AnyCancellable>()
    
    enum CodingKeys: String, CodingKey {
        case id, name, lists
    }
        
    init(name: String, lists: [BoardList] = []) {
        self.name = name
        self.lists = lists
        // Add observation of lists
        for list in lists {
            observeList(list)
        }
    }
    
    private func observeList(_ list: BoardList) {
        list.objectWillChange.sink { [weak self] _ in
            self?.objectWillChange.send()
        }.store(in: &cancellables)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.id = try container.decode(UUID.self, forKey: .id)
        self.name = try container.decode(String.self, forKey: .name)
        self.lists = try container.decode([BoardList].self, forKey: .lists)
        for list in lists {
            observeList(list)
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(name, forKey: .name)
        try container.encode(lists, forKey: .lists)
    }
    
    func move(card: Card, to boardList: BoardList, at index: Int) {
        guard
            let sourceBoardListIndex = boardListIndex(id: card.boardListId),
            let destinationBoardListIndex = boardListIndex(id: boardList.id),
            sourceBoardListIndex != destinationBoardListIndex,
            let sourceCardIndex = cardIndex(id: card.id, boardIndex: sourceBoardListIndex)
        else {
            return
        }
        
        objectWillChange.send()
        boardList.cards.insert(card, at: index)
        card.boardListId = boardList.id
        lists[sourceBoardListIndex].cards.remove(at: sourceCardIndex)
    }
    
    func addNewBoardListWithName(_ name: String) {
        let newList = BoardList(name: name, boardID: id)
        observeList(newList)  
        objectWillChange.send()
        lists.append(newList)
    }
    
    func removeBoardList(_ boardList: BoardList) {
        guard let index = boardListIndex(id: boardList.id) else { return }
        objectWillChange.send()
        lists.remove(at: index)
    }
    
    private func cardIndex(id: UUID, boardIndex: Int) -> Int? {
        lists[boardIndex].cardIndex(id: id)
    }
    
    private func boardListIndex(id: UUID) -> Int? {
        lists.firstIndex { $0.id == id }
    }
}
