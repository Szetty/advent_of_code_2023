import Foundation

class Day2: Day {
    let filePath = "input/2"
    let availableRedCubes = 12
    let availableGreenCubes = 13
    let availableBlueCubes = 14

    struct Game: Equatable {
        struct CubeSet: Equatable {
            let red: Int
            let green: Int
            let blue: Int
        }
        let id: Int
        let cubeSets: [CubeSet]
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = sumOfPossibleGameIDs(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = sumOfGamePowers(lines)
        print("B: \(result)")
    }

    func sumOfPossibleGameIDs(_ lines: [String]) -> Int {
        let games = lines.map(parseGame)
        let possibleGames = filterPossibleGames(games: games)
        return possibleGames.map { $0.id }.reduce(0, +)
    }

    func filterPossibleGames(games: [Game]) -> [Game] {
        games.filter { game in
            !game.cubeSets.contains(
                where: { $0.red > availableRedCubes || $0.green > availableGreenCubes || $0.blue > availableBlueCubes}
            )
        }
    }

    func sumOfGamePowers(_ lines: [String]) -> Int {
        let games = lines.map(parseGame)
        return games.map(computePowerForGame).reduce(0, +)
    }

    func computePowerForGame(_ game: Game) -> Int {
        let (red, green, blue) = computeMaximumCubePerColorForGame(game)
        return red * green * blue
    }

    func computeMaximumCubePerColorForGame(_ game: Game) -> (red: Int, green: Int, blue: Int) {
        (
            game.cubeSets.map{ $0.red }.max() ?? 0,
            game.cubeSets.map{ $0.green }.max() ?? 0,
            game.cubeSets.map{ $0.blue }.max() ?? 0
        )
    }

    func parseGame(_ game: String) -> Game {
        func parseCubeSet(_ cubeSet: Substring) -> Game.CubeSet {
            let cubes = cubeSet.split(separator: ",")
            var red = 0
            var green = 0
            var blue = 0
            for cube in cubes {
                let cubeParts = cube.split(separator: " ")
                let value = Int(cubeParts[0])!
                switch cubeParts[1] {
                case "red":
                    red = value
                case "green":
                    green = value
                case "blue":
                    blue = value
                default:
                    fatalError("Undefined cube color")
                }
            }
            return Game.CubeSet(red: red, green: green, blue: blue)
        }

        let parts = game.split(whereSeparator: {$0 == ":" || $0 == ";" })
        let id = Int(parts[0].split(separator: " ")[1])!
        let cubeSets = parts[1...].map { parseCubeSet($0) }
        return Game(id: id, cubeSets: cubeSets)
    }

    func runTests() {
        let testGame = Game(id: 1, cubeSets: [
            Game.CubeSet(red: 4, green: 0, blue: 3),
            Game.CubeSet(red: 1, green: 2, blue: 6),
            Game.CubeSet(red: 0, green: 2, blue: 0),
        ])

        assert(parseGame("Game 1: 3 blue, 4 red; 1 red, 2 green, 6 blue; 2 green") == testGame)

        assert(
            filterPossibleGames(games: [
                testGame,
                Game(id: 2, cubeSets: [
                    Game.CubeSet(red: 1, green: 2, blue: 0),
                    Game.CubeSet(red: 1, green: 3, blue: 4),
                    Game.CubeSet(red: 0, green: 1, blue: 1),
                ]),
                Game(id: 3, cubeSets: [
                    Game.CubeSet(red: 20, green: 8, blue: 6),
                    Game.CubeSet(red: 4, green: 13, blue: 5),
                    Game.CubeSet(red: 1, green: 5, blue: 0),
                ]),
                Game(id: 4, cubeSets: [
                    Game.CubeSet(red: 3, green: 1, blue: 6),
                    Game.CubeSet(red: 0, green: 0, blue: 0),
                    Game.CubeSet(red: 14, green: 3, blue: 15),
                ]),
                Game(id: 5, cubeSets: [
                    Game.CubeSet(red: 1, green: 3, blue: 6),
                    Game.CubeSet(red: 1, green: 2, blue: 0),
                    Game.CubeSet(red: 0, green: 2, blue: 0),
                ]),
            ]).map{ $0.id } == [1, 2, 5]
        )

        assert(computeMaximumCubePerColorForGame(testGame) == (red: 4, green: 2, blue: 6))
        assert(computePowerForGame(testGame) == 48)
    }
}