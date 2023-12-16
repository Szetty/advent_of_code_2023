import Foundation

class Day11: Day {
    let filePath = "input/11"

    typealias Image = [[Character]]
    struct Coordinate: Equatable {
        let row: Int
        let col: Int
    }
    typealias Expansion = (
        rows: [Int],
        cols: [Int]
    )

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseAndCalculateSumOfDistancesForPairsOfGalaxies(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseAndCalculateSumOfDistancesForPairsOfGalaxiesWithHugeExpansion(lines)
        print("B: \(result)")
    }

    func parseAndCalculateSumOfDistancesForPairsOfGalaxies(_ lines: [String]) -> Int {
        let (_, galaxyCoordinates, expansion: expansion) = parseImageAndExpand(lines)
        return calculateSumOfDistancesForPairsOfGalaxies(galaxyCoordinates, expansion: expansion)
    }

    func parseAndCalculateSumOfDistancesForPairsOfGalaxiesWithHugeExpansion(_ lines: [String]) -> Int {
        let (_, galaxyCoordinates, expansion: expansion) = parseImageAndExpand(lines)
        return calculateSumOfDistancesForPairsOfGalaxies(
            galaxyCoordinates,
            expansion: expansion,
            sizeOfExpansion: 1_000_000
        )
    }

    func calculateSumOfDistancesForPairsOfGalaxies(
        _ galaxyCoordinates: [Coordinate],
        expansion: Expansion,
        sizeOfExpansion: Int = 2
    ) -> Int {
        var distances: [Int] = []

        func calculateExpansionInducedDistance(_ galaxy1: Coordinate, _ galaxy2: Coordinate) -> Int {
            (expansion.rows.filter{
                anyClosedRange(galaxy1.row, galaxy2.row).contains($0)
            }.count + expansion.cols.filter{
                anyClosedRange(galaxy1.col, galaxy2.col).contains($0)
            }.count) * (sizeOfExpansion - 1)
        }

        for i in 0..<galaxyCoordinates.count {
            for j in i+1..<galaxyCoordinates.count {
                distances.append(
                    calculateManhattanDistance(galaxyCoordinates[i], galaxyCoordinates[j]) +
                        calculateExpansionInducedDistance(galaxyCoordinates[i], galaxyCoordinates[j])
                )
            }
        }
        return distances.reduce(0, +)
    }

    func calculateManhattanDistance(_ a: Coordinate, _ b: Coordinate) -> Int {
        abs(a.row - b.row) + abs(a.col - b.col)
    }

    func parseImageAndExpand(_ lines: [String]) -> (
        image: Image,
        galaxyCoordinates: [Coordinate],
        expansion: Expansion
    ) {
        var image: Image = []
        var galaxyCoordinates: [Coordinate] = []
        var rowsToExpand: [Int] = []
        var colsWithGalaxies: [Int: Bool] =
            Dictionary(uniqueKeysWithValues: lines[0].enumerated().map { ($0.offset, false) })

        for rowIdx in 0..<lines.count {
            let row = Array(lines[rowIdx])
            image += [row]
            var rowContainsGalaxy = false
            for colIdx in 0..<row.count {
                if row[colIdx] == "#" {
                    galaxyCoordinates.append(Coordinate(row: rowIdx, col: colIdx))
                    colsWithGalaxies[colIdx] = true
                    rowContainsGalaxy = true
                }
            }
            if !rowContainsGalaxy {
                rowsToExpand.append(rowIdx)
            }
        }

        return (
            image: image,
            galaxyCoordinates: galaxyCoordinates,
            expansion: (
                rows: rowsToExpand,
                cols: colsWithGalaxies.filter{ !$0.value }.keys.sorted()
            )
        )
    }

    func doubleEmptyRows(_ image: Image) -> Image {
        var newImage: Image = []
        for row in image {
            if row.allSatisfy({ $0 == "." }) {
                newImage += [row, row]
            } else {
                newImage += [row]
            }
        }
        return newImage
    }

    func runTests() {
        let example =
            Common.transformToLines(
                """
                ...#......
                .......#..
                #.........
                ..........
                ......#...
                .#........
                .........#
                ..........
                .......#..
                #...#.....
                """
            )

        let (
            image: _,
            galaxyCoordinates: galaxyCoordinates,
            expansion: expansion
        ) = parseImageAndExpand(example)

        assert(
            galaxyCoordinates == [
                Coordinate(row: 0, col: 3),
                Coordinate(row: 1, col: 7),
                Coordinate(row: 2, col: 0),
                Coordinate(row: 4, col: 6),
                Coordinate(row: 5, col: 1),
                Coordinate(row: 6, col: 9),
                Coordinate(row: 8, col: 7),
                Coordinate(row: 9, col: 0),
                Coordinate(row: 9, col: 4),
            ]
        )

        assert(expansion == (rows: [3, 7], cols: [2, 5, 8]))

        assert(calculateSumOfDistancesForPairsOfGalaxies(galaxyCoordinates, expansion: expansion) == 374)

        assert(
            calculateSumOfDistancesForPairsOfGalaxies(galaxyCoordinates, expansion: expansion, sizeOfExpansion: 10) ==
                1030
        )

        assert(
            calculateSumOfDistancesForPairsOfGalaxies(galaxyCoordinates, expansion: expansion, sizeOfExpansion: 100) ==
                8410
        )
    }
}