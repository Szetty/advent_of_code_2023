import Foundation

class Common {
    static func readLines(filePath: String) async throws -> [String] {
        var lines: [String] = []
        for try await line in URL(fileURLWithPath: filePath).lines {
            lines.append(line)
        }
        return lines
    }

    static func transformToLines(_ string: String) -> [String] {
        string.components(separatedBy: .newlines).filter{ $0 != "" }
    }

    static func transpose<T>(_ array2d: [[T]]) -> [[T]] {
        var transposed: [[T]] = array2d

        // finding transpose of a 2d array by
        // swapping self[x][y] with self[y][x]
        for x in 0..<array2d.count {
            for y in 0..<array2d[x].count {
                transposed[x][y] = array2d[y][x]
                transposed[y][x] = array2d[x][y]
            }
        }

        return transposed
    }
}

extension Array {
    subscript(safe index: Int) -> Element? {
        if index < 0 || index >= count {
            return nil
        }
        return self[index]
    }

    func chunked(into size: Int) -> [[Element]] {
        stride(from: 0, to: count, by: size).map {
            Array(self[$0..<Swift.min($0 + size, count)])
        }
    }
}

extension Array where Element: Comparable {
    static func <(lhs: [Element], rhs: [Element]) -> Bool {
        for i in 0..<Swift.min(lhs.count, rhs.count) {
            if lhs[i] < rhs[i] {
                return true
            } else if lhs[i] > rhs[i] {
                return false
            }
        }
        return lhs.count < rhs.count
    }
}

extension Collection where Self.Iterator.Element: RandomAccessCollection {
    // PRECONDITION: `self` must be rectangular, i.e. every row has equal size.
    func transposed() -> [[Self.Iterator.Element.Iterator.Element]] {
        guard let firstRow = self.first else { return [] }
        return firstRow.indices.map { index in
            self.map{ $0[index] }
        }
    }
}

func anyClosedRange<Bound>(_ a: Bound, _ b: Bound) -> ClosedRange<Bound> {
    if a <= b {
        return a...b
    } else {
        return b...a
    }
}