import SwiftUI

struct BacteriaView: View {
    var bacteria: Bacteria
    var rotationAction: () -> Void
    
    var image: String {
        switch bacteria.color{
        case .red:
                return "chevron.up.circle.fill"
        case .green:
                return "chevron.up.circle.fill"
        case .yellow:
                return "chevron.up.square.fill"
        case .blue:
                return "chevron.up.square.fill"
        default:
            return "chevron.up.circle"
        }
    }
    
    var body: some View {
        ZStack{
            Button(action: rotationAction){
                Image(systemName: image)
                    .resizable()
                    .foregroundColor(bacteria.color)
            }
            .buttonStyle(.plain)
            .frame(width: 32, height: 32)
            
            Rectangle()
                .fill(bacteria.color)
                .frame(width: 3, height: 8)
                .offset(y: -20)
        }
        .rotationEffect(.degrees(bacteria.direction.rotation))
    }
}
