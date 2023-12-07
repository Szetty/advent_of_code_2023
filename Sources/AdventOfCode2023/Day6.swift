import Foundation
import RegexBuilder

class Day6: Day {
    let filePath = "input/6"

    struct Race: Equatable {
        let time: Int
        let distance: Int
    }

    struct RaceStrategy: Equatable {
        let speed: Int
        let movingTime: Int
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = calculateProductOfNumberOfRaceStrategiesToWin(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = mathematicallyCalculateNumberOfRaceStrategiesToWinMergedRace(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    private func calculateProductOfNumberOfRaceStrategiesToWin(_ lines: [String]) -> Int {
        parseRaceDocument(lines)
            .map {
                computeRaceStrategiesToWin($0).count
            }
            .reduce(1, *)
    }

    private func calculateNumberOfRaceStrategiesToWinMergedRace(_ lines: [String]) -> Int {
        let races = parseRaceDocument(lines, mergeTimesAndDistances: true)
        assert(races.count == 1)
        let race = races[0]
        print(race)
        return computeRaceStrategiesToWin(race).count
    }

    private func mathematicallyCalculateNumberOfRaceStrategiesToWinMergedRace(_ lines: [String]) -> Int {
        let races = parseRaceDocument(lines, mergeTimesAndDistances: true)
        assert(races.count == 1)
        let race = races[0]

        return solveEquation(Double(race.time), Double(race.distance))
    }

    private func solveEquation(_ t: Double, _ d: Double) -> Int {
        /*
            Equation will look like this
            x + y = t
            x * y = d => y = d / x
            x + d / x = t
            x^2 - t * x + d = 0
            we need to calculate x1, x2 for this 2nd degree equation
            for values in the range x1...x2 we will have x * y >= d
            to calculate the difference square root of delta of the equation is enough
         */
        let a = 1.0
        let b = -t
        let c = d
        let d = b * b - 4 * a * c
        return Int(sqrt(d).rounded(.down))
    }

    func parseRaceDocument(_ lines: [String], mergeTimesAndDistances: Bool = false) -> [Race] {
        assert(lines[0].starts(with: "Time:"))
        assert(lines[1].starts(with: "Distance:"))

        let numberRegex = Regex {
            OneOrMore {
                .digit
            }
        }

        if mergeTimesAndDistances {
            let time = Int(lines[0].matches(of: numberRegex).map {
                    $0.output
                }
                .joined())!
            let distance = Int(lines[1].matches(of: numberRegex).map {
                    $0.output
                }
                .joined())!
            return [Race(time: time, distance: distance)]
        } else {
            let times = lines[0].matches(of: numberRegex).map {
                Int($0.output)!
            }
            let distances = lines[1].matches(of: numberRegex).map {
                Int($0.output)!
            }

            return zip(times, distances).map {
                Race(time: $0.0, distance: $0.1)
            }
        }
    }

    func computeRaceStrategiesToWin(_ race: Race) -> [RaceStrategy] {
        generateAllRaceStrategies(race).filter { strategy in
            strategy.speed * strategy.movingTime > race.distance
        }
    }

    func generateAllRaceStrategies(_ race: Race) -> [RaceStrategy] {
        (1..<race.time).map {
            RaceStrategy(speed: $0, movingTime: race.time - $0)
        }
    }

    func runTests() {
        assert(
            parseRaceDocument(
                """
                Time:      7  15   30
                Distance:  9  40  200
                """
                    .split(separator: "\n")
                    .map {
                        String($0)
                    }
            ) == [
                Race(time: 7, distance: 9),
                Race(time: 15, distance: 40),
                Race(time: 30, distance: 200),
            ]
        )

        assert(
            parseRaceDocument(
                """
                Time:      7  15   30
                Distance:  9  40  200
                """
                    .split(separator: "\n")
                    .map {
                        String($0)
                    },
                mergeTimesAndDistances: true
            ) == [
                Race(time: 71530, distance: 940200)
            ]
        )

        assert(
            generateAllRaceStrategies(Race(time: 2, distance: 0)) == [
                RaceStrategy(speed: 1, movingTime: 1),
            ]
        )

        assert(
            generateAllRaceStrategies(Race(time: 5, distance: 0)) == [
                RaceStrategy(speed: 1, movingTime: 4),
                RaceStrategy(speed: 2, movingTime: 3),
                RaceStrategy(speed: 3, movingTime: 2),
                RaceStrategy(speed: 4, movingTime: 1),
            ]
        )

        assert(
            computeRaceStrategiesToWin(Race(time: 3, distance: 1)) == [
                RaceStrategy(speed: 1, movingTime: 2),
                RaceStrategy(speed: 2, movingTime: 1),
            ]
        )

        assert(
            computeRaceStrategiesToWin(Race(time: 3, distance: 2)) == []
        )

        assert(
            computeRaceStrategiesToWin(Race(time: 7, distance: 9)) == [
                RaceStrategy(speed: 2, movingTime: 5),
                RaceStrategy(speed: 3, movingTime: 4),
                RaceStrategy(speed: 4, movingTime: 3),
                RaceStrategy(speed: 5, movingTime: 2),
            ]
        )

        assert(
            mathematicallyCalculateNumberOfRaceStrategiesToWinMergedRace(
                """
                Time:      7  15   30
                Distance:  9  40  200
                """
                    .split(separator: "\n")
                    .map {
                        String($0)
                    }
            ) == 71503
        )
    }
}