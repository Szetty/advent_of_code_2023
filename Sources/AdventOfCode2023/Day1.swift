import Foundation
import RegexBuilder

class Day1: Day {
    let filePath = "input/1"

    let numbersAsLetters = "(one)|(two)|(three)|(four)|(five)|(six)|(seven)|(eight)|(nine)"
    let regexDigitOrDigitFromLetters: NSRegularExpression

    required init() {
        regexDigitOrDigitFromLetters = try! NSRegularExpression(pattern: "(\\d)|(?=\(numbersAsLetters))")
    }

    func a() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let sum = sumOfNumberFromLines(lines, lineToDigitsFn: digitsFromLine)
        print(sum)
    }

    func b() async throws {
        let lines = try await Common.readLines(filePath: filePath)
        let sum = sumOfNumberFromLines(lines, lineToDigitsFn: digitsFromLineFromLettersToo)
        print(sum)
    }

    func sumOfNumberFromLines(_ lines: [String], lineToDigitsFn: (String) -> [Int]) -> Int {
        lines.map {
                    numberFromLine(line: $0, lineToDigitsFn: lineToDigitsFn)
                }
                .reduce(0, +)
    }

    func numberFromLine(line: String, lineToDigitsFn: (String) -> [Int]) -> Int {
        let digits = lineToDigitsFn(line)
        switch digits.count {
        case 0:
            return 0
        case 1:
            return digits[0] * 10 + digits[0]
        default:
            return digits[0] * 10 + digits.last!
        }
    }

    func digitsFromLine(line: String) -> [Int] {
        var digits: [Int] = []
        for c in line {
            if let i = Int(String(c)) {
                digits.append(i)
            }
        }
        return digits
    }

    func digitsFromLineFromLettersToo(line: String) -> [Int] {
        let stringRange = NSRange(location: 0, length: line.utf16.count)
        let matches = regexDigitOrDigitFromLetters.matches(in: line, range: stringRange)
        var result: [Int] = []
        for match in matches {
            for rangeIndex in 1 ..< match.numberOfRanges {
                let nsRange = match.range(at: rangeIndex)
                guard !NSEqualRanges(nsRange, NSMakeRange(NSNotFound, 0)) else { continue }
                let string = (line as NSString).substring(with: nsRange)
                switch string {
                case "one": result.append(1)
                case "two": result.append(2)
                case "three": result.append(3)
                case "four": result.append(4)
                case "five": result.append(5)
                case "six": result.append(6)
                case "seven": result.append(7)
                case "eight": result.append(8)
                case "nine": result.append(9)
                default: result.append(Int(string)!)
                }
            }
        }
        return result
    }

    func runTests() {
        assert(digitsFromLine(line: "12ct5a") == [1, 2, 5], "digits are wrong")
        assert(numberFromLine(line: "12ct5a", lineToDigitsFn: digitsFromLine) == 15, "number is wrong")
        assert(numberFromLine(line: "treb7uchet", lineToDigitsFn: digitsFromLine) == 77, "number is wrong")
        assert(numberFromLine(line: "abcdefg", lineToDigitsFn: digitsFromLine) == 0, "number is wrong")
        assert(sumOfNumberFromLines([], lineToDigitsFn: digitsFromLine) == 0, "sum is wrong")
        assert(sumOfNumberFromLines(["11", "2", "33"], lineToDigitsFn: digitsFromLine) == 66, "sum is wrong")
        assert(
                sumOfNumberFromLines(
                        ["1abc2", "pqr3stu8vwx", "a1b2c3d4e5f", "treb7uchet"],
                        lineToDigitsFn: digitsFromLine
                ) == 142,
                "sum is wrong"
        )

        assert(digitsFromLineFromLettersToo(line: "1oneabctwo2") == [1, 1, 2, 2], "digits from letters is wrong")
        assert(digitsFromLineFromLettersToo(line: "4nineeightseven2") == [4, 9, 8, 7, 2], "digits from letters is wrong")
        assert(digitsFromLineFromLettersToo(line: "896") == [8, 9, 6], "digits from letters is wrong")
        assert(digitsFromLineFromLettersToo(line: "zoneight234") == [1, 8, 2, 3, 4], "digits from letters is wrong")
        assert(sumOfNumberFromLines(["4nineeightseven2"], lineToDigitsFn: digitsFromLineFromLettersToo) == 42, "sum is wrong")
        assert(
                sumOfNumberFromLines(
                        [
                            "two1nine",
                            "eightwothree",
                            "abcone2threexyz",
                            "xtwone3four",
                            "4nineeightseven2",
                            "zoneight234",
                            "7pqrstsixteen",
                        ],
                        lineToDigitsFn: digitsFromLineFromLettersToo
                ) == 281,
                "sum is wrong"
        )
    }
}