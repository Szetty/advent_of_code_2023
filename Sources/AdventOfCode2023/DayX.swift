import Foundation

class DayX: Day {
    let filePath = "input/x"

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = f(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = f(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func runTests() {
    }
}