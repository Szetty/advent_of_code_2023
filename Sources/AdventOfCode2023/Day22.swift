import Foundation
import DequeModule

class Day22: Day {
    let filePath = "input/22"

    typealias BrickID = Int

    struct Brick: Comparable {
        let id: BrickID
        let start: Position
        let end: Position

        let xRange: ClosedRange<Int>
        let yRange: ClosedRange<Int>

        init(id: BrickID, start: Position, end: Position) {
            self.id = id
            self.start = start
            self.end = end
            xRange = start.x...end.x
            yRange = start.y...end.y
        }

        static func <(lhs: Brick, rhs: Brick) -> Bool {
            if lhs.start.z != rhs.start.z {
                return lhs.start.z < rhs.start.z
            }
            if lhs.end.z != rhs.end.z {
                return lhs.end.z < rhs.end.z
            }
            return false
        }

        func updateZ(_ newStartZ: Int) -> Brick {
            Brick(
                id: id,
                start: Position([start.x, start.y, newStartZ]),
                end: Position([end.x, end.y, (end.z - start.z) + newStartZ])
            )
        }
    }

    struct Position: Equatable {
        let x: Int
        let y: Int
        let z: Int

        init(_ xyz: [Int]) {
            x = xyz[0]
            y = xyz[1]
            z = xyz[2]
        }
    }

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseBricksAndSimulateFallingAndComputeNumberOfDisintegrableBricks(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseBricksAndSimulateFallingAndComputeFallingCausedByDisintegratingBricks(lines)
        print("B: \(result)")
    }

    func parseBricksAndSimulateFallingAndComputeNumberOfDisintegrableBricks(_ lines: [String]) -> Int {
        let bricks = parseBricks(lines)
        let (_, supportingBrickIDs) = simulateBricksFallingAndBuildSupportingBrickIDs(bricks)
        return computeNumberOfDisintegrableBricks(supportingBrickIDs)
    }

    func parseBricksAndSimulateFallingAndComputeFallingCausedByDisintegratingBricks(_ lines: [String]) -> Int {
        let bricks = parseBricks(lines)
        let (_, supportingBrickIDs) = simulateBricksFallingAndBuildSupportingBrickIDs(bricks)
        return computeFallingCausedByDisintegratingBricks(supportingBrickIDs)
    }

    func computeNumberOfDisintegrableBricks(_ supportingBrickIDs: [BrickID: [BrickID]]) -> Int {
        let supportedByBrickIDs = buildSupportedByBrickIDs(supportingBrickIDs)

        return supportingBrickIDs.filter { supportingBrickID, supportedBrickIDs in
                supportedBrickIDs.allSatisfy({ supportedBrickID in
                    supportedByBrickIDs[supportedBrickID]!.filter {
                            $0 != supportingBrickID
                        }
                        .count > 0
                })
            }
            .count
    }

    func computeFallingCausedByDisintegratingBricks(_ supportingBrickIDs: [BrickID: [BrickID]]) -> Int {
        let supportedByBrickIDs = buildSupportedByBrickIDs(supportingBrickIDs)

        return supportingBrickIDs.map { supportingBrickID, supportedBrickIDs in
                var fallingBrickIDs = Set([supportingBrickID])
                var supportedBrickIDsToProcess = Deque(supportedBrickIDs)

                while let supportedBrickID = supportedBrickIDsToProcess.popFirst() {
                    if supportedByBrickIDs[supportedBrickID]!.allSatisfy({
                        fallingBrickIDs.contains($0)
                    }) {
                        fallingBrickIDs.insert(supportedBrickID)
                        supportedBrickIDsToProcess += supportingBrickIDs[supportedBrickID]!
                    }
                }

                return fallingBrickIDs.count - 1
            }
            .reduce(0, +)
    }

