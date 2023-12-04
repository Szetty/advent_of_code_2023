import Foundation

print("\nAdvent of Code 2023\n")

let arguments = CommandLine.arguments
let dayNr = arguments[1]

if let aClass = NSClassFromString("AdventOfCode2023.Day\(dayNr)") as? Day.Type {
    let day = aClass.init()
    day.runTests()
    try await day.a()
    try await day.b()
} else {
    print("There is no day \(dayNr) yet!")
}