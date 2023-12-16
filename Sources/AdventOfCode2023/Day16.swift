import Foundation

class Day16: Day {
    let filePath = "input/16"

    required init() {
    }

    struct Position: Equatable, Hashable {
        let row: Int
        let col: Int

        static func +(lhs: Position, rhs: Position) -> Position {
            Position(row: lhs.row + rhs.row, col: lhs.col + rhs.col)
        }
    }

    struct Beam: Equatable, Hashable {
        let position: Position
        let direction: Position

        func move() -> Beam {
            Beam(
                position: position + direction,
                direction: direction
            )
        }
    }

    typealias Contraption = [[Character]]

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseContraptionAndSimulateBeamsAndCountEnergizedTiles(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseContraptionAndSimulateBeamFromAnyEdge(lines)
        print("B: \(result)")
    }

    func parseContraptionAndSimulateBeamsAndCountEnergizedTiles(_ lines: [String]) -> Int {
        simulateBeamsAndCountEnergizedTiles(parseContraption(lines))
    }

    func parseContraptionAndSimulateBeamFromAnyEdge(_ lines: [String]) -> Int {
        simulateBeamFromAnyEdge(parseContraption(lines))
    }

    func simulateBeamFromAnyEdge(_ contraption: Contraption) -> Int {
        let rowsCount = contraption.count
        let colsCount = contraption[0].count

        return [
            (0..<colsCount, Position(row: 1, col: 0), ("row", 0)),
            (0..<colsCount, Position(row: -1, col: 0), ("row", rowsCount - 1)),
            (0..<rowsCount, Position(row: 0, col: 1), ("col", 0)),
            (0..<rowsCount, Position(row: 0, col: -1), ("row", colsCount - 1))
        ]
            .flatMap{ (range, direction, rowOrCol) in
                switch rowOrCol.0 {
                case "row":
                    return range.map { col in
                        simulateBeamsAndCountEnergizedTiles(
                            contraption,
                            initialPosition: Position(row: rowOrCol.1, col: col),
                            initialDirection: direction
                        )
                    }
                case "col":
                    return range.map { row in
                        simulateBeamsAndCountEnergizedTiles(
                            contraption,
                            initialPosition: Position(row: row, col: rowOrCol.1),
                            initialDirection: direction
                        )
                    }
                default:
                    fatalError("Unknown rowOrCol \(rowOrCol)")
                }
            }.max()!
    }

    func simulateBeamsAndCountEnergizedTiles(
        _ contraption: Contraption,
        initialPosition: Position = Position(row: 0, col: 0),
        initialDirection: Position = Position(row: 0, col: 1)
    ) -> Int {
        let rowsCount = contraption.count
        let colsCount = contraption[0].count

        var energizedTiles: Set<Position> = [initialPosition]
        let initialBeam = Beam(position: initialPosition, direction: initialDirection)
        var beamsSimulated: Set<Beam> = [initialBeam]
        var currentBeams = [initialBeam]

        while currentBeams.count > 0 {
            currentBeams =
                currentBeams
                .flatMap {
                    moveBeam($0, contraption: contraption)
                }
                .filter {
                    (0..<rowsCount).contains($0.position.row)
                        && (0..<colsCount).contains($0.position.col)
                        && !beamsSimulated.contains($0)
                }

            energizedTiles.formUnion(currentBeams.map { $0.position })
            beamsSimulated.formUnion(currentBeams)
        }

        return energizedTiles.count
    }

