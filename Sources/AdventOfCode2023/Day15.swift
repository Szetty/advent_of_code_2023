import Foundation

class Day15: Day {
    let filePath = "input/15"

    typealias Box = [Lens]
    typealias Lens = (name: String, focalLength: Int)

    required init() {
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseStepsAndCalculateSumOfHashes(lines)
        print("A: \(result)")
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let result = parseStepsApplyThemOnBoxesAndCalculateFocusingPower(lines)
        print("B: \(result)")
    }

    func f(_ lines: [String]) -> Int {
        lines.count
    }

    func parseStepsAndCalculateSumOfHashes(_ lines: [String]) -> Int {
        parseSteps(lines)
            .map {
                calculateHash($0)
            }
            .reduce(0, +)
    }

    func parseStepsApplyThemOnBoxesAndCalculateFocusingPower(_ lines: [String]) -> Int {
        var boxes = [Box](repeating: [], count: 256)

        for step in parseSteps(lines) {
            switch step {
            case let removeStep where removeStep.contains("-"):
                let lensName = removeStep.replacingOccurrences(of: "-", with: "")
                let hash = calculateHash(lensName)
                let box = boxes[hash]
                boxes[hash] = box.filter {
                    $0.name != lensName
                }
            case let addStep where addStep.contains("="):
                let addStepComponents = addStep.components(separatedBy: "=")
                let lensName = addStepComponents[0]
                let hash = calculateHash(lensName)
                var box = boxes[hash]
                var lensFound = false
                var lensIdx = 0

                while lensIdx < box.count && !lensFound {
                    if box[lensIdx].name == lensName {
                        lensFound = true
                        box[lensIdx] = (lensName, Int(addStepComponents[1])!)
                    }
                    lensIdx += 1
                }

                if lensFound {
                    boxes[hash] = box
                } else {
                    boxes[hash] = box + [(lensName, Int(addStepComponents[1])!)]
                }
            default:
                fatalError("Unknown step: \(step)")
            }
        }

        return calculateFocusingPower(boxes)
    }

    private func calculateFocusingPower(_ boxes: [Box]) -> Int {
        boxes
            .enumerated()
            .map { (boxIdx, box) in
                box
                    .enumerated()
                    .map { (lensIdx, lens) in
                        (boxIdx + 1) * (lensIdx + 1) * lens.focalLength
                    }
                    .reduce(0, +)
            }
            .reduce(0, +)
    }

    func calculateHash(_ s: String) -> Int {
        var hash = 0
        for c in s {
            hash = (17 * (hash + Int(c.asciiValue!))) % 256
        }
        return hash
    }

    func parseSteps(_ lines: [String]) -> [String] {
        assert(lines.count == 1)
        return lines[0].components(separatedBy: ",")
    }

    func runTests() {
        assert(calculateHash("HASH") == 52)
        assert(calculateHash("rn=1") == 30)
        assert(calculateHash("cm-") == 253)
        assert(calculateHash("qp=3") == 97)
        assert(calculateHash("cm=2") == 47)
        assert(calculateHash("qp-") == 14)
        assert(calculateHash("pc=4") == 180)
        assert(calculateHash("ot=9") == 9)
        assert(calculateHash("ab=5") == 197)
        assert(calculateHash("pc-") == 48)
        assert(calculateHash("pc=6") == 214)
        assert(calculateHash("ot=7") == 231)

        assert(
            parseStepsApplyThemOnBoxesAndCalculateFocusingPower(
                ["rn=1,cm-,qp=3,cm=2,qp-,pc=4,ot=9,ab=5,pc-,pc=6,ot=7"]
            ) == 145
        )
    }
}