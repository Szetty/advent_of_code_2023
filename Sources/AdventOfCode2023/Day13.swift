import Foundation

class Day13: Day {
    let filePath = "input/13"

    typealias Map = [[Character]]
    typealias Reflection = (axis: Axis, idx: Int)

    enum Axis {
        case horizontal
        case vertical
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapsAndCalculateSumOfReflections(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseMapsFixSmudgesAndCalculateSumOfReflections(lines)
        print("B: \(result)")
    }

    func parseMapsAndCalculateSumOfReflections(_ lines: [String]) -> Int {
        calculateSumOfReflections(parseMaps(lines))
    }

    func parseMapsFixSmudgesAndCalculateSumOfReflections(_ lines: [String]) -> Int {
        calculateSumOfReflections(parseMaps(lines), hasSmudge: true)
    }

    func calculateSumOfReflections(_ maps: [Map], hasSmudge: Bool = false) -> Int {
        maps.map { map in
                let reflection = findReflection(map, hasSmudge: hasSmudge)
                switch reflection.axis {
                case .horizontal:
                    return reflection.idx * 100
                case .vertical:
                    return reflection.idx

                }
            }
            .reduce(0, +)
    }

    func findReflection(_ map: Map, hasSmudge: Bool = false) -> Reflection {
        if hasSmudge {
            if let idx = findSmudgeAndNewReflectionIdx(map) {
                return (axis: .horizontal, idx: idx)
            }

            return (axis: .vertical, idx: findSmudgeAndNewReflectionIdx(map.transposed())!)
        } else {
            if let idx = findReflectionIdx(map) {
                return (axis: .horizontal, idx: idx)
            }

            return (axis: .vertical, idx: findReflectionIdx(map.transposed())!)
        }
    }

    func findReflectionIdx(_ map: Map) -> Int? {
        for idx in 1...map.count - 1 {
            let rangeToCheck: ClosedRange<Int> = (1...[idx, map.count - idx].min()!)
            if rangeToCheck.count > 0 && rangeToCheck.allSatisfy({
                map[idx - $0] == map[idx + $0 - 1]
            }) {
                return idx
            }
        }
        return nil
    }

    func findSmudgeAndNewReflectionIdx(_ map: Map) -> Int? {
        for rowIdx in 1...map.count - 1 {
            let rangeToCheck: ClosedRange<Int> = (1...[rowIdx, map.count - rowIdx].min()!)
            if rangeToCheck.count > 0 {
                let notMatchingRowOffsets = rangeToCheck.filter({
                    map[rowIdx - $0] != map[rowIdx + $0 - 1]
                })

                if notMatchingRowOffsets.count == 1 {
                    let notMatchingCharacters =
                        zip(map[rowIdx - notMatchingRowOffsets[0]], map[rowIdx + notMatchingRowOffsets[0] - 1])
                            .enumerated()
                            .filter({ $0.element.0 != $0.element.1 })

                    if notMatchingCharacters.count == 1 {
                        return rowIdx
                    }
                }
            }
        }
        return nil
    }

    func parseMaps(_ lines: [String]) -> [Map] {
        var maps = [Map]()
        var currentMap = Map()

        for line in lines {
            if line == "NEXT" {
                maps.append(currentMap)
                currentMap = Map()
            } else {
                currentMap.append(Array(line))
            }
        }

        if currentMap.count > 0 {
            maps.append(currentMap)
        }

        return maps
    }

    func runTests() {
        assert(
            findReflectionIdx(
                Common.transformToLines(
                    """
                    #.#
                    #.#
                    ...
                    """
                ).map {
                    Array($0)
                }
            ) == 1
        )
        assert(
            findReflectionIdx(
                Common.transformToLines(
                    """
                    ...
                    #.#
                    #.#
                    """
                ).map {
                    Array($0)
                }
            ) == 2
        )
        assert(
            findReflectionIdx(
                Common.transformToLines(
                    """
                    ...
                    #.#
                    #.#
                    ...
                    """
                ).map {
                    Array($0)
                }
            ) == 2
        )
        assert(
            findReflectionIdx(
                Common.transformToLines(
                    """
                    ...
                    #.#
                    #.#
                    ...
                    ###
                    """
                ).map {
                    Array($0)
                }
            ) == 2
        )

        assert(
            findSmudgeAndNewReflectionIdx(
                Common.transformToLines(
                    """
                    ...
                    ..#
                    #.#
                    """
                ).map {
                    Array($0)
                }
            )! == 1
        )

        assert(
            findSmudgeAndNewReflectionIdx(
                Common.transformToLines(
                    """
                    #.##..##.
                    ..#.##.#.
                    ##......#
                    ##......#
                    ..#.##.#.
                    ..##..##.
                    #.#.##.#.
                    """
                ).map {
                    Array($0)
                }
            )! == 3
        )

        assert(
            findSmudgeAndNewReflectionIdx(
                Common.transformToLines(
                    """
                    #...##..#
                    #....#..#
                    ..##..###
                    #####.##.
                    #####.##.
                    ..##..###
                    #....#..#
                    """
                ).map {
                    Array($0)
                }
            )! == 1
        )

        let example =
            Common.transformToLines(
                """
                #.##..##.
                ..#.##.#.
                ##......#
                ##......#
                ..#.##.#.
                ..##..##.
                #.#.##.#.
                NEXT
                #...##..#
                #....#..#
                ..##..###
                #####.##.
                #####.##.
                ..##..###
                #....#..#
                """
            )

        let maps = parseMaps(example)

        assert(maps.count == 2)
        assert(maps[0][0] == ["#", ".", "#", "#", ".", ".", "#", "#", "."])
        assert(maps[0].last! == ["#", ".", "#", ".", "#", "#", ".", "#", "."])
        assert(maps[1][0] == ["#", ".", ".", ".", "#", "#", ".", ".", "#"])
        assert(maps[1].last! == ["#", ".", ".", ".", ".", "#", ".", ".", "#"])

        assert(calculateSumOfReflections(maps) == 405)
    }
}