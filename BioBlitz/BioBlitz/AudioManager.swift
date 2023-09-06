import AVFoundation

class AudioManager {
    static let shared = AudioManager() // Singleton instance
    
    private var audioPlayer: AVAudioPlayer?
    
    private init() { }
    
    func playInfectionSound() {
        if let soundURL = Bundle.main.url(forResource: "683587__yehawsnail__bubble-pop", withExtension: "wav") {
            do {
                audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
                audioPlayer?.play()
            } catch {
                print("Error playing sound: \(error.localizedDescription)")
            }
        }
    }
}

