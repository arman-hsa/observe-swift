import Foundation

public enum ObservationEvent: Int, EnumCollection {
    case willSet = 0
    case didSet
}

public class Observer<T> {
    private typealias EventHandler = (AnyObject) -> (T, T) -> ()
    
    fileprivate let event: ObservationEvent
    private weak var target: AnyObject?
    private let handler: EventHandler
    
    public init<U: AnyObject>(_ event: ObservationEvent, target: U, handler: @escaping (U) -> (T, T) -> ()) {
        self.event = event
        self.target = target
        self.handler = { handler($0 as! U) }
    }
    
    fileprivate func observeChange(_ newValue: T, _ previousValue: T) {
        guard let target = target else {
            return
        }
        handler(target)(newValue, previousValue)
    }
}

public class Observable<T>: Codable where T: Codable {
    private typealias ObservationTable = [ObservationEvent: [Observer<T>]]
    
    public var value: T {
        willSet {
            notifyObservers(for: .willSet, newValue: newValue, previousValue: value)
        }
        didSet {
            notifyObservers(for: .didSet, newValue: value, previousValue: oldValue)
        }
    }
    
    private lazy var observers: ObservationTable = {
        return ObservationEvent.allValues.reduce(into: ObservationTable()) { $0[$1] = [] }
    }()
    
    public init(_ value: T) {
        self.value = value
    }
    
    public required convenience init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(T.self)
        self.init(value)
    }
    
    deinit {
        unsubscribeAllObservers()
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(value)
    }
    
    public func subscribe(_ observer: Observer<T>) {
        observers[observer.event]?.append(observer)
    }
    
    public func unsubscribe(_ observer: Observer<T>) {
        guard let observersForEvent = observers[observer.event] else {
            fatalError("This Observable's observers dictionary somehow does not have keys for all event types. This should not happen and should be reported immediately to the framework maintainer.")
        }
        observers[observer.event] = observersForEvent.filter { $0 !== observer }
    }
    
    public func unsubscribeAllObservers(for event: ObservationEvent? = nil) {
        if let event = event {
            observers[event] = []
        } else {
            observers[.willSet] = []
            observers[.didSet] = []
        }
    }
    
    private func notifyObservers(for event: ObservationEvent, newValue: T, previousValue: T) {
        guard let observers = observers[event] else {
            fatalError("This Observable's observers dictionary somehow does not have keys for all event types. This should not happen and should be reported immediately to the framework maintainer.")
        }
        for observer in observers {
            DispatchQueue.global(qos: .background).async {
                observer.observeChange(newValue, previousValue)
            }
        }
    }
}

extension Observable: CustomStringConvertible {
    public var description: String {
        return String(describing: value)
    }
}

public extension KeyedDecodingContainer {
    func decode<T>(_ type: Observable<T>.Type, forKey key: K) throws -> Observable<T> {
        let value = try decode(T.self, forKey: key)
        return Observable(value)
    }
    
    func decodeIfPresent<T>(_ type: Observable<T>.Type, forKey key: K) throws -> Observable<T>? {
        guard let value = try decodeIfPresent(T.self, forKey: key) else {
            return nil
        }
        return Observable(value)
    }
}

public extension KeyedEncodingContainer {
    mutating func encode<T>(_ value: Observable<T>, forKey key: K) throws {
        try encode(value.value, forKey: key)
    }
    
    mutating func encodeIfPresent<T>(_ value: Observable<T>?, forKey key: K) throws {
        try encodeIfPresent(value?.value, forKey: key)
    }
}
