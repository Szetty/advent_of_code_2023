import Foundation

class Day10: Day {
    let filePath = "input/10"

    let validNeighbourPipes: [(Int, Int, [Character])] =
        [
            (0, -1, ["-", "L", "F"].map {
                Character($0)
            }),
            (0, 1, ["-", "J", "7"].map {
                Character($0)
            }),
            (-1, 0, ["|", "7", "F"].map {
                Character($0)
            }),
            (1, 0, ["|", "L", "J"].map {
                Character($0)
            }),
        ]


    typealias Grid = [[Character]]
    struct Tile: Equatable, Hashable, Comparable {
        let rowIdx: Int
        let colIdx: Int

        static func +(lhs: Tile, rhs: Tile) -> Tile {
            Tile(rowIdx: lhs.rowIdx + rhs.rowIdx, colIdx: lhs.colIdx + rhs.colIdx)
        }

        static func <(lhs: Day10.Tile, rhs: Day10.Tile) -> Bool {
            lhs.rowIdx < rhs.rowIdx || (lhs.rowIdx == rhs.rowIdx && lhs.colIdx < rhs.colIdx)
        }
    }
    struct Polygon {
        let perimeterTiles: Set<Tile>
        let stepsNeededToBuild: Int
        let minimumRowIdx: Int
        let maximumRowIdx: Int
        let minimumColIdx: Int
        let maximumColIdx: Int
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseAndBuildPolygonAndReturnStepsNeededToBuild(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseAndBuildPolygonAndCountTilesEnclosedInPolygon(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func parseAndBuildPolygonAndReturnStepsNeededToBuild(_ lines: [String]) -> Int {
        let (grid: grid, startingTile: startingTile) = parseGrid(lines)
        let polygon = buildPolygon(grid, startingTile: startingTile!)
        return polygon.stepsNeededToBuild
    }

    func parseAndBuildPolygonAndCountTilesEnclosedInPolygon(_ lines: [String]) -> Int {
        let (grid: grid, startingTile: startingTile) = parseGrid(lines)
        let polygon = buildPolygon(grid, startingTile: startingTile!)
        let enclosedTiles = findTilesEnclosedInPolygon(polygon, grid: grid)
        print(
            enclosedTiles.sorted().map{ ($0.rowIdx, $0.colIdx) }
        )
//        displayPolygon(polygon, grid: grid, enclosedTiles: enclosedTiles)
        return enclosedTiles.count
    }

    private func findTilesEnclosedInPolygon(_ polygon: Polygon, grid: Grid) -> [Tile] {
        var enclosedTiles: [Tile] = []

        enum Axis {
            case row
            case col
        }
        typealias ClosestOutsideTile = (tile: Tile, distance: Int, direction: Tile, axis: Axis)

        func isTileEnclosed(_ tile: Tile) -> Bool {
            func findClosestOutsideTile(_ tile: Tile) -> ClosestOutsideTile {
                [
                    (
                        tile: Tile(rowIdx: polygon.minimumRowIdx - 1, colIdx: tile.colIdx),
                        distance: tile.rowIdx - polygon.minimumRowIdx,
                        direction: Tile(rowIdx: -1, colIdx: 0),
                        axis: .row
                    ),
                    (
                        tile: Tile(rowIdx: polygon.maximumRowIdx + 1, colIdx: tile.colIdx),
                        distance: polygon.maximumRowIdx - tile.rowIdx,
                        direction: Tile(rowIdx: 1, colIdx: 0),
                        axis: .row
                    ),
                    (
                        tile: Tile(rowIdx: tile.rowIdx, colIdx: polygon.minimumColIdx - 1),
                        distance: tile.colIdx - polygon.minimumColIdx,
                        direction: Tile(rowIdx: 0, colIdx: -1),
                        axis: .col
                    ),
                    (
                        tile: Tile(rowIdx: tile.rowIdx, colIdx: polygon.maximumColIdx + 1),
                        distance: polygon.maximumColIdx - tile.colIdx,
                        direction: Tile(rowIdx: 0, colIdx: 1),
                        axis: .col
                    ),
                ]
                    .min (by: { closestOutsideTile1, closestOutsideTile2 in
                        closestOutsideTile1.distance < closestOutsideTile2.distance
                    })!
            }

            func countDirectionChangesUntilOutsideTile(_ closestOutsideTile: ClosestOutsideTile) -> Int {
                enum Direction {
                    case up
                    case down
                    case left
                    case right
                    case anyRow
                    case anyCol
                }

                var previousPerimeterDirection: Direction?
                var count = 0
                var currentTile = tile

                func isTheSameDirectionAsPrevious(_ current: Tile) -> Bool {
                    switch(closestOutsideTile.axis, grid[currentTile.rowIdx][currentTile.colIdx]) {
                    case (.row, "-"):
                        return [.left, .right, .anyCol].contains(previousPerimeterDirection)
                    case (.row, "|"):
                        return false
                    case (.row, "J"):
                        return [.left, .anyCol].contains(previousPerimeterDirection)
                    case (.row, "7"):
                        return [.left, .anyCol].contains(previousPerimeterDirection)
                    case (.row, "L"):
                        return [.right, .anyCol].contains(previousPerimeterDirection)
                    case (.row, "F"):
                        return [.right, .anyCol].contains(previousPerimeterDirection)
                    case (.col, "|"):
                        return [.up, .down, .anyRow].contains(previousPerimeterDirection)
                    case (.col, "-"):
                        return false
                    case (.col, "L"):
                        return [.up, .anyRow].contains(previousPerimeterDirection)
                    case (.col, "J"):
                        return [.up, .anyRow].contains(previousPerimeterDirection)
                    case (.col, "7"):
                        return [.down, .anyRow].contains(previousPerimeterDirection)
                    case (.col, "F"):
                        return [.down, .anyRow].contains(previousPerimeterDirection)
                    default:
                        print(grid[currentTile.rowIdx][currentTile.colIdx])
                        fatalError()
                    }
                }

                func decideOnDirection(pipe: Character) -> Direction? {
                    switch(closestOutsideTile.axis, pipe) {
                    case (.row, "-"):
                        return .anyCol
                    case (.col, "|"):
                        return .anyRow
                    case (.row, "L"):
                        return .right
                    case (.col, "L"):
                        return .up
                    case (.row, "J"):
                        return .left
                    case (.col, "J"):
                        return .up
                    case (.row, "7"):
                        return .left
                    case (.col, "7"):
                        return .down
                    case (.row, "F"):
                        return .right
                    case (.col, "F"):
                        return .down
                    case (.row, "|"):
                        return nil
                    case (.col, "-"):
                        return nil
                    default:
                        print(pipe)
                        fatalError()
                    }
                }

//                print("Start:", tile, closestOutsideTile)

                while currentTile != closestOutsideTile.tile {
                    currentTile = currentTile + closestOutsideTile.direction
//                    print("Loop:", previousPerimeterDirection, currentTile, count)
                    if polygon.perimeterTiles.contains(currentTile) {
                        if previousPerimeterDirection == nil {
                            previousPerimeterDirection = decideOnDirection(
                                pipe: grid[currentTile.rowIdx][currentTile.colIdx]
                            )
                            count += 1
                        } else if isTheSameDirectionAsPrevious(currentTile) {
                            count += 1
                            previousPerimeterDirection = nil
                        }
                    }
                }

                return count
            }

            if polygon.perimeterTiles.contains(tile) {
                return false
            }

            return countDirectionChangesUntilOutsideTile(findClosestOutsideTile(tile)) % 2 == 1
        }

        for rowIdx in polygon.minimumRowIdx...polygon.maximumRowIdx {
            for colIdx in polygon.minimumColIdx...polygon.maximumColIdx {
                if isTileEnclosed(Tile(rowIdx: rowIdx, colIdx: colIdx)) {
                    enclosedTiles += [Tile(rowIdx: rowIdx, colIdx: colIdx)]
                }
            }
        }

        return enclosedTiles
    }

    func buildPolygon(_ grid: Grid, startingTile: Tile) -> Polygon {
        let currentTiles = findConnectedTiles(grid, sourceTile: startingTile)
        assert(currentTiles.count == 2)
        var currentTile1 = currentTiles[0]
        var currentTile2 = currentTiles[1]
        var previousTile1 = startingTile
        var previousTile2 = startingTile

        var steps = 1
        var perimeterTiles: Set<Tile> = [startingTile]
        var minimumRowIdx = startingTile.rowIdx
        var maximumRowIdx = startingTile.rowIdx
        var minimumColIdx = startingTile.colIdx
        var maximumColIdx = startingTile.colIdx

        while (currentTile1 != currentTile2) {
            if currentTile1.rowIdx < minimumRowIdx {
                minimumRowIdx = currentTile1.rowIdx
            }
            if currentTile1.rowIdx > maximumRowIdx {
                maximumRowIdx = currentTile1.rowIdx
            }
            if currentTile1.colIdx < minimumColIdx {
                minimumColIdx = currentTile1.colIdx
            }
            if currentTile1.colIdx > maximumColIdx {
                maximumColIdx = currentTile1.colIdx
            }
            if currentTile2.rowIdx < minimumRowIdx {
                minimumRowIdx = currentTile2.rowIdx
            }
            if currentTile2.rowIdx > maximumRowIdx {
                maximumRowIdx = currentTile2.rowIdx
            }
            if currentTile2.colIdx < minimumColIdx {
                minimumColIdx = currentTile2.colIdx
            }
            if currentTile2.colIdx > maximumColIdx {
                maximumColIdx = currentTile2.colIdx
            }

            perimeterTiles.insert(currentTile1)
            perimeterTiles.insert(currentTile2)
            let nextTile1 = findNextTile(
                currentTile1,
                currentPipe: grid[currentTile1.rowIdx][currentTile1.colIdx],
                previousTile: previousTile1
            )
            let nextTile2 = findNextTile(
                currentTile2,
                currentPipe: grid[currentTile2.rowIdx][currentTile2.colIdx],
                previousTile: previousTile2
            )
            previousTile1 = currentTile1
            previousTile2 = currentTile2
            currentTile1 = nextTile1
            currentTile2 = nextTile2

            steps += 1
        }

        perimeterTiles.insert(currentTile1)

        return Polygon(
            perimeterTiles: perimeterTiles,
            stepsNeededToBuild: steps,
            minimumRowIdx: minimumRowIdx,
            maximumRowIdx: maximumRowIdx,
            minimumColIdx: minimumColIdx,
            maximumColIdx: maximumColIdx
        )
    }

    func findConnectedTiles(_ grid: Grid, sourceTile: Tile) -> [Tile] {
        validNeighbourPipes
            .reduce([], { (acc, element) in
                let (dRow, dCol, validPipes) = element
                let neighbourRowIdx = sourceTile.rowIdx + dRow
                let neighbourColIdx = sourceTile.colIdx + dCol
                let neighbour = grid[safe: neighbourRowIdx]?[safe: neighbourColIdx]
                if neighbour != nil && validPipes.contains(neighbour!) {
                    return acc + [Tile(rowIdx: neighbourRowIdx, colIdx: neighbourColIdx)]
                } else {
                    return acc
                }
            })
    }

    func findNextTile(_ currentTile: Tile, currentPipe: Character, previousTile: Tile) -> Tile {
        switch currentPipe {
        case "-" where currentTile.colIdx > previousTile.colIdx:
            return Tile(rowIdx: previousTile.rowIdx, colIdx: previousTile.colIdx + 2)
        case "-" where currentTile.colIdx < previousTile.colIdx:
            return Tile(rowIdx: previousTile.rowIdx, colIdx: previousTile.colIdx - 2)
        case "|" where currentTile.rowIdx > previousTile.rowIdx:
            return Tile(rowIdx: previousTile.rowIdx + 2, colIdx: previousTile.colIdx)
        case "|" where currentTile.rowIdx < previousTile.rowIdx:
            return Tile(rowIdx: previousTile.rowIdx - 2, colIdx: previousTile.colIdx)
        case "L" where currentTile.rowIdx > previousTile.rowIdx:
            return Tile(rowIdx: previousTile.rowIdx + 1, colIdx: previousTile.colIdx + 1)
        case "L" where currentTile.colIdx < previousTile.colIdx:
            return Tile(rowIdx: previousTile.rowIdx - 1, colIdx: previousTile.colIdx - 1)
        case "J" where currentTile.rowIdx > previousTile.rowIdx:
            return Tile(rowIdx: previousTile.rowIdx + 1, colIdx: previousTile.colIdx - 1)
        case "J" where currentTile.colIdx > previousTile.colIdx:
            return Tile(rowIdx: previousTile.rowIdx - 1, colIdx: previousTile.colIdx + 1)
        case "7" where currentTile.rowIdx < previousTile.rowIdx:
            return Tile(rowIdx: previousTile.rowIdx - 1, colIdx: previousTile.colIdx - 1)
        case "7" where currentTile.colIdx > previousTile.colIdx:
            return Tile(rowIdx: previousTile.rowIdx + 1, colIdx: previousTile.colIdx + 1)
        case "F" where currentTile.rowIdx < previousTile.rowIdx:
            return Tile(rowIdx: previousTile.rowIdx - 1, colIdx: previousTile.colIdx + 1)
        case "F" where currentTile.colIdx < previousTile.colIdx:
            return Tile(rowIdx: previousTile.rowIdx + 1, colIdx: previousTile.colIdx - 1)
        default:
            fatalError("Unknown case for nextTile: \(currentTile), currentPipe: \(currentPipe), previousTile: \(previousTile)")
        }
    }

    func parseGrid(_ lines: [String]) -> (grid: Grid, startingTile: Tile?) {
        var grid: Grid = []
        var startingTile: Tile?
        for (rowIdx, line) in lines.enumerated() {
            var row: [Character] = []
            for (colIdx, char) in line.enumerated() {
                if char == "S" {
                    startingTile = Tile(rowIdx: rowIdx, colIdx: colIdx)
                    // TODO: hardcoded
                    row.append("7")
                } else {
                    row.append(char)
                }
            }
            grid.append(row)
        }
        return (grid, startingTile)
    }

    func displayPolygon(_ polygon: Polygon, grid: Grid, enclosedTiles: [Tile]) {
        var gridToPrint = ""
        for rowIdx in 0..<grid.count {
            for colIdx in 0..<grid[rowIdx].count {
                let tile = Tile(rowIdx: rowIdx, colIdx: colIdx)
                if polygon.perimeterTiles.contains(tile) {
                    gridToPrint += "X"
                } else if enclosedTiles.contains(tile) {
                    gridToPrint += "I"
                } else {
                    gridToPrint += String(grid[rowIdx][colIdx])
                }
            }
            gridToPrint += "\n"
        }
        print(gridToPrint)
    }

    func runTests() {
        let previousTile = Tile(rowIdx: 0, colIdx: 0)

        assert(
            findNextTile(Tile(rowIdx: 0, colIdx: 1), currentPipe: "-", previousTile: previousTile) ==
                Tile(rowIdx: 0, colIdx: 2)
        )
        assert(
            findNextTile(Tile(rowIdx: 0, colIdx: 0), currentPipe: "-", previousTile: Tile(rowIdx: 0, colIdx: 2)) ==
                previousTile
        )
        assert(
            findNextTile(Tile(rowIdx: 1, colIdx: 0), currentPipe: "|", previousTile: previousTile) ==
                Tile(rowIdx: 2, colIdx: 0)
        )
        assert(
            findNextTile(Tile(rowIdx: 1, colIdx: 0), currentPipe: "|", previousTile: Tile(rowIdx: 2, colIdx: 0)) ==
                previousTile
        )
        assert(
            findNextTile(Tile(rowIdx: 1, colIdx: 0), currentPipe: "L", previousTile: previousTile) ==
                Tile(rowIdx: 1, colIdx: 1)
        )
        assert(
            findNextTile(Tile(rowIdx: 1, colIdx: 0), currentPipe: "L", previousTile: Tile(rowIdx: 1, colIdx: 1)) ==
                previousTile
        )
        assert(
            findNextTile(Tile(rowIdx: 1, colIdx: 0), currentPipe: "J", previousTile: previousTile) ==
                Tile(rowIdx: 1, colIdx: -1)
        )
        assert(
            findNextTile(Tile(rowIdx: 1, colIdx: 0), currentPipe: "J", previousTile: Tile(rowIdx: 1, colIdx: -1)) ==
                previousTile
        )
        assert(
            findNextTile(Tile(rowIdx: -1, colIdx: 0), currentPipe: "7", previousTile: previousTile) ==
                Tile(rowIdx: -1, colIdx: -1)
        )
        assert(
            findNextTile(Tile(rowIdx: -1, colIdx: 0), currentPipe: "7", previousTile: Tile(rowIdx: -1, colIdx: -1)) ==
                previousTile
        )
        assert(
            findNextTile(Tile(rowIdx: -1, colIdx: 0), currentPipe: "F", previousTile: previousTile) ==
                Tile(rowIdx: -1, colIdx: 1)
        )
        assert(
            findNextTile(Tile(rowIdx: -1, colIdx: 0), currentPipe: "F", previousTile: Tile(rowIdx: -1, colIdx: 1)) ==
                previousTile
        )

        let example1 =
            Common.transformToLines(
                """
                -L|F7
                7S-7|
                L|7||
                -L-J|
                L|-JF
                """
            )

        let (grid: grid1, startingTile: startingTile1) = parseGrid(example1)
        assert(startingTile1 == Tile(rowIdx: 1, colIdx: 1))
//        assert(grid1[1][1] == "S")
        assert(grid1[0][0] == "-")
        assert(grid1[4][4] == "F")

        assert(
            findConnectedTiles(grid1, sourceTile: Tile(rowIdx: 1, colIdx: 1)) == [
                Tile(rowIdx: 1, colIdx: 2),
                Tile(rowIdx: 2, colIdx: 1)
            ]
        )

        let polygon1 = buildPolygon(grid1, startingTile: startingTile1!)

        assert(polygon1.stepsNeededToBuild == 4)
        assert(polygon1.minimumRowIdx == 1)
        assert(polygon1.minimumColIdx == 1)
        assert(polygon1.maximumRowIdx == 3)
        assert(polygon1.maximumColIdx == 3)

        let example2 =
            Common.transformToLines(
                """
                ..F7.
                .FJ|.
                SJ.L7
                |F--J
                LJ...
                """
            )

        let (grid: grid2, startingTile: startingTile2) = parseGrid(example2)

        assert(startingTile2 == Tile(rowIdx: 2, colIdx: 0))

        let polygon2 = buildPolygon(grid2, startingTile: startingTile2!)

        assert(polygon2.stepsNeededToBuild == 8)
        assert(polygon2.minimumRowIdx == 0)
        assert(polygon2.minimumColIdx == 0)
        assert(polygon2.maximumRowIdx == 4)
        assert(polygon2.maximumColIdx == 4)

        let example3 =
            Common.transformToLines(
                """
                ..........
                .S------7.
                .|F----7|.
                .||OOOO||.
                .||OOOO||.
                .|L-7F-J|.
                .|II||II|.
                .L--JL--J.
                ..........
                """
            )

        assert(parseAndBuildPolygonAndCountTilesEnclosedInPolygon(example3) == 4)

        let example4 =
            Common.transformToLines(
                """
                .F----7F7F7F7F-7....
                .|F--7||||||||FJ....
                .||.FJ||||||||L7....
                FJL7L7LJLJ||LJ.L-7..
                L--J.L7...LJS7F-7L7.
                ....F-J..F7FJ|L7L7L7
                ....L7.F7||L7|.L7L7|
                .....|FJLJ|FJ|F7|.LJ
                ....FJL-7.||.||||...
                ....L---J.LJ.LJLJ...
                """
            )

        assert(parseAndBuildPolygonAndCountTilesEnclosedInPolygon(example4) == 8)

        let example5 =
            Common.transformToLines(
                """
                FF7FSF7F7F7F7F7F---7
                L|LJ||||||||||||F--J
                FL-7LJLJ||||||LJL-77
                F--JF--7||LJLJ7F7FJ-
                L---JF-JLJ.||-FJLJJ7
                |F|F-JF---7F7-L7L|7|
                |FFJF7L7F-JF7|JL---7
                7-L-JL7||F7|L7F-7F7|
                L.L7LFJ|||||FJL7||LJ
                L7JLJL-JLJLJL--JLJ.L
                """
            )

        assert(parseAndBuildPolygonAndCountTilesEnclosedInPolygon(example5) == 10)
    }
}