import SwiftUI

struct ContentView: View {
    @State private var isTwoPlayersSelected = false
    @State private var isFourPlayersSelected = false
    @StateObject private var board = GameBoard()
    @StateObject private var boardXL = GameBoardXL()
    
    var body: some View {
        //main menu
        if(!isTwoPlayersSelected && !isFourPlayersSelected){
            VStack {
                Text("BIOBLITZ")
                    .font(.largeTitle)
                    .fontWeight(.black)
                    .padding()
                
                Button(action: {
                    isTwoPlayersSelected = true
                    board.start()
                }) {
                    Text("2 PLAYERS")
                        .padding()
                        .frame(maxWidth:250)
                        .background(Color(#colorLiteral(red: 1, green: 0.937254902, blue: 0.7019607843, alpha: 1)))
                        .foregroundColor(.black)
                        .font(.largeTitle)
                        .fontWeight(.black)
                }
                .buttonStyle(.plain)
                
                Button(action: {
                    isFourPlayersSelected = true
                    boardXL.start()
                }) {
                    Text("4 PLAYERS")
                        .padding()
                        .frame(maxWidth: 250)
                        .background(Color(#colorLiteral(red: 1, green: 0.937254902, blue: 0.7019607843, alpha: 1)))
                        .foregroundColor(.black)
                        .font(.largeTitle)
                        .fontWeight(.black)
                }
                .buttonStyle(.plain)
            }
        }
        //2 player mode
        else if(isTwoPlayersSelected && !isFourPlayersSelected){
            TwoPlayerView(board: board)
        }
        //4 player mode
        else if(!isTwoPlayersSelected && isFourPlayersSelected){
            FourPlayerView(boardXL: boardXL)
        }
    }
}



#Preview {
    ContentView()
}
