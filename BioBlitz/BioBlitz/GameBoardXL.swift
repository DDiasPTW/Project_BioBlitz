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
    @Published var maxRounds = 40
    @Published var currentRound = 0
    
    //Timers
    @Published var playerTimerProgress: Double = 1.0
    @Published var playerTimer = 7.0
    @Published var currentPlayerTimer: AnyCancellable?
    
    //Attack phase
    @Published var canAttack = false
    private var roundsUntilAttack = 3
    @Published var howManyAttackRounds = 4
    @Published var howManyRounds = 0
    
    //Power-ups
    private let bombRadius = 2 //.orange
    
    private let rowsToInfect = 5 // Number of rows to affect above and below -> .purple
    private let colsToInfect = 5 // Number of columns to affect to the left and right -> .purple
    
    
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
        generateGrid()
    }
    
    func generateGrid(){
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
        
        // Cross power-up -> decide where it stays in the board
        var randomRowCross: Int
        var randomColCross: Int
        var randomRowCross2: Int
        var randomColCross2: Int
        
        // Bomb power-up
        var randomRowBomb: Int
        var randomColBomb: Int
        
        repeat {
            randomRowCross = Int.random(in: 3..<rowCount)
            randomColCross = Int.random(in: 3..<columnCount)
            
            randomRowCross2 = Int.random(in: 3..<rowCount)
            randomColCross2 = Int.random(in: 3..<columnCount)
            
            randomRowBomb = Int.random(in: 3..<rowCount)
            randomColBomb = Int.random(in: 3..<columnCount)
        } while randomRowCross == randomRowBomb && randomColCross == randomColBomb && randomRowCross == randomRowCross2 &&
        randomColCross == randomColCross2 && randomRowBomb == randomRowCross2 && randomColBomb == randomColCross2
        
        //place players and power ups
        grid[0][0].color = .green
        grid[rowCount - 1][columnCount - 1].color = .red
        grid[0][columnCount - 1].color = .yellow
        grid[rowCount - 1][0].color = .blue
        grid[randomRowCross][randomColCross].color = .purple //cross power-up
        grid[randomRowCross2][randomColCross2].color = .purple //cross power-up
        grid[randomRowBomb][randomColBomb].color = .orange //bomb power-up
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
            if (from.color != .gray && bacteria.color == .purple) // Cross power up
            {
                // Do not change the color of the purple bacteria so that other players can use the power-up as well
                
                // Infect bacteria in the same row
                for col in max(0, bacteria.col - colsToInfect)..<min(columnCount, bacteria.col + colsToInfect + 1) {
                    if col != bacteria.col {
                        let otherBacteria = grid[bacteria.row][col]
                        
                        if otherBacteria.color != from.color {
                            otherBacteria.color = from.color
                            bacteriaBeingInfected += 1
                            
                            AudioManager.shared.playInfectionSound()
                            
                            bacteriaToInfect.append(otherBacteria) // Append to the list of bacteria to infect
                            
                            Task { @MainActor in
                                try await Task.sleep(for: .milliseconds(5))
                                bacteriaBeingInfected -= 1
                                infect(from: otherBacteria)
                            }
                        }
                    }
                }
                
                // Infect bacteria in the same column
                for row in max(0, bacteria.row - rowsToInfect)..<min(rowCount, bacteria.row + rowsToInfect + 1) {
                    if row != bacteria.row {
                        let otherBacteria = grid[row][bacteria.col]
                        
                        if otherBacteria.color != from.color {
                            otherBacteria.color = from.color
                            bacteriaBeingInfected += 1
                            
                            AudioManager.shared.playInfectionSound()
                            
                            bacteriaToInfect.append(otherBacteria) // Append to the list of bacteria to infect
                            
                            Task { @MainActor in
                                try await Task.sleep(for: .milliseconds(5))
                                bacteriaBeingInfected -= 1
                                infect(from: otherBacteria)
                            }
                        }
                    }
                }
            }
            else if (from.color != .gray && bacteria.color == .orange) // Bomb power up
            {
                for row in grid.indices {
                    for col in grid[row].indices {
                        let otherBacteria = grid[row][col]
                        
                        // Calculate the distance between the bomb and the other bacteria
                        let rowDistance = abs(otherBacteria.row - bacteria.row)
                        let colDistance = abs(otherBacteria.col - bacteria.col)
                        
                        // Check if the bacteria is within the specified radius
                        if rowDistance <= bombRadius && colDistance <= bombRadius {
                            if otherBacteria.color != from.color{
                                otherBacteria.color = from.color
                                bacteriaBeingInfected += 1
                                
                                AudioManager.shared.playInfectionSound()
                                
                                bacteriaToInfect.append(otherBacteria) // Append to the list of bacteria to infect
                                
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
