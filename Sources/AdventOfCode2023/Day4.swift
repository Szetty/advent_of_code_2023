import Foundation

class Day4: Day {
    let filePath = "input/4"

    struct Card: Equatable {
        let winningNumbers: [Int]
        let numbers: [Int]
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = compute_scratchcard_score(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = compute_scratchcards_number(lines)
        print("B: \(result)")
    }

    func compute_scratchcard_score(_ lines: [String]) -> Int {
        var score = 0
        for line in lines {
            let card = parseCard(line)
            let count = compute_winner_numbers_count(card)
            score += compute_score(count: count)
        }
        return score
    }

    func compute_scratchcards_number(_ lines: [String]) -> Int {
        var countByCard: [Int: Int] = [:]

        for (idx, line) in lines.enumerated() {
            countByCard[idx, default: 0] += 1

            let card = parseCard(line)
            let count = compute_winner_numbers_count(card)

            if count > 0 {
                for i in 1 ... count {
                    countByCard[idx + i, default: 0] += countByCard[idx]!
                }
            }
        }

        assert(countByCard.keys.max()! == lines.count - 1)

        return countByCard.values.reduce(0, +)
    }

    func parseCard(_ card: String) -> Card {
        let components = card.split(whereSeparator: { $0 == ":" || $0 == "|" })
        assert(components.count == 3)
        let winningNumbers = components[1].split(separator: " ").map {
            Int($0)!
        }
        let numbers = components[2].split(separator: " ").map {
            Int($0)!
        }
        return Card(winningNumbers: winningNumbers, numbers: numbers)
    }

    func compute_winner_numbers_count(_ card: Card) -> Int {
        var count = 0
        for number in card.numbers {
            if card.winningNumbers.contains(number) {
                count += 1
            }
        }
        return count
    }

    func compute_score(count: Int) -> Int {
        count != 0 ? 1 << (count - 1) : 0
    }

    func runTests() {
        assert(
            parseCard("Card 1: 41 48 83 86 17 | 83 86  6 31 17  9 48 53") ==
                Card(winningNumbers: [41, 48, 83, 86, 17], numbers: [83, 86, 6, 31, 17, 9, 48, 53])
        )

        assert(
            compute_winner_numbers_count(
                Card(winningNumbers: [41, 48, 83, 86, 17], numbers: [83, 86, 6, 31, 17, 9, 48, 53])
            ) == 4
        )
        assert(
            compute_winner_numbers_count(
                Card(winningNumbers: [13, 32, 20, 16, 61], numbers: [61, 30, 68, 82, 17, 32, 24, 19])
            ) == 2
        )
        assert(
            compute_winner_numbers_count(
                Card(winningNumbers: [1, 21, 53, 59, 44], numbers: [69, 82, 63, 72, 16, 21, 14, 1])
            ) == 2
        )
        assert(
            compute_winner_numbers_count(
                Card(winningNumbers: [41, 92, 73, 84, 69], numbers: [59, 84, 76, 51, 58, 5, 54, 83])
            ) == 1
        )
        assert(
            compute_winner_numbers_count(
                Card(winningNumbers: [87, 83, 26, 28, 32], numbers: [88, 30, 70, 12, 93, 22, 82, 36])
            ) == 0
        )
        assert(
            compute_winner_numbers_count(
                Card(winningNumbers: [31, 18, 13, 56, 72], numbers: [74, 77, 10, 23, 35, 67, 36, 11])
            ) == 0
        )

        assert(compute_score(count: 0) == 0)
        assert(compute_score(count: 1) == 1)
        assert(compute_score(count: 2) == 2)
        assert(compute_score(count: 3) == 4)
        assert(compute_score(count: 4) == 8)
        assert(compute_score(count: 5) == 16)
    }
}