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
}