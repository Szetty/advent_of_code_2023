import Foundation

class Day3: Day {
    let filePath = "input/3"

    struct NumberWithIndices: Equatable, Hashable {
        struct Index: Equatable, Hashable {
            let rowIdx: Int
            let colIdx: Int

            init(_ t: (rowIdx: Int, colIdx: Int)) {
                rowIdx = t.rowIdx
                colIdx = t.colIdx
            }
        }

        let number: Int
        let indices: [Index]

        init(number: Int, indices: [(rowIdx: Int, colIdx: Int)]) {
            self.number = number
            self.indices = indices.map {
                Index($0)
            }
        }
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = computeSumOfPartNumbers(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = computeSumOfGearRatios(lines)
        print("B: \(result)")
    }

    func computeSumOfPartNumbers(_ lines: [String]) -> Int {
        let schematic = lines.map {
            Array($0)
        }
        let partNumbers = findNumbersNextToSymbols(schematic)
        return partNumbers.map {
                $0.number
            }
            .reduce(0, +)
    }

    func computeSumOfGearRatios(_ lines: [String]) -> Int {
        let schematic = lines.map {
            Array($0)
        }
        let partNumbers = findNumbersNextToSymbols(schematic)

        func getPartNumberNeighbours(_ rowIdx: Int, _ colIdx: Int) -> [NumberWithIndices] {
            [
                (rowIdx - 1, colIdx - 1),
                (rowIdx - 1, colIdx),
                (rowIdx - 1, colIdx + 1),
                (rowIdx, colIdx - 1),
                (rowIdx, colIdx + 1),
                (rowIdx + 1, colIdx - 1),
                (rowIdx + 1, colIdx),
                (rowIdx + 1, colIdx + 1),
            ]
                .map { index -> NumberWithIndices? in
                    partNumbers.first(where: { $0.indices.contains(NumberWithIndices.Index(index)) })
                }
                .filter {
                    $0 != nil
                }
                .map {
                    $0!
                }
        }

        var gearRatios: [Int] = []
        for (rowIdx, row) in schematic.enumerated() {
            for (colIdx, cell) in row.enumerated() {
                if cell == "*" {
                    let partNumberNeighbours = Set(getPartNumberNeighbours(rowIdx, colIdx))
                    if partNumberNeighbours.count == 2 {
                        let gearRatio = partNumberNeighbours.map{ $0.number }.reduce(1, *)
                        gearRatios.append(gearRatio)
                    }
                }
            }
        }

        return gearRatios.reduce(0, +)
    }

    func findNumbersNextToSymbols(_ schematic: [[Character]]) -> [NumberWithIndices] {
        var numbers: [NumberWithIndices] = []

        func hasAnySymbolNeighbour(rowIdx: Int, colIdx: Int) -> Bool {
            [
                (rowIdx - 1, colIdx - 1),
                (rowIdx - 1, colIdx),
                (rowIdx - 1, colIdx + 1),
                (rowIdx, colIdx - 1),
                (rowIdx, colIdx + 1),
                (rowIdx + 1, colIdx - 1),
                (rowIdx + 1, colIdx),
                (rowIdx + 1, colIdx + 1),
            ].contains { (rowIdx, colIdx) in
                if let neighbour = schematic[safe: rowIdx]?[safe: colIdx] {
                    return !neighbour.isNumber && neighbour != "."
                } else {
                    return false
                }
            }
        }

        for (rowIdx, row) in schematic.enumerated() {
            var onGoingNumber = ""
            var onGoingIndices: [(rowIdx: Int, colIdx: Int)] = []
            var hadSymbol = false
            for (colIdx, cell) in row.enumerated() {
                if cell.isWholeNumber {
                    onGoingNumber.append(cell)
                    onGoingIndices.append((rowIdx, colIdx))
                    if !hadSymbol && hasAnySymbolNeighbour(rowIdx: rowIdx, colIdx: colIdx) {
                        hadSymbol = true
                    }
                } else {
                    if !onGoingNumber.isEmpty {
                        if hadSymbol {
                            numbers.append(NumberWithIndices(number: Int(onGoingNumber)!, indices: onGoingIndices))
                        }
                        onGoingNumber = ""
                        onGoingIndices = []
                        hadSymbol = false
                    }
                }
            }
            if !onGoingNumber.isEmpty {
                if hadSymbol {
                    numbers.append(NumberWithIndices(number: Int(onGoingNumber)!, indices: onGoingIndices))
                }
                onGoingNumber = ""
                onGoingIndices = []
                hadSymbol = false
            }
        }
        return numbers
    }

    func runTests() {
        let example = """
                      467..114..
                      ...*......
                      ..35...633
                      ......#...
                      617*......
                      .....+.58.
                      ..592.....
                      ......755.
                      ...$.*....
                      .664.598..
                      """
            .split(separator: "\n")
            .map { String($0) }

        assert(findNumbersNextToSymbols(example.map{Array($0)}) == [
            NumberWithIndices(number: 467, indices: [(0, 0), (0, 1), (0, 2)]),
            NumberWithIndices(number: 35, indices: [(2, 2), (2, 3)]),
            NumberWithIndices(number: 633, indices: [(2, 7), (2, 8), (2, 9)]),
            NumberWithIndices(number: 617, indices: [(4, 0), (4, 1), (4, 2)]),
            NumberWithIndices(number: 592, indices: [(6, 2), (6, 3), (6, 4)]),
            NumberWithIndices(number: 755, indices: [(7, 6), (7, 7), (7, 8)]),
            NumberWithIndices(number: 664, indices: [(9, 1), (9, 2), (9, 3)]),
            NumberWithIndices(number: 598, indices: [(9, 5), (9, 6), (9, 7)])
        ])

        assert(computeSumOfGearRatios(example) == 467835)
    }
}