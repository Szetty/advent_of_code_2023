import Foundation

class Day8: Day {
    let filePath = "input/8"

    required init() {
    }

    typealias Instructions = [Int]
    typealias Network = [String: (String, String)]

    struct Map: Equatable {
        let instructions: Instructions
        let network: Network

        static func ==(lhs: Map, rhs: Map) -> Bool {
            lhs.instructions == rhs.instructions &&
                zip(lhs.network.sorted(by: { $0.key < $1.key }), rhs.network.sorted(by: { $0.key < $1.key }))
                    .allSatisfy { (lhs, rhs) in
                        lhs.key == rhs.key && lhs.value == rhs.value
                    }
        }
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapAndCalculateNumberOfSteps(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapAndQuickCalculateNumberOfSteps(lines)
        print("B: \(result)")
    }

    func parseMapAndCalculateNumberOfSteps(_ lines: [String]) -> Int {
        followInstructionsAndCountNumberOfSteps(parseMap(lines))
    }

    func parseMapAndQuickCalculateNumberOfSteps(_ lines: [String]) -> Int {
        quickCalculateNumberOfSteps(parseMap(lines))
    }

    func followInstructionsAndCountNumberOfSteps(_ map: Map) -> Int {
        var currentNodes = ["AAA"]
        var steps = 0
        while true {
            let instruction = map.instructions[steps % map.instructions.count]
            currentNodes = currentNodes.map { currentNode in
                let (left, right) = map.network[currentNode]!
                return instruction == 0 ? left : right
            }
            steps += 1
            if currentNodes.allSatisfy({ $0.hasSuffix("Z") }) {
                return steps
            }
        }
    }

    func quickCalculateNumberOfSteps(_ map: Map) -> Int {
        var currentNodes = map.network.keys.filter { $0.hasSuffix("A") }
        var firstReachedEndNode: [Int: Int] = [:]
        var steps = 0
        while true {
            let instruction = map.instructions[steps % map.instructions.count]
            currentNodes = currentNodes.enumerated().map { (idx, currentNode) in
                let (left, right) = map.network[currentNode]!
                let newCurrentNode = instruction == 0 ? left : right
                if newCurrentNode.hasSuffix("Z") && firstReachedEndNode[idx] == nil {
                    firstReachedEndNode[idx] = steps + 1
                }
                return newCurrentNode
            }
            steps += 1
            if firstReachedEndNode.count == currentNodes.count {
                return calculateLeastCommonMultiple(firstReachedEndNode.values.map { $0 })
            }
        }
    }

    func calculateLeastCommonMultiple(_ numbers: [Int]) -> Int {
        numbers.reduce(1) { (result, number) in
            result * number / calculateGreatestCommonDivisor(result, number)
        }
    }

    private func calculateGreatestCommonDivisor(_ result: Int, _ number: Int) -> Int {
        if result == 0 {
            return number
        }
        return calculateGreatestCommonDivisor(number % result, result)
    }

    func parseMap(_ lines: [String]) -> Map {
        let instructions = lines[0].split(separator: "").map { instruction in
            switch instruction {
            case "L":
                return 0
            case "R":
                return 1
            default:
                fatalError("Unknown instruction \(instruction)")
            }
        }

        var network: Network = [:]

        for line in lines[1...] {
            let components = line.components(separatedBy: " = ")
            let key = components[0]
            let value = components[1]
            let leftRight = value.trimmingCharacters(in: CharacterSet(charactersIn: "()")).components(separatedBy: ", ")
            network[key] = (leftRight[0], leftRight[1])
        }

        return Map(instructions: instructions, network: network)
    }

    func runTests() {
        let example1 =
            Common.transformToLines(
                """
                RL

                AAA = (BBB, CCC)
                BBB = (DDD, EEE)
                CCC = (ZZZ, GGG)
                DDD = (DDD, DDD)
                EEE = (EEE, EEE)
                GGG = (GGG, GGG)
                ZZZ = (ZZZ, ZZZ)
                """
            )

        let parsedMap1 = parseMap(example1)

        assert(
            parsedMap1 == Map(
                instructions: [1, 0],
                network: [
                    "AAA": ("BBB", "CCC"),
                    "BBB": ("DDD", "EEE"),
                    "CCC": ("ZZZ", "GGG"),
                    "DDD": ("DDD", "DDD"),
                    "EEE": ("EEE", "EEE"),
                    "GGG": ("GGG", "GGG"),
                    "ZZZ": ("ZZZ", "ZZZ"),
                ]
            )
        )

        assert(followInstructionsAndCountNumberOfSteps(parsedMap1) == 2)

        let example2 =
            Common.transformToLines(
                """
                LLR

                AAA = (BBB, BBB)
                BBB = (AAA, ZZZ)
                ZZZ = (ZZZ, ZZZ)
                """
            )

        let parsedMap2 = parseMap(example2)

        assert(
            parsedMap2 == Map(
                instructions: [0, 0, 1],
                network: [
                    "AAA": ("BBB", "BBB"),
                    "BBB": ("AAA", "ZZZ"),
                    "ZZZ": ("ZZZ", "ZZZ"),
                ]
            )
        )

        assert(followInstructionsAndCountNumberOfSteps(parsedMap2) == 6)
    }
}