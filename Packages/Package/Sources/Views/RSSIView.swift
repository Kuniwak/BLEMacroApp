import SwiftUI
import Models


public struct RSSIView: View {
    public var rssi: Result<NSNumber, PeripheralModelFailure>
    
    
    public init(rssi: Result<NSNumber, PeripheralModelFailure>) {
        self.rssi = rssi
    }
    
    
    public var body: some View {
        switch rssi {
        case .success(let rssi):
            if rssi.compare(-70) == .orderedAscending {
                Image(systemName: "wifi.slash")
                    .foregroundStyle(.red)
            } else if rssi.compare(-50) == .orderedAscending {
                Image(systemName: "wifi")
                    .foregroundStyle(.yellow)
            } else {
                Image(systemName: "wifi")
                    .foregroundStyle(.green)
            }
        case .failure(let error):
            Text(error.description)
                .font(.footnote)
                .foregroundStyle(.red)
        }
    }
}

#Preview {
    List {
        RSSIView(rssi: .success(-80))
        RSSIView(rssi: .success(-60))
        RSSIView(rssi: .success(-40))
        RSSIView(rssi: .failure(.init(description: "error")))
    }
}
