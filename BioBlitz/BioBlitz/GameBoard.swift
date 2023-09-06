import SwiftUI
import Combine

class GameBoard: ObservableObject{
    
    //Board size
    let rowCount = 11
    let columnCount = 22
    @Published var grid = [[Bacteria]]()
    
    //Scores
    @Published var currentPlayer = Color.green
    @Published var greenScore = 1
    @Published var redScore = 1
    private var bacteriaBeingInfected = 0
    @Published var winner: String? = nil
    
    //Rounds
    @Published var maxRounds = 15
    @Published var currentRound = 0
    
    //Timers
    @Published var playerTimerProgress: Double = 1.0
    @Published var playerTimer = 4.0
    @Published var currentPlayerTimer: AnyCancellable?
    
    init(){
        reset()
        startPlayerTimer()
    }
    
    func reset(){
        winner = nil
        //currentPlayerTimer?.cancel()
        self.playerTimerProgress = 1.0
        currentPlayer = .green
        redScore = 1
        greenScore = 1
        currentRound = 0
        
        grid.removeAll()
        
        for row in 0..<rowCount{
            var newRow = [Bacteria]()
            
            for col in 0..<columnCount{
                let bacteria = Bacteria(row: row, col: col)
                
                if row <= rowCount / 2 {
                    
                    if row == 0 && col == 0{
                        bacteria.direction = .north //top left
                    }
                    
                    else if row == 0 && col == columnCount - 1 {
                        bacteria.direction = .east //top right
                    }
                    
                    //make sure nothings points towards the players
                    else if row == 0 && col == 1{
                        bacteria.direction = .east
                    }else if row == 0 && col == columnCount - 2{
                        bacteria.direction = .west
                    }
                    else if row == 1 && col == 0{
                        bacteria.direction = .south
                    }else if row == 1 && col == columnCount - 1{
                        bacteria.direction = .south
                    }
                    else{
                        bacteria.direction = Bacteria.Direction.allCases.randomElement()!
                    }
                }
                else{
                    //mirror the board
                    if let counterPart = getBacteria(atRow: rowCount - 1 - row, col: columnCount - 1 - col){
                        bacteria.direction = counterPart.direction.opposite
                    }
                }
                
                newRow.append(bacteria)
            }
            
            grid.append(newRow)
        }
        
        grid[0][0].color = .green
        grid[rowCount - 1][columnCount - 1].color = .red
    }
    
    func startPlayerTimer() {
        guard winner == nil else { return }
        
        currentPlayerTimer = Timer.publish(every: 1.0, on: .main, in: .common)
            .autoconnect()
            .sink { _ in
                self.playerTimerProgress -= 1.0 / self.playerTimer
                if self.playerTimerProgress <= 0 && self.bacteriaBeingInfected == 0{
                    self.playerTimerProgress = 1.0
                    self.changePlayer()
                }
            }
    }
    
    func getBacteria(atRow row: Int, col: Int) -> Bacteria? {
        guard row >= 0 else {return nil}
        guard row < grid.count else {return nil}
        guard col >= 0 else {return nil}
        guard col < grid[0].count else {return nil}
        return grid[row][col]
    }
    
    func infect(from: Bacteria){
        objectWillChange.send()
        
        var bacteriaToInfect = [Bacteria?]()
        
        //direct infection
        switch from.direction {
        case .north:
            bacteriaToInfect.append(getBacteria(atRow: from.row - 1, col: from.col))
        case .south:
            bacteriaToInfect.append(getBacteria(atRow: from.row + 1, col: from.col))
        case .east:
            bacteriaToInfect.append(getBacteria(atRow: from.row, col: from.col + 1))
        case .west:
            bacteriaToInfect.append(getBacteria(atRow: from.row, col: from.col - 1))
        }
        
        //indirect infection from above
        if let indirect = getBacteria(atRow: from.row - 1, col: from.col){
            if indirect.direction == .south{
                bacteriaToInfect.append(indirect)
            }
        }
        //indirect infection from below
        if let indirect = getBacteria(atRow: from.row + 1, col: from.col){
            if indirect.direction == .north{
                bacteriaToInfect.append(indirect)
            }
        }
        //indirect infection from left
        if let indirect = getBacteria(atRow: from.row, col: from.col - 1){
            if indirect.direction == .east{
                bacteriaToInfect.append(indirect)
            }
        }
        //indirect infection from right
        if let indirect = getBacteria(atRow: from.row, col: from.col + 1){
            if indirect.direction == .west{
                bacteriaToInfect.append(indirect)
            }
        }
        
        for case let bacteria? in bacteriaToInfect{
            if bacteria.color != from.color{
                bacteria.color = from.color
                bacteriaBeingInfected += 1
                
                AudioManager.shared.playInfectionSound()
                
                Task { @MainActor in
                    try await Task.sleep(for: .milliseconds(5))
                    bacteriaBeingInfected -= 1
                    infect(from: bacteria)
                }
            }
        }
        updateScore()
    }
    
    func rotate(bacteria: Bacteria){
        guard bacteria.color == currentPlayer else { return }
        guard bacteriaBeingInfected == 0 else { return }
        guard winner == nil else { return }
        
        objectWillChange.send()
        
        bacteria.direction = bacteria.direction.next
        
        infect(from: bacteria)
    }
    
    func changePlayer() {
        // Stop the timer for the current player
        currentPlayerTimer?.cancel()
        self.playerTimerProgress = 1.0
        
        if(currentRound < maxRounds){
            if currentPlayer == .green {
                if(currentRound < maxRounds){
                    currentPlayer = .red
                }else { updateScore() }
            }else{
                currentRound += 1
                if(currentRound < maxRounds){
                    currentPlayer = .green
                }else { updateScore() }
            }
        }
        
        // Start a new timer for the current player
        startPlayerTimer()
    }
    
    func updateScore(){
        var newRedScore = 0
        var newGreenScore = 0
        var nonZeroScores = [Color]()
        
        for row in grid{
            for bacteria in row{
                if bacteria.color == .red{
                    newRedScore += 1
                }else if bacteria.color == .green{
                    newGreenScore += 1
                }
            }
        }
        
        redScore = newRedScore
        greenScore = newGreenScore
        
        if redScore > 0 {
            nonZeroScores.append(.red)
        }
        if greenScore > 0 {
            nonZeroScores.append(.green)
        }
        
        if bacteriaBeingInfected == 0{
            if nonZeroScores.count == 1{
                // Only one player has points, end the game
                winner = "\(nonZeroScores[0])"
            } else if currentRound == maxRounds {
                // Game ended due to rounds and no single winner
                withAnimation(.spring()) {
                    if redScore > greenScore {
                        winner = "RED"
                    } else if greenScore > redScore {
                        winner = "GREEN"
                    }
                    else {winner = "NOBODY"}
                }
            } else {
                changePlayer()
            }
        }
    }
}
