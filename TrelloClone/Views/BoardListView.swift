import SwiftUI
import Introspect

struct BoardListView: View {
    @ObservedObject var board: Board
    @ObservedObject var boardList: BoardList
    @State var listHeight: CGFloat = 0
    @State private var dragging: BoardList? = nil  
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            headerView
            listView
                .frame(maxHeight: listHeight)
            
            Button("+ Add card") {
                handleAddCard()
            }
            .padding(.horizontal)
            .frame(maxWidth: .infinity, alignment: .center)
        }
        .padding(.vertical)
        .background(boardListBackgroundColor)
        .frame(width: 300)
        .cornerRadius(8)
        .foregroundColor(.black)
    }
    
    private var headerView: some View {
        HStack(alignment: .top) {
            Text(boardList.name)
                .font(.headline)
                .lineLimit(2)
            
            Spacer()
            
            Menu {
                Button("Rename") {
                    handleBoardListRename()
                }
                
                Button("Delete", role: .destructive) {
                    board.removeBoardList(boardList)
                }
                
            } label: {
                Image(systemName: "ellipsis.circle")
                    .imageScale(.large)
            }
        }
        .padding(.horizontal)
    }
    
    private var listView: some View {
        ScrollView {
            LazyVStack(spacing: 4) {
                ForEach(boardList.cards) { card in
                    CardView(boardList: boardList, card: card)
                        .onDrag {
                            NSItemProvider(object: card)
                        }
                }
                .onInsert(of: [Card.typeIdentifier], perform: handleOnInsertCard)
                .onMove(perform: boardList.moveCards(fromOffsets:toOffset:))
            }
            .padding(.horizontal, 8)
        }
        .introspectScrollView { scrollView in
            DispatchQueue.main.async {
                listHeight = scrollView.contentSize.height
            }
        }
        .onDrop(of: [Card.typeIdentifier], delegate: BoardDropDelegate(board: board, boardList: boardList, lists: $board.lists, current: $dragging))
    }
    
    private func handleOnInsertCard(index: Int, itemProviders: [NSItemProvider]) {
        for itemProvider in itemProviders {
            itemProvider.loadObject(ofClass: Card.self) { item, _ in
                guard let card = item as? Card else { return }
                DispatchQueue.main.async {
                    board.move(card: card, to: boardList, at: index)
                }
            }
        }
    }
    
    private func handleBoardListRename() {
        presentAlertTextField(title: "Rename list", defaultTextFieldText: boardList.name) { text in
            guard let text = text, !text.isEmpty else {
                return
            }
            boardList.name = text
        }
    }
    
    private func handleAddCard() {
        presentAlertTextField(title: "Add card to \(boardList.name)") { text in
            guard let text = text, !text.isEmpty else {
                return
            }
            boardList.addNewCardWithContent(text)
        }
    }
}

struct BoardListView_Previews: PreviewProvider {
    @StateObject static var board = Board.stub
    
    static var previews: some View {
        BoardListView(board: board, boardList: board.lists[0])
            .previewLayout(.sizeThatFits)
            .frame(width: 300, height: 512)
    }
}