    func moveBeam(_ beam: Beam, contraption: Contraption) -> [Beam] {
        switch contraption[beam.position.row][beam.position.col] {
        case ".":
            return [beam.move()]
        case "/":
            switch beam.direction {
            case Position(row: 0, col: 1):
                let newDirection = Position(row: -1, col: 0)
                return [
                    Beam(position: beam.position + newDirection, direction: newDirection)
                ]
            case Position(row: 0, col: -1):
                let newDirection = Position(row: 1, col: 0)
                return [
                    Beam(position: beam.position + newDirection, direction: newDirection)
                ]
            case Position(row: 1, col: 0):
                let newDirection = Position(row: 0, col: -1)
                return [
                    Beam(position: beam.position + newDirection, direction: newDirection)
                ]
            case Position(row: -1, col: 0):
                let newDirection = Position(row: 0, col: 1)
                return [
                    Beam(position: beam.position + newDirection, direction: newDirection)
                ]
            default:
                fatalError("Unknown direction \(beam.direction)")
            }
        case "\\":
            switch beam.direction {
            case Position(row: 0, col: 1):
                let newDirection = Position(row: 1, col: 0)
                return [
                    Beam(position: beam.position + newDirection, direction: newDirection)
                ]
            case Position(row: 0, col: -1):
                let newDirection = Position(row: -1, col: 0)
                return [
                    Beam(position: beam.position + newDirection, direction: newDirection)
                ]
            case Position(row: 1, col: 0):
                let newDirection = Position(row: 0, col: 1)
                return [
                    Beam(position: beam.position + newDirection, direction: newDirection)
                ]
            case Position(row: -1, col: 0):
                let newDirection = Position(row: 0, col: -1)
                return [
                    Beam(position: beam.position + newDirection, direction: newDirection)
                ]
            default:
                fatalError("Unknown direction \(beam.direction)")
            }
        case "|":
            switch beam.direction {
            case Position(row: 0, col: 1):
                let newDirection1 = Position(row: -1, col: 0)
                let newDirection2 = Position(row: 1, col: 0)
                return [
                    Beam(position: beam.position + newDirection1, direction: newDirection1),
                    Beam(position: beam.position + newDirection2, direction: newDirection2)
                ]
            case Position(row: 0, col: -1):
                let newDirection1 = Position(row: -1, col: 0)
                let newDirection2 = Position(row: 1, col: 0)
                return [
                    Beam(position: beam.position + newDirection1, direction: newDirection1),
                    Beam(position: beam.position + newDirection2, direction: newDirection2)
                ]
            case Position(row: 1, col: 0):
                return [beam.move()]
            case Position(row: -1, col: 0):
                return [beam.move()]
            default:
                fatalError("Unknown direction \(beam.direction)")
            }
        case "-":
            switch beam.direction {
            case Position(row: 0, col: 1):
                return [beam.move()]
            case Position(row: 0, col: -1):
                return [beam.move()]
            case Position(row: 1, col: 0):
                let newDirection1 = Position(row: 0, col: -1)
                let newDirection2 = Position(row: 0, col: 1)
                return [
                    Beam(position: beam.position + newDirection1, direction: newDirection1),
                    Beam(position: beam.position + newDirection2, direction: newDirection2)
                ]
            case Position(row: -1, col: 0):
                let newDirection1 = Position(row: 0, col: -1)
                let newDirection2 = Position(row: 0, col: 1)
                return [
                    Beam(position: beam.position + newDirection1, direction: newDirection1),
                    Beam(position: beam.position + newDirection2, direction: newDirection2)
                ]
            default:
                fatalError("Unknown direction \(beam.direction)")
            }
        default:
            fatalError("Unknown character \(contraption[beam.position.row][beam.position.col])")
        }
    }

    func parseContraption(_ lines: [String]) -> Contraption {
        lines.map { Array($0) }
    }

    func runTests() {
        let example =
            Common.transformToLines(
                #"""
                .|...\....
                |.-.\.....
                .....|-...
                ........|.
                ..........
                .........\
                ..../.\\..
                .-.-/..|..
                .|....-|.\
                ..//.|....
                """#
            )

        let parsedContraption = parseContraption(example)
        assert(parsedContraption[0][0] == ".")
        assert(parsedContraption[0][1] == "|")
        assert(parsedContraption[1][4] == #"\"#)

        assert(simulateBeamsAndCountEnergizedTiles(parsedContraption) == 46)
        assert(simulateBeamFromAnyEdge(parsedContraption) == 51)
    }
}