    func simulateBricksFallingAndBuildSupportingBrickIDs(_ bricks: [Brick]) -> (
        fallenBricks: [Brick], supportingBrickIDs: [BrickID: [BrickID]]
    ) {
        var fallenBricks: [Brick] = []
        var supportingBrickIDs: [BrickID: [BrickID]] = Dictionary(uniqueKeysWithValues: bricks.map {
            ($0.id, [])
        })
        var maximumZ = 0

        func supports(_ brick: Brick, xRange: ClosedRange<Int>, yRange: ClosedRange<Int>) -> Bool {
            brick.xRange.overlaps(xRange) && brick.yRange.overlaps(yRange)
        }

        func supportedByBrickIDs(_ brick: Brick, newZ: Int) -> [BrickID] {
            var supportedByBrickIDs = [BrickID]()
            for fallenBrick in fallenBricks.filter({ $0.end.z == newZ - 1 }) {
                if supports(fallenBrick, xRange: brick.xRange, yRange: brick.yRange) {
                    supportedByBrickIDs.append(fallenBrick.id)
                }
            }
            return supportedByBrickIDs
        }

        for brick in bricks.sorted(by: (<)) {
            var startZ = maximumZ + 1

            while startZ > 1 {
                let supportedByBrickIDs = supportedByBrickIDs(brick, newZ: startZ)

                if supportedByBrickIDs.count > 0 {
                    for brickID in supportedByBrickIDs {
                        supportingBrickIDs[brickID]! += [brick.id]
                    }
                    break
                }

                startZ -= 1
            }
            let fallenBrick = brick.updateZ(startZ)
            fallenBricks.append(fallenBrick)
            maximumZ = max(maximumZ, fallenBrick.end.z)
        }

        return (fallenBricks, supportingBrickIDs)
    }

    func buildSupportedByBrickIDs(_ supportingBrickIDs: [BrickID: [BrickID]]) -> [BrickID: [BrickID]] {
        supportingBrickIDs.reduce([BrickID: [BrickID]](), { acc, supportingBrickIDAndSupportedBrickIDs in
            let (supportingBrickID, supportedBrickIDs) = supportingBrickIDAndSupportedBrickIDs
            var acc = acc
            for supportedBrickID in supportedBrickIDs {
                acc[supportedBrickID, default: []] += [supportingBrickID]
            }
            return acc
        })
    }

    func parseBricks(_ lines: [String]) -> [Brick] {
        var bricks = [Brick]()
        var id = 0
        for line in lines {
            let parts = line.split(separator: "~")
            let start = Position(parts[0].split(separator: ",").map {
                Int($0)!
            })
            let end = Position(parts[1].split(separator: ",").map {
                Int($0)!
            })
            bricks.append(Brick(id: id, start: start, end: end))
            id += 1
        }
        return bricks
    }

    func runTests() {
        let example =
            Common.transformToLines(
                """
                1,0,1~1,2,1
                0,0,2~2,0,2
                0,2,3~2,2,3
                0,0,4~0,2,4
                2,0,5~2,2,5
                0,1,6~2,1,6
                1,1,8~1,1,9
                """
            )

        let bricks = parseBricks(example)

        assert(bricks.count == 7)
        assert(bricks[0] == Brick(id: 0, start: Position([1, 0, 1]), end: Position([1, 2, 1])))
        assert(bricks[1] == Brick(id: 1, start: Position([0, 0, 2]), end: Position([2, 0, 2])))
        assert(bricks[2] == Brick(id: 2, start: Position([0, 2, 3]), end: Position([2, 2, 3])))
        assert(bricks[3] == Brick(id: 3, start: Position([0, 0, 4]), end: Position([0, 2, 4])))
        assert(bricks[4] == Brick(id: 4, start: Position([2, 0, 5]), end: Position([2, 2, 5])))
        assert(bricks[5] == Brick(id: 5, start: Position([0, 1, 6]), end: Position([2, 1, 6])))
        assert(bricks[6] == Brick(id: 6, start: Position([1, 1, 8]), end: Position([1, 1, 9])))

        let (fallenBricks, supportingBrickIDs) = simulateBricksFallingAndBuildSupportingBrickIDs(bricks)

        assert(
            fallenBricks == [
                Brick(id: 0, start: Position([1, 0, 1]), end: Position([1, 2, 1])),
                Brick(id: 1, start: Position([0, 0, 2]), end: Position([2, 0, 2])),
                Brick(id: 2, start: Position([0, 2, 2]), end: Position([2, 2, 2])),
                Brick(id: 3, start: Position([0, 0, 3]), end: Position([0, 2, 3])),
                Brick(id: 4, start: Position([2, 0, 3]), end: Position([2, 2, 3])),
                Brick(id: 5, start: Position([0, 1, 4]), end: Position([2, 1, 4])),
                Brick(id: 6, start: Position([1, 1, 5]), end: Position([1, 1, 6])),
            ]
        )

        assert(
            supportingBrickIDs == [5: [6], 2: [3, 4], 0: [1, 2], 3: [5], 1: [3, 4], 4: [5], 6: []]
        )

        assert(computeNumberOfDisintegrableBricks(supportingBrickIDs) == 5)

        assert(computeFallingCausedByDisintegratingBricks(supportingBrickIDs) == 7)
    }
}
