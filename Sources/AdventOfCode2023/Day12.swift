import Foundation

class Day12: Day {
    let filePath = "input/12"

    required init() {
    }

    typealias ConditionRecord = (springs: Springs, checkSum: CheckSum)
    typealias Springs = String
    typealias CheckSum = [Int]

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseConditionRecordsAndCalculateSumOfPossibleArrangements(lines)
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

    func parseConditionRecordsAndCalculateSumOfPossibleArrangements(_ lines: [String]) -> Int {
        let conditionRecords = parseConditionRecords(lines)
        return conditionRecords.map {
                countOfPossibleArrangements($0)
            }
            .reduce(0, +)
    }

    func countOfPossibleArrangements(_ conditionRecord: ConditionRecord) -> Int {
        let (springs, checkSum) = conditionRecord
        let possibleArrangements = generatePossibleArrangements(springs, checkSum: checkSum)
        return possibleArrangements.count
    }

    private func generatePossibleArrangements(_ springs: Springs, checkSum: CheckSum) -> [Springs] {
        var partialArrangements: [Springs] = [""]
        for spring in springs {
            switch spring {
            case ".", "#":
                partialArrangements = partialArrangements.map {
                    $0 + String(spring)
                }.filter{ validPartialArrangement($0, checkSum: checkSum) }
            case "?":
                partialArrangements = partialArrangements.flatMap({
                    [$0 + ".", $0 + "#"]
                }).filter{ validPartialArrangement($0, checkSum: checkSum) }
            default:
                fatalError("Unknown spring: \(spring)")
            }
        }
        return partialArrangements.filter {
            validArrangement($0, checkSum: checkSum)
        }
    }

    private func validPartialArrangement(_ springs: Springs, checkSum: CheckSum) -> Bool {
        let damageSequenceCounts = computeDamageSequenceCounts(springs)

        return zip(damageSequenceCounts, checkSum)
            .enumerated()
            .allSatisfy { (idx, t) in
                let (damageSequenceCount, checkSum) = t
                if idx == damageSequenceCounts.count - 1 {
                    return damageSequenceCount <= checkSum
                } else {
                    return damageSequenceCount == checkSum
                }
            }
    }

    private func validArrangement(_ springs: Springs, checkSum: CheckSum) -> Bool {
        computeDamageSequenceCounts(springs) == checkSum
    }

    func computeDamageSequenceCounts(_ springs: Springs) -> [Int] {
        var currentDamagedSequence = 0
        var damagedSequenceCounts = [Int]()
        for spring in springs {
            switch spring {
            case ".":
                if currentDamagedSequence > 0 {
                    damagedSequenceCounts.append(currentDamagedSequence)
                    currentDamagedSequence = 0
                }
            case "#":
                currentDamagedSequence += 1
            case "?":
                fatalError("No unknown springs should exist at validation step")
            default:
                fatalError("Unknown spring: \(spring)")
            }
        }

        if currentDamagedSequence > 0 {
            damagedSequenceCounts.append(currentDamagedSequence)
        }

        return damagedSequenceCounts
    }

    func parseConditionRecords(_ lines: [String]) -> [ConditionRecord] {
        lines.map { line in
            let parts = line.components(separatedBy: " ")
            let springs = parts[0]
            let checkSum = parts[1].components(separatedBy: ",").map {
                Int($0)!
            }
            return (springs, checkSum)
        }
    }

    func runTests() {
        let example1 =
            Common.transformToLines(
                """
                ???.### 1,1,3
                .??..??...?##. 1,1,3
                ?#?#?#?#?#?#?#? 1,3,1,6
                ????.#...#... 4,1,1
                ????.######..#####. 1,6,5
                ?###???????? 3,2,1
                """
            )

        let conditionRecords = parseConditionRecords(example1)

        assert(conditionRecords == [
            ("???.###", [1, 1, 3]),
            (".??..??...?##.", [1, 1, 3]),
            ("?#?#?#?#?#?#?#?", [1, 3, 1, 6]),
            ("????.#...#...", [4, 1, 1]),
            ("????.######..#####.", [1, 6, 5]),
            ("?###????????", [3, 2, 1])
        ])

        assert(validArrangement("#.#.###", checkSum: [1, 1, 3]) == true)
        assert(validArrangement("#.#.###", checkSum: [1, 1, 2]) == false)
        assert(validArrangement("#.#.###.", checkSum: [1, 1, 3]) == true)
        assert(validArrangement(".#.###.#.######", checkSum: [1, 3, 1, 6]) == true)
        assert(validArrangement("#....######..#####.", checkSum: [1, 6, 5]) == true)

        assert(countOfPossibleArrangements(("???.###", [1, 1, 3])) == 1)
        assert(countOfPossibleArrangements(("????.######..#####.", [1, 6, 5])) == 4)
        assert(countOfPossibleArrangements(("?###????????", [3, 2, 1])) == 10)
    }
}