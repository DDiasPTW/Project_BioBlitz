import SwiftUI
import Combine

class GameBoard: ObservableObject{
    //.green -> player 1, .red -> player 2, .orange -> bomb power-up, .purple crossPower-up
    
    //Board size
    let rowCount = 12
    let columnCount = 24
    @Published var grid = [[Bacteria]]()
    
    //Scores
    @Published var currentPlayer = Color.green
    @Published var greenScore = 1
    @Published var redScore = 1
    private var bacteriaBeingInfected = 0
    @Published var winner: String? = nil
    
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
    
    //Power-ups
    private var bombRadius = 2 //.orange
    
    private let rowsToInfect = 5 // Number of rows to affect above and below -> .purple
    private let colsToInfect = 5 // Number of columns to affect to the left and right -> .purple
    
    init(){
        start()
    }
    
    func start(){
        winner = nil
        startPlayerTimer()
        //currentPlayerTimer?.cancel()
        self.playerTimerProgress = 1.0
        currentPlayer = .green
        redScore = 1
        greenScore = 1
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
        
        // Bomb power-up
        var randomRowBomb: Int
        var randomColBomb: Int
        
        repeat {
            randomRowCross = Int.random(in: 1..<rowCount)
            randomColCross = Int.random(in: 1..<columnCount)
            
            randomRowBomb = Int.random(in: 1..<rowCount)
            randomColBomb = Int.random(in: 1..<columnCount)
        } while randomRowCross == randomRowBomb && randomColCross == randomColBomb
        
        
        //place players and power-ups
        grid[0][0].color = .green
        grid[rowCount - 1][columnCount - 1].color = .red
        grid[randomRowCross][randomColCross].color = .purple //cross power-up
        grid[randomRowBomb][randomColBomb].color = .orange //bomb power-up
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
                        (from.color == .red && bacteria.color != .gray && canAttack )
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
        
        if(currentRound < maxRounds){
            if currentPlayer == .green {
                if(currentRound < maxRounds){
                    currentPlayer = .red
                }else { updateScore() }
            }else{
                currentRound += 1
                howManyRounds -= 1
                if(currentRound < maxRounds){
                    currentPlayer = .green
                    if howManyRounds < -howManyAttackRounds{
                        howManyRounds = roundsUntilAttack
                        canAttack = false
                    }else if howManyRounds < 0 && roundsUntilAttack >= -roundsUntilAttack{ canAttack = true }
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
