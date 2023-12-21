import Foundation

class Day21: Day {
    let filePath = "input/21"

    struct Map {
        typealias Cell = Character
        typealias Container = [[Cell]]
        var data: Container
        let rows: Int
        let cols: Int

        init(data: Container) {
            self.data = data
            rows = data.count
            cols = data[0].count
        }

        subscript(position: Position) -> Cell {
            data[position.row %% rows][position.col %% cols]
        }
    }

    enum Direction: CaseIterable {
        case north
        case south
        case west
        case east
    }

    struct Position: Equatable, Hashable {
        let row: Int
        let col: Int

        static func +(lhs: Position, rhs: Direction) -> Position {
            lhs + Position.fromDirection(rhs)
        }

        static func +(lhs: Position, rhs: Position) -> Position {
            Position(row: lhs.row + rhs.row, col: lhs.col + rhs.col)
        }

        static func fromDirection(_ direction: Direction) -> Position {
            switch direction {
            case .north:
                return Position(row: -1, col: 0)
            case .south:
                return Position(row: 1, col: 0)
            case .west:
                return Position(row: 0, col: -1)
            case .east:
                return Position(row: 0, col: 1)
            }
        }
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapAndComputeNumberOfGardenPlotsReachableInSteps(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapAndApplyLagrangeInterpolation(lines)
        print("B: \(result)")
    }

    func parseMapAndComputeNumberOfGardenPlotsReachableInSteps(_ lines: [String]) -> Int {
        let (map, startingPosition) = parseMap(lines)
        let (numberOfGardenPlotsReachableInSteps, _) =
            computeNumberOfGardenPlotsReachableInSteps(map, startingPosition: startingPosition, steps: 64)
        return numberOfGardenPlotsReachableInSteps
    }

    func parseMapAndApplyLagrangeInterpolation(_ lines: [String]) -> Int {
        let (map, startingPosition) = parseMap(lines)
        return applyLagrangeInterpolation(map, startingPosition: startingPosition, steps: 26501365)
    }

    func computeNumberOfGardenPlotsReachableInSteps(
        _ map: Map,
        startingPosition: Position,
        steps: Int,
        otherStepsToReport: [Int] = []
    ) -> (finalValue: Int, valueForOtherSteps: [Int: Int]) {
        var currentPositions: Set<Position> = [startingPosition]
        var currentSteps = 0
        var valueForOtherSteps = [Int: Int]()

        while currentSteps < steps {
            currentPositions =
                Set(
                    currentPositions.flatMap { position in
                        Direction
                            .allCases
                            .map {
                                position + $0
                            }
                            .filter { position in
                                map[position] != "#"
                            }
                    })
            currentSteps += 1

            if otherStepsToReport.contains(currentSteps) {
                valueForOtherSteps[currentSteps] = currentPositions.count
            }
        }

        return (currentPositions.count, valueForOtherSteps)
    }

    func applyLagrangeInterpolation(_ map: Map, startingPosition: Position, steps: Int) -> Int {
        /*
         The input has the following specific properties:
         - starting point is in the exact center
         - the edge rows and columns are all open, and the starting point has a straight path to all of them
         These properties ensure that when we reach the edges a diamond will be formed.
         We need to calculate the steps to form the first 3 diamonds.
         First diamond requires half size of the grid to reach, and subsequent ones require full size of the grid.
         y will be the number of reachable garden plots
         x will be the number of steps
        */
        let x1 = map.rows / 2
        let x2 = x1 + map.rows
        let x3 = x2 + map.rows

        let (y3, otherYsByX) = computeNumberOfGardenPlotsReachableInSteps(
            map, startingPosition: startingPosition, steps: x3, otherStepsToReport: [x1, x2]
        )

        let y1 = otherYsByX[x1]!
        let y2 = otherYsByX[x2]!

        let x = steps

        return
            ((x - x2) * (x - x3)) / ((x1 - x2) * (x1 - x3)) * y1 +
            ((x - x1) * (x - x3)) / ((x2 - x1) * (x2 - x3)) * y2 +
            ((x - x1) * (x - x2)) / ((x3 - x1) * (x3 - x2)) * y3
    }

    func parseMap(_ lines: [String]) -> (map: Map, startingPosition: Position) {
        var mapData = Map.Container()
        var startingPosition: Position?

        for row in 0..<lines.count {
            var mapRow = Map.Container.Element()
            for (col, c) in lines[row].enumerated() {
                mapRow.append(c)
                if c == "S" {
                    startingPosition = Position(row: row, col: col)
                }
            }
            mapData.append(mapRow)
        }

        return (Map(data: mapData), startingPosition!)
    }

    func runTests() {
        let example =
            Common.transformToLines(
                """
                ...........
                .....###.#.
                .###.##..#.
                ..#.#...#..
                ....#.#....
                .##..S####.
                .##..#...#.
                .......##..
                .##.#.####.
                .##..##.##.
                ...........
                """
            )

        let (map, startingPosition) = parseMap(example)

        assert(map.rows == 11)
        assert(map.cols == 11)
        assert(startingPosition == Position(row: 5, col: 5))

        assert(
            computeNumberOfGardenPlotsReachableInSteps(map, startingPosition: startingPosition, steps: 1) ==
                (2, [:])
        )
        assert(
            computeNumberOfGardenPlotsReachableInSteps(map, startingPosition: startingPosition, steps: 2) ==
                (4, [:])
        )
        assert(
            computeNumberOfGardenPlotsReachableInSteps(map, startingPosition: startingPosition, steps: 3) ==
                (6, [:])
        )
        assert(
            computeNumberOfGardenPlotsReachableInSteps(map, startingPosition: startingPosition, steps: 6) ==
                (16, [:])
        )
        assert(
            computeNumberOfGardenPlotsReachableInSteps(map, startingPosition: startingPosition, steps: 10) ==
                (50, [:])
        )
        assert(
            computeNumberOfGardenPlotsReachableInSteps(map, startingPosition: startingPosition, steps: 50) ==
                (1594, [:])
        )
    }
}