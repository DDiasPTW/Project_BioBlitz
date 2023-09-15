import SwiftUI
import Combine

class GameBoardXL: ObservableObject{
    //.green -> player 1, .red -> player 4 , .yellow -> player 2, .blue -> player 3, .orange -> bomb power-up, .purple crossPower-up
    
    
    //Board size
    let rowCount = 15
    let columnCount = 30
    @Published var grid = [[Bacteria]]()
    
    //Scores
    @Published var currentPlayer = Color.green
    @Published var greenScore = 1
    @Published var redScore = 1
    @Published var yellowScore = 1
    @Published var blueScore = 1
    @Published var winner: String? = nil
    private var bacteriaBeingInfected = 0
    
    //Rounds
    @Published var maxRounds = 30
    @Published var currentRound = 0
    
    //Timers
    @Published var playerTimerProgress: Double = 1.0
    @Published var playerTimer = 7.0
    @Published var currentPlayerTimer: AnyCancellable?
    
    //Attack phase
    @Published var canAttack = false
    private var roundsUntilAttack = 3
    @Published var howManyAttackRounds = 3
    @Published var howManyRounds = 0
    
    
    init(){
        start()
        startPlayerTimer()
    }
    
    func start(){
        winner = nil
        //currentPlayerTimer?.cancel()
        self.playerTimerProgress = 1.0
        currentPlayer = .green
        redScore = 1
        greenScore = 1
        yellowScore = 1
        blueScore = 1
        currentRound = 0
        howManyRounds = roundsUntilAttack
        canAttack = false
        grid.removeAll()
        
        
        //!TO DO: ADD "BOMB" POWER-UP | ADD "LINE" POWER-UP
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
        
        //Cross power-up -> decide where in the board it stays
        let randomRow = Int.random(in: 5..<rowCount)
        let randomCol = Int.random(in: 5..<columnCount)
        
        //place players and power ups
        grid[0][0].color = .green
        grid[rowCount - 1][columnCount - 1].color = .red
        grid[0][columnCount - 1].color = .yellow
        grid[rowCount - 1][0].color = .blue
        grid[randomRow][randomCol].color = .purple //cross power-up
    }
    
    func startPlayerTimer() {
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
            if (from.color != .gray && bacteria.color == .purple) //cross power up
            {
                for row in grid {
                    for otherBacteria in row {
                        if otherBacteria.row == bacteria.row || otherBacteria.col == bacteria.col {
                            if otherBacteria.color != from.color {
                                otherBacteria.color = from.color
                                bacteriaBeingInfected += 1
                                
                                AudioManager.shared.playInfectionSound()
                                
                                Task { @MainActor in
                                    try await Task.sleep(for: .milliseconds(5))
                                    bacteriaBeingInfected -= 1
                                    infect(from: otherBacteria)
                                }
                            }
                        }
                    }
                }
            }
            else if (from.color != .gray && bacteria.color == .gray) ||
                (from.color == .green && bacteria.color != .gray && canAttack) ||
                (from.color == .red && bacteria.color != .gray && canAttack ||
                 from.color == .blue && bacteria.color != .gray && canAttack) ||
                (from.color == .yellow && bacteria.color != .gray && canAttack)
            {
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
        
        repeat {
            if(currentRound < maxRounds){
                if currentPlayer == .green {
                    if(currentRound < maxRounds){
                        currentPlayer = .yellow
                    }else {updateScore()}
                } else if currentPlayer == .yellow {
                    if(currentRound < maxRounds){
                        currentPlayer = .blue
                    }else {updateScore()}
                } else if currentPlayer == .blue {
                    if(currentRound < maxRounds){
                        currentPlayer = .red
                    }else {updateScore()}
                } else if currentPlayer == .red{
                    currentRound += 1
                    howManyRounds -= 1
                    if(currentRound < maxRounds){
                        currentPlayer = .green
                        if howManyRounds < -howManyAttackRounds{
                            howManyRounds = roundsUntilAttack
                            canAttack = false
                        }else if howManyRounds < 0 && roundsUntilAttack >= -roundsUntilAttack{ canAttack = true }
                    }else {updateScore()}
                }
            }else { updateScore() }
        }
        while (currentPlayer == .yellow && yellowScore == 0 ||
                currentPlayer == .green && greenScore == 0 ||
                currentPlayer == .blue && blueScore == 0 ||
                currentPlayer == .red && redScore == 0)
                
        // Start a new timer for the current player
        startPlayerTimer()
    }
    
    func updateScore(){
        var newRedScore = 0
        var newGreenScore = 0
        var newYellowScore = 0
        var newBlueScore = 0
        var nonZeroScores = [Color]()
        
        
        for row in grid{
            for bacteria in row{
                if bacteria.color == .red{
                    newRedScore += 1
                }else if bacteria.color == .green{
                    newGreenScore += 1
                }else if bacteria.color == .yellow{
                    newYellowScore += 1
                }else if bacteria.color == .blue{
                    newBlueScore += 1
                }
            }
        }
        
        redScore = newRedScore
        greenScore = newGreenScore
        yellowScore = newYellowScore
        blueScore = newBlueScore
        
        if redScore > 0 {
            nonZeroScores.append(.red)
        }
        if greenScore > 0 {
            nonZeroScores.append(.green)
        }
        if yellowScore > 0 {
            nonZeroScores.append(.yellow)
        }
        if blueScore > 0 {
            nonZeroScores.append(.blue)
        }
        
        if bacteriaBeingInfected == 0{
            if nonZeroScores.count == 1{
                // Only one player has points, end the game
                winner = "\(nonZeroScores[0])"
            } else if currentRound == maxRounds {
                // Game ended due to rounds and no single winner
                withAnimation(.spring()) {
                    if redScore > greenScore && redScore > blueScore && redScore > yellowScore {
                        winner = "RED"
                    } else if greenScore > redScore && greenScore > blueScore && greenScore > yellowScore {
                        winner = "GREEN"
                    } else if blueScore > greenScore && blueScore > redScore && blueScore > yellowScore {
                        winner = "BLUE"
                    } else if yellowScore > greenScore && yellowScore > blueScore && yellowScore > redScore {
                        winner = "YELLOW"
                    } else {winner = "NOBODY"}
                }
            } else {
                changePlayer()
            }
        }
    }
}
