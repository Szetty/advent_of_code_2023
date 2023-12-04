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