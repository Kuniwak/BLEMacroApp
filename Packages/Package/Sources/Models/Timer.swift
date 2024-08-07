import Foundation
import Combine


/// Timer that can work on not main-thread.
public final actor Timer {
    private var internalTimer: TimerInternal? = nil
    private var startRequested = false
    private var cancellables = Set<AnyCancellable>()
    nonisolated public let publisher: AnyPublisher<Void, Never>
    nonisolated private let subject: PassthroughSubject<Void, Never>

    
    public init(withTimeInterval interval: TimeInterval) {
        let subject = PassthroughSubject<Void, Never>()
        self.subject = subject
        self.publisher = subject.eraseToAnyPublisher()
        
        Task { await self.setupTimer(withTimeInterval: interval) }
    }
    
    
    private func setupTimer(withTimeInterval interval: TimeInterval) {
        Task {
            let timer = await TimerInternal(withTimeInterval: interval)
            timer.publisher
                .subscribe(subject)
                .store(in: &self.cancellables)
            self.internalTimer = timer

            if self.startRequested {
                await timer.start()
            }
        }
    }
    
    
    private func requestStartIfGetReady(_ enabled: Bool) {
        self.startRequested = enabled
    }
    
    
    nonisolated public func start() {
        Task {
            if let internalTimer = await self.internalTimer {
                await internalTimer.start()
            } else {
                await self.requestStartIfGetReady(true)
            }
        }
    }
    
    
    nonisolated public func stop() {
        Task {
            if let internalTimer = await self.internalTimer {
                await internalTimer.stop()
            } else {
                await self.requestStartIfGetReady(false)
            }
        }
    }
    
    
    // XXX: It must be the MainActor because the event handlers of Timer are not called on non-main threads.
    @MainActor
    private class TimerInternal {
        private var timer: Foundation.Timer? = nil
        private let interval: TimeInterval
        private let subject: PassthroughSubject<Void, Never>
        nonisolated public let publisher: AnyPublisher<Void, Never>
        
        
        public init(withTimeInterval interval: TimeInterval) {
            self.interval = interval
            let subject = PassthroughSubject<Void, Never>()
            self.subject = subject
            self.publisher = subject.eraseToAnyPublisher()
        }
        
        
        deinit {
            self.timer?.invalidate()
        }

        
        public func start() {
            guard timer == nil else { return }
            self.timer = Foundation.Timer.scheduledTimer(withTimeInterval: self.interval, repeats: true) { [weak self] _ in
                guard let self else { return }
                Task { await self.fire() }
            }
        }
        
        
        public func stop() {
            guard let timer else { return }
            timer.invalidate()
            self.timer = nil
        }
        
        
        private func fire() {
            self.subject.send()
        }
    }
}
