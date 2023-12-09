import Foundation

class Day9: Day {
    let filePath = "input/9"

    required init() {
    }

    typealias History = [Int]

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseHistoryAndFindSumOfTheirNextValue(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseHistoryAndFindSumOfTheirPreviousValue(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func parseHistoryAndFindSumOfTheirNextValue(_ lines: [String]) -> Int {
        parseHistories(lines).map { findNextValue($0) }.reduce(0, +)
    }

    func parseHistoryAndFindSumOfTheirPreviousValue(_ lines: [String]) -> Int {
        parseHistories(lines).map { findPreviousValue($0) }.reduce(0, +)
    }

    func findNextValue(_ history: History) -> Int {
        var reverseDifferenceSequences = generateDifferenceSequences(history).reversed().map{ $0 }
        reverseDifferenceSequences[0].append(0)
        for i in 1..<reverseDifferenceSequences.count {
            reverseDifferenceSequences[i].append(
                reverseDifferenceSequences[i].last! + reverseDifferenceSequences[i - 1].last!
            )
        }

        return history.last! + reverseDifferenceSequences.last!.last!
    }

    func findPreviousValue(_ history: History) -> Int {
        var reverseDifferenceSequences = generateDifferenceSequences(history).reversed().map{ $0 }
        reverseDifferenceSequences[0].insert(0, at: 0)
        for i in 1..<reverseDifferenceSequences.count {
            reverseDifferenceSequences[i].insert(
                reverseDifferenceSequences[i][0] - reverseDifferenceSequences[i - 1][0],
                at: 0
            )
        }

        return history[0] - (reverseDifferenceSequences.last!)[0]
    }

    func generateDifferenceSequences(_ history: History) -> [[Int]] {
        var differenceSequences: [[Int]] = []
        var currentDifferenceSequence: [Int] = history

        while !currentDifferenceSequence.allSatisfy({ $0 == 0 }) {
            currentDifferenceSequence = generateDifferenceSequence(numbers: currentDifferenceSequence)
            differenceSequences.append(currentDifferenceSequence)
        }

        return differenceSequences
    }

    func generateDifferenceSequence(numbers: [Int]) -> [Int] {
        var result: [Int] = []
        for i in 1..<numbers.count {
            result.append(numbers[i] - numbers[i - 1])
        }
        return result
    }

    func parseHistories(_ lines: [String]) -> [History] {
        lines.map { line in
            line.components(separatedBy: .whitespaces).map { Int($0)! }
        }
    }

    func runTests() {
        let example =
            Common.transformToLines(
                """
                0 3 6 9 12 15
                1 3 6 10 15 21
                10 13 16 21 30 45
                """
            )

        assert (
            parseHistories(example) == [
                [0, 3, 6, 9, 12, 15],
                [1, 3, 6, 10, 15, 21],
                [10, 13, 16, 21, 30, 45]
            ]
        )

        assert(findNextValue([0, 3, 6, 9, 12, 15]) == 18)
        assert(findNextValue([1, 3, 6, 10, 15, 21]) == 28)
        assert(findNextValue([10, 13, 16, 21, 30, 45]) == 68)

        assert(findPreviousValue([0, 3, 6, 9, 12, 15]) == -3)
        assert(findPreviousValue([1, 3, 6, 10, 15, 21]) == 0)
        assert(findPreviousValue([10, 13, 16, 21, 30, 45]) == 5)
    }
}