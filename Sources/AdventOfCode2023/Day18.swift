import Foundation

class Day18: Day {
    let filePath = "input/18"

    typealias DigPlan = [Dig]

    struct Dig: Equatable {
        let direction: Direction
        let quantity: Int
    }

    enum Direction: String {
        case up = "U"
        case down = "D"
        case left = "L"
        case right = "R"
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

        static func fromDirection(_ direction: Direction) -> Position {
            switch direction {
            case .up:
                return Position(row: -1, col: 0)
            case .down:
                return Position(row: 1, col: 0)
            case .left:
                return Position(row: 0, col: -1)
            case .right:
                return Position(row: 0, col: 1)
            }
        }
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseDigPlanAndDigEdgesAndInteriorAndCountCubicMeters(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseDigPlanFromHexaAndDigEdgesAndInteriorAndCountCubicMeters(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func parseDigPlanAndDigEdgesAndInteriorAndCountCubicMeters(_ lines: [String]) -> Int {
        let edges = digEdges(parseDigPlan(lines))
        let area = calculatePolygonArea(edges)
        return picksTheorem(area: area, edges: edges)
    }

    func parseDigPlanFromHexaAndDigEdgesAndInteriorAndCountCubicMeters(_ lines: [String]) -> Int {
        let edges = digEdges(parseDigPlan(lines, fromHexa: true))
        let area = calculatePolygonArea(edges)
        return picksTheorem(area: area, edges: edges)
    }

    func digEdges(_ digPlan: DigPlan) -> [Position] {
        let initialPosition = Position(row: 0, col: 0)
        var edges: [Position] = [initialPosition]
        var current = initialPosition
        for dig in digPlan {
            current = current + dig.quantity * Position.fromDirection(dig.direction)
            edges.append(current)
        }
        return edges
    }

    func calculatePolygonArea(_ edges: [Position]) -> Double {
        guard edges.count >= 3 else {
            return 0.0
        }

        var area = 0.0
        let n = edges.count

        for i in 0..<n {
            let j = (i + 1) % n
            area += Double(
                edges[i].row * edges[j].col -
                    edges[j].row * edges[i].col
            )
        }

        return abs(area / 2.0)
    }

    func picksTheorem(area: Double, edges: [Position]) -> Int {
        var totalEdgePoints = 1

        for i in 0..<edges.count {
            let j = (i + 1) % edges.count
            totalEdgePoints += abs(edges[i].row - edges[j].row) + abs(edges[i].col - edges[j].col)
        }

        return Int(area + Double(totalEdgePoints / 2) + 1)
    }

    func parseDigPlan(_ lines: [String], fromHexa: Bool = false) -> DigPlan {
        func characterToDirection(_ c: Character) -> Direction {
            switch c {
            case "0":
                return .right
            case "1":
                return .down
            case "2":
                return .left
            case "3":
                return .up
            default:
                fatalError()
            }
        }

        return lines.map { lines in
            let parts = lines.split(separator: " ")
            if fromHexa {
                let hexaString = String(parts[2]).trimmingCharacters(in: CharacterSet(charactersIn: "(#)"))
                let direction = characterToDirection(hexaString.last!)
                let quantity = Int(hexaString.dropLast(), radix: 16)!
                return Dig(direction: direction, quantity: quantity)
            } else {
                let direction = Direction(rawValue: String(parts[0]))!
                let quantity = Int(parts[1])!
                return Dig(direction: direction, quantity: quantity)
            }
        }
    }

    func toMap(_ edges: [Position]) -> [[Character]] {
        var map = [[Character]]()
        var minimumRow = Int.max
        var minimumCol = Int.max
        var maximumRow = Int.min
        var maximumCol = Int.min

        for edge in edges {
            minimumRow = min(minimumRow, edge.row)
            minimumCol = min(minimumCol, edge.col)
            maximumRow = max(maximumRow, edge.row)
            maximumCol = max(maximumCol, edge.col)
        }

        for row in minimumRow...maximumRow {
            var mapRow = [Character]()
            for col in minimumCol...maximumCol {
                let position = Position(row: row, col: col)
                if edges.contains(position) {
                    mapRow.append("#")
                } else {
                    mapRow.append(".")
                }
            }
            map.append(mapRow)
        }

        return map
    }

    func runTests() {
        let example =
            Common.transformToLines(
                """
                R 6 (#70c710)
                D 5 (#0dc571)
                L 2 (#5713f0)
                D 2 (#d2c081)
                R 2 (#59c680)
                D 2 (#411b91)
                L 5 (#8ceee2)
                U 2 (#caa173)
                L 1 (#1b58a2)
                U 2 (#caa171)
                R 2 (#7807d2)
                U 3 (#a77fa3)
                L 2 (#015232)
                U 2 (#7a21e3)
                """
            )

        let digPlan1 = parseDigPlan(example)

        assert(digPlan1.count == 14)
        assert(digPlan1[0] == Dig(direction: .right, quantity: 6))
        assert(digPlan1[1] == Dig(direction: .down, quantity: 5))
        assert(digPlan1[2] == Dig(direction: .left, quantity: 2))
        assert(digPlan1[3] == Dig(direction: .down, quantity: 2))
        assert(digPlan1[4] == Dig(direction: .right, quantity: 2))
        assert(digPlan1[5] == Dig(direction: .down, quantity: 2))
        assert(digPlan1[6] == Dig(direction: .left, quantity: 5))
        assert(digPlan1[7] == Dig(direction: .up, quantity: 2))
        assert(digPlan1[8] == Dig(direction: .left, quantity: 1))
        assert(digPlan1[9] == Dig(direction: .up, quantity: 2))
        assert(digPlan1[10] == Dig(direction: .right, quantity: 2))
        assert(digPlan1[11] == Dig(direction: .up, quantity: 3))
        assert(digPlan1[12] == Dig(direction: .left, quantity: 2))
        assert(digPlan1[13] == Dig(direction: .up, quantity: 2))

        let edges = digEdges(digPlan1)

        assert(
            toMap(edges) ==
                Common.transformToLines(
                    """
                    #.....#
                    .......
                    #.#....
                    .......
                    .......
                    #.#.#.#
                    .......
                    ##..#.#
                    .......
                    .#....#
                    """
                )
                    .map { Array($0) }
        )

        let area = calculatePolygonArea(edges)
        assert(area == 42.0)
        assert(picksTheorem(area: area, edges: edges) == 62)

        let digPlan2 = parseDigPlan(example, fromHexa: true)
        let edges2 = digEdges(digPlan2)

        assert(picksTheorem(area: calculatePolygonArea(edges2), edges: edges2) == 952408144115)
    }
}