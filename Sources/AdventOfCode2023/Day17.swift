import Foundation

class Day17: Day {
    let filePath = "input/17"

    struct Map {
        let data: [[Int]]
        let rows: Int
        let cols: Int

        init(data: [[Int]]) {
            self.data = data
            rows = data.count
            cols = data[0].count
        }

        subscript(position: Position) -> Int {
            data[position.row][position.col]
        }

        subscript(row: Int) -> [Int] {
            data[row]
        }

        func withinBounds(position: Position) -> Bool {
            position.row >= 0 && position.row < rows
                && position.col >= 0 && position.col < cols
        }
    }

    struct Position: Equatable, Hashable, Comparable {
        let row: Int
        let col: Int

        static func +(lhs: Position, rhs: Position) -> Position {
            Position(row: lhs.row + rhs.row, col: lhs.col + rhs.col)
        }

        static prefix func -(pos: Position) -> Position {
            Position(row: -pos.row, col: -pos.col)
        }

        static func <(lhs: Position, rhs: Position) -> Bool {
            lhs.row < rhs.row || (lhs.row == rhs.row && lhs.col < rhs.col)
        }

        static func *(lhs: Int, rhs: Position) -> Position {
            Position(row: lhs * rhs.row, col: lhs * rhs.col)
        }
    }

    struct Path: Equatable, Hashable, Comparable {
        let position: Position
        let direction: Position
        let movedSoFarInSameDirection: Int
        let heatLoss: Int

