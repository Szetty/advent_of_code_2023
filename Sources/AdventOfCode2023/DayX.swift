import Foundation

class DayX: Day {
    let filePath = "input/x"

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = f("a", lines)
        print(result)
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = f("b", lines)
        print(result)
    }

    func f(_ name: String, _ lines: [String]) -> String {
        "TEST \(name): \(lines.count)"
    }

    func runTests() {
    }
}