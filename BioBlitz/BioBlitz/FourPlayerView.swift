import SwiftUI

struct FourPlayerView: View {
    @StateObject var boardXL: GameBoardXL
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
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
                        .padding(.horizontal)
                        .background(Capsule().fill(.orange).opacity(boardXL.canAttack == true ? 1 : 0))
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
                        
                        Button(action: boardXL.start){
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
    FourPlayerView(boardXL: GameBoardXL())
}