        static func <(lhs: Path, rhs: Path) -> Bool {
            lhs.heatLoss < rhs.heatLoss
                || (lhs.heatLoss == rhs.heatLoss && lhs.position <= rhs.position)
        }
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapAndFindPathWithMinimumHeatLoss(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapAndFindPathWithMinimumHeatLossUsingUltraCrucible(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func parseMapAndFindPathWithMinimumHeatLoss(_ lines: [String]) -> Int {
        findPathWithMinimumHeatLoss(parseMap(lines))
    }

    func parseMapAndFindPathWithMinimumHeatLossUsingUltraCrucible(_ lines: [String]) -> Int {
        findPathWithMinimumHeatLoss(parseMap(lines), maximumMovesInSameDirection: 10, minimumMovesInSameDirection: 4)
    }

    func findPathWithMinimumHeatLoss(
        _ map: Map,
        maximumMovesInSameDirection: Int = 3,
        minimumMovesInSameDirection: Int = 1
    ) -> Int {
        let initialPosition = Position(row: 0, col: 0)
        let initialDirection = Position(row: 0, col: 0)
        let destinationPosition = Position(row: map.rows - 1, col: map.cols - 1)
        let initialPath = Path(
            position: initialPosition,
            direction: initialDirection,
            movedSoFarInSameDirection: 1,
            heatLoss: 0
        )

        var currentPaths = BinaryHeap<Path>(comparator: { $0 < $1 })
        currentPaths.insert(initialPath)

        struct HeatLossesKey: Hashable {
            let direction: Position
            let movedSoFarInSameDirection: Int
        }

        var heatLosses: [Position: [HeatLossesKey: Int]] = [
            initialPosition: [
                HeatLossesKey(direction: initialDirection, movedSoFarInSameDirection: 0): 0
            ]
        ]

        func shouldVisitPath(_ path: Path) -> Bool {
            let key = HeatLossesKey(
                direction: path.direction,
                movedSoFarInSameDirection: path.movedSoFarInSameDirection
            )

            return
                heatLosses[path.position] == nil
                    || path.heatLoss < heatLosses[path.position]![key, default: Int.max]
        }

        while currentPaths.count > 0 {
            let currentPath = currentPaths.pop()!
            let nextPaths = findNextPossiblePaths(
                currentPath, map: map, minimumMovesInSameDirection: minimumMovesInSameDirection
            )

            for nextPath in nextPaths {
                if nextPath.movedSoFarInSameDirection <= maximumMovesInSameDirection
                       && shouldVisitPath(nextPath) {
                    currentPaths.insert(nextPath)
                    let key = HeatLossesKey(
                        direction: nextPath.direction,
                        movedSoFarInSameDirection: nextPath.movedSoFarInSameDirection
                    )

                    heatLosses[nextPath.position, default: [:]][key] = nextPath.heatLoss
                }
            }
        }

        return heatLosses[destinationPosition]!.values.min()!
    }

    func findNextPossiblePaths(_ path: Path, map: Map, minimumMovesInSameDirection: Int) -> [Path] {
        [
            Position(row: -1, col: 0),
            Position(row: 0, col: -1),
            Position(row: 0, col: 1),
            Position(row: 1, col: 0),
        ]
            .map{ newDirection in
                if newDirection == -path.direction {
                    return nil
                }

                if newDirection == path.direction {
                    let newPosition = path.position + newDirection

                    if !map.withinBounds(position: newPosition) {
                        return nil
                    }

                    return Path(
                        position: newPosition,
                        direction: newDirection,
                        movedSoFarInSameDirection: path.movedSoFarInSameDirection + 1,
                        heatLoss: path.heatLoss + map[newPosition]
                    )
                } else {
                    var newPosition = path.position
                    var heatLoss = path.heatLoss

                    for _ in 0..<minimumMovesInSameDirection {
                        newPosition = newPosition + newDirection

                        if !map.withinBounds(position: newPosition) {
                            return nil
                        }

                        heatLoss += map[newPosition]
                    }

                    return Path(
                        position: newPosition,
                        direction: newDirection,
                        movedSoFarInSameDirection: minimumMovesInSameDirection,
                        heatLoss: heatLoss
                    )
                }
            }
            .filter {
                $0 != nil
            }
            .map{
                $0!
            }
    }

    func parseMap(_ lines: [String]) -> Map {
        Map(data: lines.map {
            $0.map {
                Int(String($0))!
            }
        })
    }

    func runTests() {
        assert(
            findNextPossiblePaths(
                Path(
                    position: Position(row: 0, col: 0),
                    direction: Position(row: 0, col: 0),
                    movedSoFarInSameDirection: 1,
                    heatLoss: 0
                ),
                map: parseMap(
                    Common.transformToLines(
                        """
                        24
                        32
                        """
                    )
                ),
                minimumMovesInSameDirection: 1
            ) == [
                Path(
                    position: Position(row: 0, col: 1),
                    direction: Position(row: 0, col: 1),
                    movedSoFarInSameDirection: 1,
                    heatLoss: 4
                ),
                Path(
                    position: Position(row: 1, col: 0),
                    direction: Position(row: 1, col: 0),
                    movedSoFarInSameDirection: 1,
                    heatLoss: 3
                )
            ]
        )

        assert(
            findNextPossiblePaths(
                Path(
                    position: Position(row: 0, col: 0),
                    direction: Position(row: 0, col: 0),
                    movedSoFarInSameDirection: 1,
                    heatLoss: 0
                ),
                map: parseMap(
                    Common.transformToLines(
                        """
                        123
                        456
                        789
                        """
                    )
                ),
                minimumMovesInSameDirection: 2
            ) == [
                Path(
                    position: Position(row: 0, col: 2),
                    direction: Position(row: 0, col: 1),
                    movedSoFarInSameDirection: 2,
                    heatLoss: 5
                ),
                Path(
                    position: Position(row: 2, col: 0),
                    direction: Position(row: 1, col: 0),
                    movedSoFarInSameDirection: 2,
                    heatLoss: 11
                )
            ]
        )

        assert(
            findNextPossiblePaths(
                Path(
                    position: Position(row: 0, col: 2),
                    direction: Position(row: 0, col: 1),
                    movedSoFarInSameDirection: 2,
                    heatLoss: 5
                ),
                map: parseMap(
                    Common.transformToLines(
                        """
                        1234
                        """
                    )
                ),
                minimumMovesInSameDirection: 2
            ) == [
                Path(
                    position: Position(row: 0, col: 3),
                    direction: Position(row: 0, col: 1),
                    movedSoFarInSameDirection: 3,
                    heatLoss: 9
                )
            ]
        )

        let example =
            Common.transformToLines(
                """
                2413432311323
                3215453535623
                3255245654254
                3446585845452
                4546657867536
                1438598798454
                4457876987766
                3637877979653
                4654967986887
                4564679986453
                1224686865563
                2546548887735
                4322674655533
                """
            )

        let map = parseMap(example)

        assert(map.rows == 13)
        assert(map.cols == 13)
        assert(map[0][0] == 2)
        assert(map[0][12] == 3)
        assert(map[12][0] == 4)
        assert(map[12][12] == 3)

        assert(findPathWithMinimumHeatLoss(map) == 102)
        assert(findPathWithMinimumHeatLoss(map, maximumMovesInSameDirection: 10, minimumMovesInSameDirection: 4) == 94)

        let map2 =
            parseMap(
                Common.transformToLines(
                    """
                    111111111111
                    999999999991
                    999999999991
                    999999999991
                    999999999991
                    """
                )
            )

        assert(findPathWithMinimumHeatLoss(map2, maximumMovesInSameDirection: 10, minimumMovesInSameDirection: 4) == 71)
    }
}