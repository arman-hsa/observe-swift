import XCTest
@testable import Observable

struct MockJson: Codable {
    let name: String
    let age: Observable<Int>
    let isHungry: Observable<Bool>
    var someOptional: Observable<String>? = nil
    let hunger: Observable<NestedMockJson>
    
    init(name: String, age: Int, isHungry: Bool, someOptional: String? = nil, hunger: NestedMockJson) {
        self.name = name
        self.age = Observable(age)
        self.isHungry = Observable(isHungry)
        if let someOptional = someOptional {
            self.someOptional = Observable(someOptional)
        }
        self.hunger = Observable(hunger)
    }
}

struct NestedMockJson: Codable {
    let hunger: Observable<Float>
    
    init(hunger: Float) {
        self.hunger = Observable(hunger)
    }
}

class MockObserving {
    let expectation: XCTestExpectation
    
    init(expectation: XCTestExpectation) {
        self.expectation = expectation
    }
    
    func handleChange<T>(newValue: T, previousValue: T) {
        expectation.fulfill()
    }
}

class ObservableTests: XCTestCase {
    func testThatObserverTriggeredOnChange() {
        let observable = Observable(6.0)
        let expect = expectation(description: "Expected change")
        let observing = MockObserving(expectation: expect)
        observable.subscribe(Observer(.didSet, target: observing, handler: MockObserving.handleChange))
        observable.value = 8.0
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testThatMultipleObserversTriggeredOnChange() {
        let observable = Observable(6.0)
        let expect = expectation(description: "Expected changes")
        expect.expectedFulfillmentCount = 4
        let observing = MockObserving(expectation: expect)
        for _ in 0..<expect.expectedFulfillmentCount {
            observable.subscribe(Observer(.didSet, target: observing, handler: MockObserving.handleChange))
        }
        observable.value = 8.0
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testThatUnsubscribeNoLongerTriggersHandler() {
        let observable = Observable(6.0)
        let expect = expectation(description: "Expected no change")
        expect.isInverted = true
        let observing = MockObserving(expectation: expect)
        let observer = Observer<Double>(.didSet, target: observing, handler: MockObserving.handleChange)
        observable.subscribe(observer)
        observable.unsubscribe(observer)
        observable.value = 8.0
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testUnsubscribeAllForSpecificObservationEvent() {
        let observable = Observable(6.0)
        
        let invertedExpect = expectation(description: "Expected no change")
        invertedExpect.isInverted = true
        let invertedObserving = MockObserving(expectation: invertedExpect)
        let invertedObserver = Observer<Double>(.didSet, target: invertedObserving, handler: MockObserving.handleChange)
        observable.subscribe(invertedObserver)
        
        let expect = expectation(description: "Expected no change")
        let observing = MockObserving(expectation: expect)
        let observer = Observer<Double>(.willSet, target: observing, handler: MockObserving.handleChange)
        observable.subscribe(observer)
        
        observable.unsubscribeAllObservers(for: .didSet)
        observable.value = 8.0
        
        waitForExpectations(timeout: 0.5, handler: nil)
    }
    
    func testThatDescriptionIsCorrect() {
        let value = "dog"
        let expected = String(describing: value)
        let observable = Observable(value)
        let actual = observable.description
        XCTAssertEqual(expected, actual)
    }
    
    func testThatObservableDecodesCorrectly() throws {
        let expected = 3000
        let jsonString = """
        { "name": "Aaron", "age": \(expected), "isHungry": true, "someOptional": "denise", "hunger": { "hunger": 10.6 } }
        """
        guard let json = jsonString.data(using: .utf8) else {
            XCTFail("Unable to convert JSON string to Data")
            return
        }
        let decoder = JSONDecoder()
        let decoded = try decoder.decode(MockJson.self, from: json)
        XCTAssertEqual(expected, decoded.age.value)
    }
    
    func testThatObservableEncodesCorrectly() throws {
        let expected = """
        {"age":3000,"isHungry":true,"hunger":{"hunger":10.6},"name":"Aaron"}
        """
        let mockJson = MockJson(name: "Aaron", age: 3000, isHungry: true, hunger: NestedMockJson(hunger: 10.6))
        let encoder = JSONEncoder()
        let encoded = try encoder.encode(mockJson)
        guard let jsonString = String(data: encoded, encoding: .utf8) else {
            XCTFail("Unable to convert Data to JSON string")
            return
        }
        XCTAssertEqual(expected, jsonString)
    }
    
    static var allTests = [
        ("testThatObserverTriggeredOnChange", testThatObserverTriggeredOnChange),
        ("testThatMultipleObserversTriggeredOnChange", testThatMultipleObserversTriggeredOnChange),
        ("testThatObservableDecodesCorrectly", testThatObservableDecodesCorrectly),
        ("testThatObservableEncodesCorrectly", testThatObservableEncodesCorrectly)
    ]
}
