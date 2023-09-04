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
                    board.reset()
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
                    boardXL.reset()
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
                            
                            Button(action: board.reset){
                                Text("Play again")
                                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
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
        //4 player mode
        else if(!isTwoPlayersSelected && isFourPlayersSelected){
            VStack {
                HStack{
                    VStack{
                        Text("GREEN: \(boardXL.greenScore)")
                            .padding(.horizontal)
                            .background(Capsule().fill(.green).opacity(boardXL.currentPlayer == .green ? 1 : 0))
                            .fixedSize(horizontal: true, vertical: false)
                        
                        if boardXL.currentPlayer == .green {
                            Text("\(Int(boardXL.playerTimerProgress * boardXL.playerTimer))")
                                .font(.system(size: 18).weight(.black))
                        }
                    }.padding(.horizontal)
                    
                    
                    
                    VStack{
                        Text("YELLOW: \(boardXL.yellowScore)")
                            .padding(.horizontal)
                            .background(Capsule().fill(.yellow).opacity(boardXL.currentPlayer == .yellow ? 1 : 0))
                            .fixedSize(horizontal: true, vertical: false)
                        
                        if boardXL.currentPlayer == .yellow {
                            Text("\(Int(boardXL.playerTimerProgress * boardXL.playerTimer))")
                                .font(.system(size: 18).weight(.black))
                        }
                    }.padding(.horizontal)
                    
                    Spacer()
                    
                    VStack{
                        Text("BIOBLITZ")
                            .font(.system(size: 36).weight(.black))
                        Text("\(boardXL.currentRound) / \(boardXL.maxRounds)")
                    }.padding(.horizontal)
                    
                    Spacer()
                    
                    VStack{
                        Text("BLUE: \(boardXL.blueScore)")
                            .padding(.horizontal)
                            .background(Capsule().fill(.blue).opacity(boardXL.currentPlayer == .blue ? 1 : 0))
                            .fixedSize(horizontal: true, vertical: false)
                        
                        if boardXL.currentPlayer == .blue {
                            Text("\(Int(boardXL.playerTimerProgress * boardXL.playerTimer))")
                                .font(.system(size: 18).weight(.black))
                        }
                    }.padding(.horizontal)
                    
                    
                    
                    VStack{
                        Text("RED: \(boardXL.redScore)")
                            .padding(.horizontal)
                            .background(Capsule().fill(.red).opacity(boardXL.currentPlayer == .red ? 1 : 0))
                            .fixedSize(horizontal: true, vertical: false)
                        
                        if boardXL.currentPlayer == .red {
                            Text("\(Int(boardXL.playerTimerProgress * boardXL.playerTimer))")
                                .font(.system(size: 18).weight(.black))
                        }
                    }.padding(.horizontal)
                }
                .font(.system(size: 24).weight(.black))
                
                ZStack{
                    VStack{
                        ForEach(0..<boardXL.rowCount, id: \.self){ row in
                            HStack{
                                ForEach(0..<boardXL.columnCount, id: \.self){ col in
                                    let bacteria = boardXL.grid[row][col]
                                    
                                    BacteriaView(bacteria: bacteria){
                                        boardXL.rotate(bacteria: bacteria)
                                    }
                                }
                            }
                        }
                    }
                    
                    if let winner = boardXL.winner{
                        VStack{
                            Text("\(winner) wins!")
                                .font(.largeTitle)
                                .foregroundColor(.white)
                                .fontWeight(.black)
                            
                            Button(action: boardXL.reset){
                                Text("Play again")
                                    .foregroundColor(/*@START_MENU_TOKEN@*/.blue/*@END_MENU_TOKEN@*/)
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
}



#Preview {
    ContentView()
}
