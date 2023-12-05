import Foundation

class Day5: Day {
    let filePath = "input/5"

    struct Almanac: Equatable {
        typealias Seed = ClosedRange<Int>
        typealias Location = Int

        struct Map: Equatable {
            struct Range: Equatable {
                let destinationRangeStart: Int
                let sourceRangeStart: Int
                let length: Int

                func computeDestination(_ value: Int) -> Int? {
                    if value >= sourceRangeStart && value < sourceRangeStart + length {
                        return destinationRangeStart + value - sourceRangeStart
                    } else {
                        return nil
                    }
                }
            }

            let from: String
            let to: String
            let ranges: [Range]
        }

        var seeds: [Seed]
        var maps: [String: Map]
        let startingMap = "seed"

        func getMinLocationForSeeds() -> Location {
            var currentMap = maps[startingMap]
            var currentValues: [ClosedRange<Int>] = seeds

            while currentMap != nil {
                let map = currentMap!
                currentValues = currentValues.flatMap { range in
                    Almanac.applyMap(range, map: map)
                }
                currentMap = maps[map.to]
            }

            return currentValues.map {
                    $0.lowerBound
                }
                .min()!
        }

        static func applyMap(_ range: ClosedRange<Int>, map: Map) -> [ClosedRange<Int>] {
            var rangesToProcess = [range]
            var processedRanges = [ClosedRange<Int>]()

            while rangesToProcess.count > 0 {
                let range = rangesToProcess.removeLast()
                var newRangeFound = false

                for mapRange in map.ranges {
                    let rangeFromMap = mapRange.sourceRangeStart...mapRange.sourceRangeStart + mapRange.length - 1

                    if range.overlaps(rangeFromMap) {
                        if rangeFromMap.lowerBound <= range.lowerBound && rangeFromMap.upperBound >= range.upperBound {
                            // CASE RMLB...RLB...RUB...RMUB
                            let newStart = mapRange.computeDestination(range.lowerBound)!
                            let newEnd = mapRange.computeDestination(range.upperBound)!
                            processedRanges.append(newStart...newEnd)
                        } else if rangeFromMap.lowerBound > range.lowerBound && rangeFromMap.upperBound >= range.upperBound {
                            // CASE RLB...RMLB...RUB...RMUB
                            let newStart = mapRange.computeDestination(rangeFromMap.lowerBound)!
                            let newEnd = mapRange.computeDestination(range.upperBound)!
                            processedRanges.append(newStart...newEnd)
                            rangesToProcess.append(range.lowerBound...rangeFromMap.lowerBound - 1)
                        } else if rangeFromMap.lowerBound <= range.lowerBound && rangeFromMap.upperBound < range.upperBound {
                            // CASE RMLB...RLB...RMUB...RUB
                            let newStart = mapRange.computeDestination(range.lowerBound)!
                            let newEnd = mapRange.computeDestination(rangeFromMap.upperBound)!
                            processedRanges.append(newStart...newEnd)
                            rangesToProcess.append(rangeFromMap.upperBound + 1...range.upperBound)
                        } else {
                            // CASE RLB...RMLB...RMUB...RUB
                            let newStart = mapRange.computeDestination(rangeFromMap.lowerBound)!
                            let newEnd = mapRange.computeDestination(rangeFromMap.upperBound)!
                            processedRanges.append(newStart...newEnd)
                            rangesToProcess.append(range.lowerBound...rangeFromMap.lowerBound - 1)
                            rangesToProcess.append(rangeFromMap.upperBound + 1...range.upperBound)
                        }

                        newRangeFound = true
                        break
                    }
                }

                if !newRangeFound {
                    processedRanges.append(range)
                }
            }

            return processedRanges
        }
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = try parseAndGetMinimumLocation(lines, seedParser: parseSeedsAsListOfNumbers)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = try parseAndGetMinimumLocation(lines, seedParser: parseSeedsAsRanges)
        print("B: \(result)")
    }

    func parseAndGetMinimumLocation(_ lines: [String], seedParser: (String) -> [ClosedRange<Int>]) throws -> Int {
        (try parseAlmanac(lines, seedParser: seedParser)).getMinLocationForSeeds()
    }

