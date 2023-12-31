import Foundation
import SwiftZ3

class Day24: Day {
    let filePath = "input/24"

    typealias HailStones = [HailStone]
    struct HailStone: Equatable {
        let x: Int
        let y: Int
        let z: Int
        let dx: Int
        let dy: Int
        let dz: Int
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseHailStonesAndComputeNumberOfIntersections(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseHailStonesAndFindStartingPointForRockUsingZ3(lines)
        print("B: \(result)")
    }

    func parseHailStonesAndComputeNumberOfIntersections(_ lines: [String]) -> Int {
        let hailStones = parseHailStones(lines)
        return computeNumberOfIntersectionsInTestArea(hailStones, testArea: (200000000000000, 400000000000000))
    }

    func parseHailStonesAndFindStartingPointForRockUsingZ3(_ lines: [String]) -> Int {
        let hailStones = parseHailStones(lines)
        let (x, y, z) = findStartingPointForRockUsingZ3(hailStones)
        return x + y + z
    }

    func computeNumberOfIntersectionsInTestArea(
        _ hailStones: HailStones,
        testArea: (xymin: Int, xymax: Int)
    ) -> Int {
        var intersections = 0

        for i in 0..<hailStones.count {
            for j in i+1..<hailStones.count {
                if let intersection = intersectionPoint(hailStones[i], hailStones[j]) {
                    if intersection.x >= Double(testArea.xymin) && intersection.x <= Double(testArea.xymax) &&
                        intersection.y >= Double(testArea.xymin) && intersection.y <= Double(testArea.xymax) {
                        intersections += 1
                    }
                }
            }
        }

        return intersections
    }

    func findStartingPointForRockUsingZ3(_ hailStones: HailStones) -> (x: Int, y: Int, z: Int) {
        /*
        We need to find the line that intersects with all the lines that describe the
        trajectory of the hail stones.
        If we rely on the fact that such line exists, we only need 3 hailstones to have
        enough equations (9) to solve the system of equations with 9 unknowns.
        In the following we use Z3 and the first 3 hailstones to find x, y, z.
        */
        let config = Z3Config()
        config.setParameter(name: "model", value: "true")

        let context = Z3Context(configuration: config)

        let x: Z3Real = context.makeConstant(name: "x")
        let y: Z3Real = context.makeConstant(name: "y")
        let z: Z3Real = context.makeConstant(name: "z")
        let dx: Z3Real = context.makeConstant(name: "dx")
        let dy: Z3Real = context.makeConstant(name: "dy")
        let dz: Z3Real = context.makeConstant(name: "dz")

        let solver = context.makeSolver()

        for (i, hailStone) in hailStones[0...3].enumerated() {
            let x_i: Z3Real = context.makeIntToReal(context.makeInteger64(Int64(hailStone.x)))
            let y_i: Z3Real = context.makeIntToReal(context.makeInteger64(Int64(hailStone.y)))
            let z_i: Z3Real = context.makeIntToReal(context.makeInteger64(Int64(hailStone.z)))
            let dx_i: Z3Real = context.makeIntToReal(context.makeInteger64(Int64(hailStone.dx)))
            let dy_i: Z3Real = context.makeIntToReal(context.makeInteger64(Int64(hailStone.dy)))
            let dz_i: Z3Real = context.makeIntToReal(context.makeInteger64(Int64(hailStone.dz)))
            let t_i: Z3Real = context.makeConstant(name: "t_\(i)")

            solver.assert(x_i + dx_i * t_i == x + dx * t_i)
            solver.assert(y_i + dy_i * t_i == y + dy * t_i)
            solver.assert(z_i + dz_i * t_i == z + dz * t_i)
        }

        assert(solver.check() == .satisfiable)
        let model = solver.getModel()!

        return (
            Int(model.double(x)),
            Int(model.double(y)),
            Int(model.double(z))
        )
    }

