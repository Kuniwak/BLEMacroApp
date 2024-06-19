import SwiftUI
import SFSymbol
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
                Image(systemName: SFSymbol5.wifi.rawValue)
                    .foregroundStyle(Color(.error))
            } else if rssi.compare(-50) == .orderedAscending {
                Image(systemName: SFSymbol5.wifi.rawValue)
                    .foregroundStyle(Color(.warning))
            } else {
                Image(systemName: SFSymbol5.wifi.rawValue)
                    .foregroundStyle(Color(.success))
            }
        case .failure(let error):
            HStack {
                Image(systemName: SFSymbol5.Exclamationmark.circle.rawValue)
                Text(error.description)
                    .font(.footnote)
            }
            .foregroundStyle(Color(.error))
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
