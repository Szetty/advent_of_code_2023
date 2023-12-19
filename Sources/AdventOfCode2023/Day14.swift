import Foundation

class Day14: Day {
    let filePath = "input/14"

    typealias Platform = [[Character]]

    struct Coordinate: Equatable {
        let row: Int
        let col: Int

        static func +(lhs: Coordinate, rhs: Coordinate) -> Coordinate {
            Coordinate(row: lhs.row + rhs.row, col: lhs.col + rhs.col)
        }
    }

    enum TiltDirection: CaseIterable {
        case north, west, south, east
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parsePlatformTiltAndCalculateSumOfLoads(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parsePlatformAndRunCyclesAndCalculateSumOfLoads(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func parsePlatformTiltAndCalculateSumOfLoads(_ lines: [String]) -> Int {
        calculateSumOfLoads(tiltPlatform(parsePlatform(lines)))
    }

    func parsePlatformAndRunCyclesAndCalculateSumOfLoads(_ lines: [String]) -> Int {
        calculateSumOfLoads(runCycles(parsePlatform(lines), cycleCount: 1_000_000_000))
    }

    func calculateSumOfLoads(_ platform: Platform) -> Int {
        var sum = 0
        for (rowIdx, row) in platform.enumerated() {
            for c in row {
                if c == "O" {
                    sum += platform.count - rowIdx
                }
            }
        }
        return sum
    }

    func runCycles(_ platform: Platform, cycleCount: Int = 1) -> Platform {
        var newPlatform = platform
        var visitedPlatformsByPlatform: [Platform: Int] = [
            platform: 0
        ]
        var visitedPlatformsByIndex: [Int: Platform] = [
            0: platform
        ]

        var i = 1

        for _ in 0..<cycleCount {
            for tiltDirection in TiltDirection.allCases {
                newPlatform = tiltPlatform(newPlatform, tiltDirection: tiltDirection)
                if visitedPlatformsByPlatform[newPlatform] != nil {
                    let offset = visitedPlatformsByPlatform[newPlatform]!
                    let index = ((4 * cycleCount - offset) % (i - offset)) + offset
                    return visitedPlatformsByIndex[index]!
                }
                visitedPlatformsByPlatform[newPlatform] = i
                visitedPlatformsByIndex[i] = newPlatform
                i += 1
            }
        }

        return newPlatform
    }

    func tiltPlatform(_ platform: Platform, tiltDirection: TiltDirection = .north) -> Platform {
        let rows = platform.count
        let cols = platform[0].count

        var newPlatform = platform

        func withinBounds(_ coordinate: Coordinate) -> Bool {
            coordinate.row >= 0 && coordinate.row < rows &&
                coordinate.col >= 0 && coordinate.col < cols
        }

        var rockSearchingDirectionCoordinate: Coordinate
        var rowsRange: StrideThrough<Int>
        var colsRange: StrideThrough<Int>

        switch tiltDirection {
        case .north:
            rockSearchingDirectionCoordinate = Coordinate(row: 1, col: 0)
            rowsRange = stride(from: 0, through: rows - 1, by: 1)
            colsRange = stride(from: 0, through: cols - 1, by: 1)
        case .south:
            rowsRange = stride(from: rows - 1, through: 0, by: -1)
            colsRange = stride(from: cols - 1, through: 0, by: -1)
            rockSearchingDirectionCoordinate = Coordinate(row: -1, col: 0)
        case .west:
            rowsRange = stride(from: 0, through: rows - 1, by: 1)
            colsRange = stride(from: 0, through: cols - 1, by: 1)
            rockSearchingDirectionCoordinate = Coordinate(row: 0, col: 1)
        case .east:
            rowsRange = stride(from: rows - 1, through: 0, by: -1)
            colsRange = stride(from: cols - 1, through: 0, by: -1)
            rockSearchingDirectionCoordinate = Coordinate(row: 0, col: -1)
        }

        func nextRock(_ row: Int, _ col: Int) -> Coordinate? {
            var currentCoordinate = Coordinate(row: row, col: col) + rockSearchingDirectionCoordinate

            while withinBounds(currentCoordinate) {
                if newPlatform[currentCoordinate.row][currentCoordinate.col] == "#" {
                    return nil
                }
                if newPlatform[currentCoordinate.row][currentCoordinate.col] == "O" {
                    return currentCoordinate
                }
                currentCoordinate = currentCoordinate + rockSearchingDirectionCoordinate
            }

            return nil
        }

        for row in rowsRange {
            for col in colsRange {
                let c = newPlatform[row][col]
                switch c {
                case "O", "#":
                    continue
                case ".":
                    if let coordinate = nextRock(row, col) {
                        newPlatform[row][col] = "O"
                        newPlatform[coordinate.row][coordinate.col] = "."
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

        assert(platform.count == 10)
        assert(platform[0].count == 10)
        assert(platform[0][0] == "O")
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

        assert(runCycles(platform) == parsePlatform(
            Common.transformToLines(
                """
                .....#....
                ....#...O#
                ...OO##...
                .OO#......
                .....OOO#.
                .O#...O#.#
                ....O#....
                ......OOOO
                #...O###..
                #..OO#....
                """
            )
        ))

        assert(calculateSumOfLoads(runCycles(platform, cycleCount: 1_000_000_000)) == 64)
    }
}