    func intersectionPoint(_ h1: HailStone, _ h2: HailStone) -> (x: Double, y: Double)? {
        let d = Double(h2.dx * h1.dy - h1.dx * h2.dy)
        if d == 0.0 {
            return nil
        }

        let t = Double(h2.dx * (h2.y - h1.y) + h2.dy * (h1.x - h2.x)) / d
        let s = Double(h1.dx * (h2.y - h1.y) + h1.dy * (h1.x - h2.x)) / d

        if t < 0.0 || s < 0.0 {
            return nil
        }

        return (Double(h1.x) + Double(h1.dx) * t, Double(h1.y) + Double(h1.dy) * t)
    }

    func parseHailStones(_ lines: [String]) -> HailStones {
        lines.map { line in
            let parts = line.components(separatedBy: " @ ")
            let positions = parts[0].components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
            let velocities = parts[1].components(separatedBy: ", ").map { $0.trimmingCharacters(in: .whitespaces) }
            return HailStone(
                x: Int(positions[0])!,
                y: Int(positions[1])!,
                z: Int(positions[2])!,
                dx: Int(velocities[0])!,
                dy: Int(velocities[1])!,
                dz: Int(velocities[2])!
            )
        }
    }

    func runTests() {
        func equalDoubleTuples(_ t1: (Double, Double), _ t2: (Double, Double)) -> Bool {
            return abs(t1.0 - t2.0) < 0.0001 && abs(t1.1 - t2.1) < 0.0001
        }

        assert(
            equalDoubleTuples(
                intersectionPoint(
                    HailStone(x: 19, y: 13, z: 30, dx: -2, dy: 1, dz: -2),
                    HailStone(x: 18, y: 19, z: 22, dx: -1, dy: -1, dz: -2)
                )!,
                (43.0 / 3.0, 46.0 / 3.0)
            )
        )

        assert(
            equalDoubleTuples(
                intersectionPoint(
                    HailStone(x: 19, y: 13, z: 30, dx: -2, dy: 1, dz: -2),
                    HailStone(x: 20, y: 25, z: 34, dx: -2, dy: -2, dz: -4)
                )!,
                (35.0 / 3.0, 50.0 / 3.0)
            )
        )

        assert(
            equalDoubleTuples(
                intersectionPoint(
                    HailStone(x: 19, y: 13, z: 30, dx: -2, dy: 1, dz: -2),
                    HailStone(x: 12, y: 31, z: 28, dx: -1, dy: -2, dz: -1)
                )!,
                (6.2, 19.4)
            )
        )

        assert(
            intersectionPoint(
                HailStone(x: 18, y: 19, z: 22, dx: -1, dy: -1, dz: -2),
                HailStone(x: 20, y: 25, z: 34, dx: -2, dy: -2, dz: -4)
            ) == nil
        )

        let example =
            Common.transformToLines(
                """
                19, 13, 30 @ -2,  1, -2
                18, 19, 22 @ -1, -1, -2
                20, 25, 34 @ -2, -2, -4
                12, 31, 28 @ -1, -2, -1
                20, 19, 15 @  1, -5, -3
                """
            )

        let hailStones = parseHailStones(example)

        assert(hailStones.count == 5)
        assert(hailStones[0] == HailStone(x: 19, y: 13, z: 30, dx: -2, dy: 1, dz: -2))
        assert(hailStones[1] == HailStone(x: 18, y: 19, z: 22, dx: -1, dy: -1, dz: -2))
        assert(hailStones[2] == HailStone(x: 20, y: 25, z: 34, dx: -2, dy: -2, dz: -4))
        assert(hailStones[3] == HailStone(x: 12, y: 31, z: 28, dx: -1, dy: -2, dz: -1))
        assert(hailStones[4] == HailStone(x: 20, y: 19, z: 15, dx: 1, dy: -5, dz: -3))

        assert(
            computeNumberOfIntersectionsInTestArea(
                hailStones,
                testArea: (xymin: 7, xymax: 27)
            ) == 2
        )
    }
}
