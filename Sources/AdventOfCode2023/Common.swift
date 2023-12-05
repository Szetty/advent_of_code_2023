import Foundation

class Common {
    static func readLines(filePath: String) async throws -> [String] {
        var lines: [String] = []
        for try await line in URL(fileURLWithPath: filePath).lines {
            lines.append(line)
        }
        return lines
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
            Array(self[$0 ..< Swift.min($0 + size, count)])
        }
    }
}