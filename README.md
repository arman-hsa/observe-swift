# Observable

[![GitHub release](https://img.shields.io/github/release/aaronsky/Observable.svg)](https://github.com/aaronsky/Observable/releases) 
[![Travis](https://img.shields.io/travis/aaronsky/Observable.svg)](https://travis-ci.org/aaronsky/Observable) 
[![Codecov](https://img.shields.io/codecov/c/github/aaronsky/Observable.svg)](https://codecov.io/gh/aaronsky/Observable) 
![Swift version 4.0](https://img.shields.io/badge/Swift-4.0-F16D39.svg?style=flat)

A micro-framework for observing changes in properties. Combined with Swift 4 keypath syntax, this is a powerfully expressive way to monitor changes on Swift value types without relying on Key-Value Observing. 


## Installing 

Add the following to your Package.swift file's dependencies:

```swift
.package(url: "https://github.com/aaronsky/Observable.git", from: "1.0.0"),
```

And then import wherever needed: `import Observable`

## Usage

```swift
import Observable

/**
 * 1. Observable Basics
 */

let observable = Observable("Janice")

// You can get the internal value using the `value` property
print(observable.value)

// You can also use `value` to modify the observable. This will update all subscribed observers of the change
observable.value = "Denise"

/**
 * 2. Observing Change
 */

// To subscribe to an Observable, you need a class type with an appropriately typed handling method. For example:
class ObservingClass {
    func onObservedChange(_ newValue: String, _ previousValue: String) {
        print("new value", newValue, "changed from", previousValue)
    }
}

let observing = ObservingClass()

// Then you create an Observer instance with an event type, target and handler
let observer = Observer(.didSet, target: observing, handler: ObservingClass.onObservedChange)

// Finally, pass the Observer to `subscribe(_: Observer)`
observable.subscribe(observer)
observable.value = "Melinda" // prints "new value Melinda changed from Denise"

// To unsubscribe, pass the original Observer to `unsubscribe(_: Observer)`
observable.unsubscribe(observer)

// You can also unsubscribe from all observers for a specific event type, or clear all of them. 
// Observable calls this automatically when it is deinitialized.
observable.unsubscribeAllObservers(for: .didSet)
observable.unsubscribeAllObservers()

/**
 * 3. Observable + Codable
 */

// You can also use Observable with Codable!
struct Person: Codable, CustomStringConvertible {
    let name: String
    let age: Observable<Int>

    var description: String {
        returns "Person: (\(name), \(age.value))"
    }
}

let json = "{"name":"Darlene","age":28}".data(using: .utf8)!
let obj = try JSONDecoder().decode(ObjectWithObservable.self, from: json)
print(obj) // prints "Person: (Darlene, 28))"

let data = JSONEncoder().encode(obj)
print(String(data: data, encoding: .utf8) ?? "") // prints "{\"age\":28,\"name\":\"Darlene\"}"
``` 

## Contributions

Pull requests and issues are always welcome and appreciated. 

## License

Observable is licensed under the MIT license. See [LICENSE](LICENSE) for more information.