    func parseAlmanac(_ lines: [String], seedParser: (String) -> [ClosedRange<Int>]) throws -> Almanac {
        let mapValuesLineRegex = try Regex(#"[\d+\s]+"#)
        let mapTitleLineRegex = try Regex(#"(\w+)-to-(\w+) map"#)

        var almanac = Almanac(seeds: [], maps: [:])

        var i = 0

        func parseNextMap() throws -> [Almanac.Map.Range] {
            var map: [Almanac.Map.Range] = []
            i += 1
            while try (i < lines.count && mapValuesLineRegex.wholeMatch(in: lines[i]) != nil) {
                let rangeNumbers = lines[i].split(separator: " ").map {
                    Int($0)!
                }
                map.append(
                    Almanac.Map.Range(
                        destinationRangeStart: rangeNumbers[0],
                        sourceRangeStart: rangeNumbers[1],
                        length: rangeNumbers[2]
                    )
                )
                i += 1
            }
            return map
        }

        while i < lines.count {
            let lineParts = lines[i].split(separator: ":")
            switch lineParts[0] {
            case "seeds":
                almanac.seeds = seedParser(String(lineParts[1]))
                i += 1
            case let map where try mapTitleLineRegex.wholeMatch(in: map) != nil:
                let matches = map.matches(of: mapTitleLineRegex).flatMap {
                        $0.output
                    }
                    .map {
                        String($0.substring!)
                    }
                let from = matches[1]

                almanac.maps[from] =
                    Almanac.Map(
                        from: from,
                        to: matches[2],
                        ranges: try parseNextMap()
                    )
            default:
                fatalError("Unknown line \"\(lines[i])\"")
            }
        }

        return almanac
    }

    func parseSeedsAsListOfNumbers(_ seedsString: String) -> [ClosedRange<Int>] {
        seedsString.split(separator: " ").map { seed in
            let seedInt = Int(seed)!
            return seedInt...seedInt
        }
    }

    func parseSeedsAsRanges(_ seedsString: String) -> [ClosedRange<Int>] {
        seedsString
            .split(separator: " ")
            .map {
                Int($0)!
            }
            .chunked(into: 2)
            .compactMap { chunk in
                chunk[0]...chunk[0] + chunk[1] - 1
            }
    }

    func runTests() {
        assert(Almanac.Map.Range(destinationRangeStart: 50, sourceRangeStart: 98, length: 2).computeDestination(98) == 50)
        assert(Almanac.Map.Range(destinationRangeStart: 50, sourceRangeStart: 98, length: 2).computeDestination(99) == 51)
        assert(Almanac.Map.Range(destinationRangeStart: 50, sourceRangeStart: 98, length: 2).computeDestination(100) == nil)

        let exampleAlmanac =
            Almanac(
                seeds: [79...79, 14...14, 55...55, 13...13],
                maps: [
                    "fertilizer": AdventOfCode2023.Day5.Almanac.Map(
                        from: "fertilizer", to: "water",
                        ranges: [
                            Almanac.Map.Range(destinationRangeStart: 49, sourceRangeStart: 53, length: 8),
                            Almanac.Map.Range(destinationRangeStart: 0, sourceRangeStart: 11, length: 42),
                            Almanac.Map.Range(destinationRangeStart: 42, sourceRangeStart: 0, length: 7),
                            Almanac.Map.Range(destinationRangeStart: 57, sourceRangeStart: 7, length: 4)
                        ]
                    ),
                    "seed": Almanac.Map(
                        from: "seed", to: "soil",
                        ranges: [
                            Almanac.Map.Range(destinationRangeStart: 50, sourceRangeStart: 98, length: 2),
                            Almanac.Map.Range(destinationRangeStart: 52, sourceRangeStart: 50, length: 48)
                        ]),
                    "humidity": Almanac.Map(
                        from: "humidity", to: "location",
                        ranges: [
                            Almanac.Map.Range(destinationRangeStart: 60, sourceRangeStart: 56, length: 37),
                            Almanac.Map.Range(destinationRangeStart: 56, sourceRangeStart: 93, length: 4)
                        ]),
                    "light": Almanac.Map(
                        from: "light", to: "temperature",
                        ranges: [
                            Almanac.Map.Range(destinationRangeStart: 45, sourceRangeStart: 77, length: 23),
                            Almanac.Map.Range(destinationRangeStart: 81, sourceRangeStart: 45, length: 19),
                            Almanac.Map.Range(destinationRangeStart: 68, sourceRangeStart: 64, length: 13)
                        ]),
                    "water": Almanac.Map(
                        from: "water", to: "light",
                        ranges: [
                            Almanac.Map.Range(destinationRangeStart: 88, sourceRangeStart: 18, length: 7),
                            Almanac.Map.Range(destinationRangeStart: 18, sourceRangeStart: 25, length: 70)
                        ]),
                    "soil": Almanac.Map(
                        from: "soil", to: "fertilizer",
                        ranges: [
                            Almanac.Map.Range(destinationRangeStart: 0, sourceRangeStart: 15, length: 37),
                            Almanac.Map.Range(destinationRangeStart: 37, sourceRangeStart: 52, length: 2),
                            Almanac.Map.Range(destinationRangeStart: 39, sourceRangeStart: 0, length: 15)
                        ]),
                    "temperature": Almanac.Map(
                        from: "temperature", to: "humidity",
                        ranges: [
                            Almanac.Map.Range(destinationRangeStart: 0, sourceRangeStart: 69, length: 1),
                            Almanac.Map.Range(destinationRangeStart: 1, sourceRangeStart: 0, length: 69)
                        ])
                ]
            )

        let example =
            """
            seeds: 79 14 55 13

            seed-to-soil map:
            50 98 2
            52 50 48

            soil-to-fertilizer map:
            0 15 37
            37 52 2
            39 0 15

            fertilizer-to-water map:
            49 53 8
            0 11 42
            42 0 7
            57 7 4

            water-to-light map:
            88 18 7
            18 25 70

            light-to-temperature map:
            45 77 23
            81 45 19
            68 64 13

            temperature-to-humidity map:
            0 69 1
            1 0 69

            humidity-to-location map:
            60 56 37
            56 93 4
            """

        assert(
            try! parseAlmanac(example.split(separator: "\n").map {
                String($0)
            }, seedParser: parseSeedsAsListOfNumbers)
                == exampleAlmanac
        )

        assert(exampleAlmanac.getMinLocationForSeeds() == 35)

        let anotherExample =
            """
            seeds: 79 2 55 1
            """

        let anotherAlmanac = try! parseAlmanac(
            anotherExample.split(separator: "\n").map {
                String($0)
            },
            seedParser: parseSeedsAsRanges
        )

        assert(anotherAlmanac.seeds == [79...80, 55...55])

        assert(
            Almanac.applyMap(
                1...4,
                map: Almanac.Map(
                    from: "", to: "",
                    ranges: [Almanac.Map.Range(destinationRangeStart: 1, sourceRangeStart: 5, length: 2)]
                )
            ) == [1...4]
        )

        assert(
            Almanac.applyMap(
                6...7,
                map: Almanac.Map(
                    from: "", to: "",
                    ranges: [Almanac.Map.Range(destinationRangeStart: 1, sourceRangeStart: 5, length: 4)]
                )
            ) == [2...3]
        )

        assert(
            Almanac.applyMap(
                4...7,
                map: Almanac.Map(
                    from: "", to: "",
                    ranges: [Almanac.Map.Range(destinationRangeStart: 1, sourceRangeStart: 5, length: 4)]
                )
            ) == [1...3, 4...4]
        )

        assert(
            Almanac.applyMap(
                4...7,
                map: Almanac.Map(
                    from: "", to: "",
                    ranges: [
                        Almanac.Map.Range(destinationRangeStart: 1, sourceRangeStart: 5, length: 4),
                        Almanac.Map.Range(destinationRangeStart: 10, sourceRangeStart: 3, length: 2)
                    ]
                )
            ) == [1...3, 11...11]
        )

        assert(
            Almanac.applyMap(
                7...10,
                map: Almanac.Map(
                    from: "", to: "",
                    ranges: [Almanac.Map.Range(destinationRangeStart: 1, sourceRangeStart: 5, length: 4)]
                )
            ) == [3...4, 9...10]
        )

        assert(
            Almanac.applyMap(
                7...10,
                map: Almanac.Map(
                    from: "", to: "",
                    ranges: [
                        Almanac.Map.Range(destinationRangeStart: 11, sourceRangeStart: 5, length: 4),
                        Almanac.Map.Range(destinationRangeStart: 1, sourceRangeStart: 9, length: 2)
                    ]
                )
            ) == [13...14, 1...2]
        )

        assert(
            Almanac.applyMap(
                1...10,
                map: Almanac.Map(
                    from: "", to: "",
                    ranges: [
                        Almanac.Map.Range(destinationRangeStart: 13, sourceRangeStart: 3, length: 3),
                    ]
                )
            ) == [13...15, 6...10, 1...2]
        )

        assert(
            Almanac.applyMap(
                1...10,
                map: Almanac.Map(
                    from: "", to: "",
                    ranges: [
                        Almanac.Map.Range(destinationRangeStart: 13, sourceRangeStart: 3, length: 3),
                        Almanac.Map.Range(destinationRangeStart: 19, sourceRangeStart: 9, length: 2)
                    ]
                )
            ) == [13...15, 19...20, 6...8, 1...2]
        )
    }
}