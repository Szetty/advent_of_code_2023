import Foundation
import DequeModule

class Day23: Day {
    let filePath = "input/23"

    struct Map {
        typealias Cell = Character
        typealias Container = [[Cell]]
        let data: Container
        let rows: Int
        let cols: Int

        init(data: Container) {
            self.data = data
            rows = data.count
            cols = data[0].count
        }

        subscript(position: Position) -> Cell {
            data[position.row][position.col]
        }

        func withinBounds(position: Position) -> Bool {
            position.row >= 0 && position.row < rows
                && position.col >= 0 && position.col < cols
        }
    }

    struct Position: Equatable, Hashable {
        let row: Int
        let col: Int

        static func +(lhs: Position, rhs: Position) -> Position {
            Position(row: lhs.row + rhs.row, col: lhs.col + rhs.col)
        }
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapAndComputeLongestPath(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        // This still take a lot of time
        let result = parseMapAndComputeLongestPathTreatingAllAsDots(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func parseMapAndComputeLongestPath(_ lines: [String]) -> Int {
        let (map, startingPosition, endingPosition) = parseMapAndStartingEndingPositions(lines)
        return computeLongestPath(
            map: map,
            startingPosition: startingPosition,
            endingPosition: endingPosition
        )
    }

    func parseMapAndComputeLongestPathTreatingAllAsDots(_ lines: [String]) -> Int {
        let (map, startingPosition, endingPosition) = parseMapAndStartingEndingPositions(lines)
        return computeLongestPath(
            map: map,
            startingPosition: startingPosition,
            endingPosition: endingPosition,
            treatAllAsDots: true
        )
    }

    func computeLongestPath(
        map: Map,
        startingPosition: Position,
        endingPosition: Position,
        treatAllAsDots: Bool = false
    ) -> Int {
        struct PathDelta {
            let position1: Position
            let position2: Position?
            let visitedDelta: Set<Position>
            let lengthDelta: Int

            init(
                position1: Position,
                visitedDelta: Set<Position>,
                lengthDelta: Int = 0,
                position2: Position? = nil
            ) {
                self.position1 = position1
                self.position2 = position2
                self.visitedDelta = visitedDelta
                self.lengthDelta = lengthDelta
            }
        }
        struct Path {
            let visited: Set<Position>
            let currentPosition: Position
            let length: Int
            let singleDecisionPathDelta: PathDelta?
            let previousPosition: Position?

            init(
                currentPosition: Position,
                visited: Set<Position>,
                length: Int = 0,
                singleDecisionPathDelta: PathDelta? = nil,
                previousPosition: Position? = nil
            ) {
                self.currentPosition = currentPosition
                self.visited = visited
                self.length = length
                self.singleDecisionPathDelta = singleDecisionPathDelta
                self.previousPosition = previousPosition
            }
        }

        let initialPath = Path(currentPosition: startingPosition, visited: [startingPosition])
        var currentPaths = Deque<Path>([initialPath])
        var singleDecisionPathDeltas: [Position: PathDelta] = [:]
        var longestPathLength = 0

        while var path = currentPaths.popLast() {
            if path.currentPosition == endingPosition {
                longestPathLength = max(longestPathLength, path.length)
                continue
            }

            if let singleDecisionPathDelta = singleDecisionPathDeltas[path.currentPosition] {
                if singleDecisionPathDelta.visitedDelta.intersection(path.visited) == [path.currentPosition] {
                    path =
                        Path(
                            currentPosition: singleDecisionPathDelta.position2!,
                            visited: path.visited.union(singleDecisionPathDelta.visitedDelta),
                            length: path.length + singleDecisionPathDelta.lengthDelta,
                            singleDecisionPathDelta: nil
                        )
                }
            }

            let nextPositions = buildNextPossiblePositions(
                map: map,
                currentPosition: path.currentPosition,
                treatAllAsDots: treatAllAsDots
            ).filter{ nextPosition in
                    map.withinBounds(position: nextPosition)
                        && map[nextPosition] != "#"
                        && !path.visited.contains(nextPosition)
                }

            var singleDecisionPathDelta: PathDelta? = nil

            if path.singleDecisionPathDelta != nil {
                switch nextPositions.count {
                    case 1:
                        singleDecisionPathDelta =
                            PathDelta(
                                position1: path.singleDecisionPathDelta!.position1,
                                visitedDelta: path.singleDecisionPathDelta!.visitedDelta.union([path.currentPosition]),
                                lengthDelta: path.singleDecisionPathDelta!.lengthDelta + 1
                            )
                    case 0:
                        if singleDecisionPathDeltas[path.singleDecisionPathDelta!.position1] == nil {
                            singleDecisionPathDeltas[path.singleDecisionPathDelta!.position1] =
                                PathDelta(
                                    position1: path.singleDecisionPathDelta!.position1,
                                    visitedDelta: path.singleDecisionPathDelta!.visitedDelta.union([path.currentPosition]),
                                    lengthDelta: path.singleDecisionPathDelta!.lengthDelta + 1,
                                    position2: path.currentPosition
                                )

                            singleDecisionPathDeltas[path.currentPosition] =
                                PathDelta(
                                    position1: path.currentPosition,
                                    visitedDelta: path.singleDecisionPathDelta!.visitedDelta.union([path.currentPosition]),
                                    lengthDelta: path.singleDecisionPathDelta!.lengthDelta + 1,
                                    position2: path.singleDecisionPathDelta!.position1
                                )
                        }

                    default:
                        if singleDecisionPathDeltas[path.singleDecisionPathDelta!.position1] == nil {
                            singleDecisionPathDeltas[path.singleDecisionPathDelta!.position1] =
                                PathDelta(
                                    position1: path.singleDecisionPathDelta!.position1,
                                    visitedDelta: path.singleDecisionPathDelta!.visitedDelta.union([path.previousPosition!]),
                                    lengthDelta: path.singleDecisionPathDelta!.lengthDelta,
                                    position2: path.previousPosition!
                                )

                            singleDecisionPathDeltas[path.previousPosition!] =
                                PathDelta(
                                    position1: path.previousPosition!,
                                    visitedDelta: path.singleDecisionPathDelta!.visitedDelta.union([path.previousPosition!]),
                                    lengthDelta: path.singleDecisionPathDelta!.lengthDelta,
                                    position2: path.singleDecisionPathDelta!.position1
                                )
                        }
                }
            } else {
                if nextPositions.count == 1 {
                    singleDecisionPathDelta =
                        PathDelta(
                            position1: path.currentPosition,
                            visitedDelta: Set<Position>([path.currentPosition])
                        )
                }
            }

            currentPaths.append(contentsOf:
                nextPositions
                .map{ nextPosition in
                    Path(
                        currentPosition: nextPosition,
                        visited: path.visited.union([nextPosition]),
                        length: path.length + 1,
                        singleDecisionPathDelta: singleDecisionPathDelta,
                        previousPosition: path.currentPosition
                    )
                }
            )
        }

        return longestPathLength
    }

    func buildNextPossiblePositions(
        map: Map,
        currentPosition: Position,
        treatAllAsDots: Bool = false
    ) -> [Position] {
        if treatAllAsDots {
            switch map[currentPosition] {
            case ".", "^", ">", "v", "<":
                return [
                    Position(row: -1, col: 0),
                    Position(row: 0, col: -1),
                    Position(row: 0, col: 1),
                    Position(row: 1, col: 0),
                ].map {
                    $0 + currentPosition
                }
            default:
                fatalError("Unknown character \(map[currentPosition]) at \(currentPosition)")
            }
        } else {
            switch map[currentPosition] {
            case "^":
                return [
                    Position(row: currentPosition.row - 1, col: currentPosition.col)
                ]
            case ">":
                return [
                    Position(row: currentPosition.row, col: currentPosition.col + 1)
                ]
            case "v":
                return [
                    Position(row: currentPosition.row + 1, col: currentPosition.col)
                ]
            case "<":
                return [
                    Position(row: currentPosition.row, col: currentPosition.col - 1)
                ]
            case ".":
                return [
                    Position(row: -1, col: 0),
                    Position(row: 0, col: -1),
                    Position(row: 0, col: 1),
                    Position(row: 1, col: 0),
                ].map {
                    $0 + currentPosition
                }
            default:
                fatalError("Unknown character \(map[currentPosition]) at \(currentPosition)")
            }
        }
    }

    func visualizeMap(_ map: Map, visited: Set<Position>) {
        var mapString = ""
        for row in 0..<map.rows {
            for col in 0..<map.cols {
                let position = Position(row: row, col: col)
                if visited.contains(position) {
                    mapString += "O"
                } else {
                    mapString += String(map[position])
                }
            }
            mapString += "\n"
        }
        print(mapString)
    }

    func parseMapAndStartingEndingPositions(_ lines: [String]) -> (
        map: Map,
        startingPosition: Position,
        endingPosition: Position
    ) {
        var map = Map.Container()
        var startingPosition: Position?
        var endingPosition: Position?
        for (rowIdx, line) in lines.enumerated() {
            var row = Map.Container.Element()
            for (colIdx, c) in line.enumerated() {
                row.append(c)
                if rowIdx == 0 && c == "." {
                    startingPosition = Position(row: rowIdx, col: colIdx)
                }
                if rowIdx == lines.count - 1 && c == "." {
                    endingPosition = Position(row: rowIdx, col: colIdx)
                }
            }
            map.append(row)
        }
        return (Map(data: map), startingPosition!, endingPosition!)
    }

    func runTests() {
        let example =
            Common.transformToLines(
                """
                #.#####################
                #.......#########...###
                #######.#########.#.###
                ###.....#.>.>.###.#.###
                ###v#####.#v#.###.#.###
                ###.>...#.#.#.....#...#
                ###v###.#.#.#########.#
                ###...#.#.#.......#...#
                #####.#.#.#######.#.###
                #.....#.#.#.......#...#
                #.#####.#.#.#########v#
                #.#...#...#...###...>.#
                #.#.#v#######v###.###v#
                #...#.>.#...>.>.#.###.#
                #####v#.#.###v#.#.###.#
                #.....#...#...#.#.#...#
                #.#########.###.#.#.###
                #...###...#...#...#.###
                ###.###.#.###v#####v###
                #...#...#.#.>.>.#.>.###
                #.###.###.#.###.#.#v###
                #.....###...###...#...#
                #####################.#
                """
            )

        let (map, startingPosition, endingPosition) = parseMapAndStartingEndingPositions(example)

        assert(map.rows == 23)
        assert(map.cols == 23)
        assert(startingPosition == Position(row: 0, col: 1))
        assert(endingPosition == Position(row: 22, col: 21))

        assert(
            computeLongestPath(
                map: map,
                startingPosition: startingPosition,
                endingPosition: endingPosition
            ) == 94
        )

        assert(
            computeLongestPath(
                map: map,
                startingPosition: startingPosition,
                endingPosition: endingPosition,
                treatAllAsDots: true
            ) == 154
        )
    }
}
