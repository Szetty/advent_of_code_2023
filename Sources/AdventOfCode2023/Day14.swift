import Foundation

class Day14: Day {
    let filePath = "input/14"

    typealias Platform = [[Character]]
    typealias Coordinate = (row: Int, col: Int)

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parsePlatformTiltAndCalculateSumOfLoads(lines)
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

    func parsePlatformTiltAndCalculateSumOfLoads(_ lines: [String]) -> Int {
        calculateSumOfLoads(tiltPlatform(parsePlatform(lines)))
    }

    func calculateSumOfLoads(_ platform: Platform) -> Int {
        var sum = 0
        for col in platform {
            for (rowIdx, c) in col.enumerated() {
                if c == "O" {
                    sum += col.count - rowIdx
                }
            }
        }
        return sum
    }

    func tiltPlatform(_ platform: Platform) -> Platform {
        var newPlatform = platform

        func nextRock(_ row: Int, _ col: Int) -> Coordinate? {
            var rockRow = row + 1

            while col < newPlatform.count && rockRow < newPlatform.count {
                if newPlatform[col][rockRow] == "#" {
                    return nil
                }
                if newPlatform[col][rockRow] == "O" {
                    return (rockRow, col)
                }
                rockRow += 1
            }

            return nil
        }

        for col in 0..<newPlatform[0].count {
            for row in (0..<newPlatform.count) {
                let c = newPlatform[col][row]
                switch c {
                case "O", "#":
                    continue
                case ".":
                    if let (nextRockRow, nextRockCol) = nextRock(row, col) {
                        newPlatform[col][row] = "O"
                        newPlatform[nextRockCol][nextRockRow] = "."
                    }
                default:
                    fatalError("Unknown character \(c)")
                }
            }
        }

        return newPlatform
    }

    func parsePlatform(_ lines: [String]) -> Platform {
        lines.map {
                Array($0)
            }
            .transposed()
    }

    func runTests() {
        let example =
            Common.transformToLines(
                """
                O....#....
                O.OO#....#
                .....##...
                OO.#O....O
                .O.....O#.
                O.#..O.#.#
                ..O..#O..O
                .......O..
                #....###..
                #OO..#....
                """
            )

        let platform = parsePlatform(example)

        assert(platform[0][0] == "O")
        assert(platform[0].last == "#")
        assert(platform.last![0] == ".")
        assert(platform.last!.last == ".")

        let tiltedPlatform = tiltPlatform(platform)

        assert(
            tiltedPlatform == parsePlatform(
                Common.transformToLines(
                    """
                    OOOO.#.O..
                    OO..#....#
                    OO..O##..O
                    O..#.OO...
                    ........#.
                    ..#....#.#
                    ..O..#.O.O
                    ..O.......
                    #....###..
                    #....#....
                    """
                )
            )
        )

        assert(calculateSumOfLoads(tiltedPlatform) == 136)
    }
}