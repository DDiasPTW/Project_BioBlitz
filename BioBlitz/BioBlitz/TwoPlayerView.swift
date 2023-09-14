import SwiftUI

struct TwoPlayerView: View {
    @StateObject var board: GameBoard
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        VStack {
            HStack{
                VStack{
                    Text("GREEN: \(board.greenScore)")
                        .padding(.horizontal)
                        .background(Capsule().fill(.green).opacity(board.currentPlayer == .green ? 1 : 0))
                    if board.currentPlayer == .green {
                        Text("\(Int(board.playerTimerProgress * board.playerTimer))")
                            .font(.system(size: 25).weight(.black))
                    }
                }.padding(.horizontal)
                
                Spacer()
                
                VStack{
                    Text("BIOBLITZ")
                        .font(.system(size: 36).weight(.black))
                    Text("\(board.currentRound) / \(board.maxRounds)")
                        .padding(.horizontal)
                        .background(Capsule().fill(.orange).opacity(board.canAttack == true ? 1 : 0))
                }.padding(.horizontal)
                
                Spacer()
                
                VStack{
                    Text("RED: \(board.redScore)")
                        .padding(.horizontal)
                        .background(Capsule().fill(.red).opacity(board.currentPlayer == .red ? 1 : 0))
                    if board.currentPlayer == .red {
                        Text("\(Int(board.playerTimerProgress * board.playerTimer))")
                            .font(.system(size: 25).weight(.black))
                    }
                }.padding(.horizontal)
            }
            .font(.system(size: 30).weight(.black))
            
            ZStack{
                VStack{
                    ForEach(0..<board.rowCount, id: \.self){ row in
                        HStack{
                            ForEach(0..<board.columnCount, id: \.self){ col in
                                let bacteria = board.grid[row][col]
                                
                                BacteriaView(bacteria: bacteria){
                                    board.rotate(bacteria: bacteria)
                                }
                            }
                        }
                    }
                }
                
                if let winner = board.winner{
                    VStack{
                        Text("\(winner) wins!")
                            .font(.largeTitle)
                            .foregroundColor(.white)
                            .fontWeight(.black)
                        
                        Button(action: board.start){
                            Text("Play again")
                                .foregroundColor(.black)
                                .fontWeight(.black)
                                .padding()
                                .background(.gray)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                        
                        Button(action: {
                            // Dismiss the current view (DetailView) and return to ContentView
                            presentationMode.wrappedValue.dismiss()
                        }){
                            Text("Back")
                                .foregroundColor(.black)
                                .fontWeight(.black)
                                .padding()
                                .background(.gray)
                                .clipShape(Capsule())
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(40)
                    .background(.gray.opacity(0.85))
                    .cornerRadius(25)
                    .transition(.scale)
                }
            }
        }
        .padding()
        .fixedSize()
        .preferredColorScheme(.dark)
    }
}

#Preview {
    TwoPlayerView(board: GameBoard())
}
