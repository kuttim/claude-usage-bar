import Foundation

struct Limit {
    let utilization: Double   // 0...100
    let resetsAt: Date?
}

struct Usage {
    let fiveHour: Limit?
    let weekly: Limit?
}

enum UsageError: Error, CustomStringConvertible {
    case noToken, http(Int), badResponse

    var description: String {
        switch self {
        case .noToken: return "No Claude Code login found in Keychain"
        case .http(let code): return "HTTP \(code)"
        case .badResponse: return "Unexpected response"
        }
    }
}

enum UsageClient {
    static func token() throws -> String {
        let p = Process()
        p.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        p.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let out = Pipe()
        p.standardOutput = out
        p.standardError = Pipe()
        try p.run()
        p.waitUntilExit()
        let data = out.fileHandleForReading.readDataToEndOfFile()
        guard p.terminationStatus == 0,
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let oauth = json["claudeAiOauth"] as? [String: Any],
              let token = oauth["accessToken"] as? String
        else { throw UsageError.noToken }
        return token
    }

    static func fetch() async throws -> Usage {
        var req = URLRequest(url: URL(string: "https://api.anthropic.com/api/oauth/usage")!)
        req.setValue("Bearer \(try token())", forHTTPHeaderField: "Authorization")
        req.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        req.timeoutInterval = 15
        let (data, resp) = try await URLSession.shared.data(for: req)
        if let code = (resp as? HTTPURLResponse)?.statusCode, code != 200 { throw UsageError.http(code) }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw UsageError.badResponse
        }
        return Usage(fiveHour: limit(json["five_hour"]) ?? Limit(utilization: 0, resetsAt: nil), weekly: limit(json["seven_day"]))
    }

    private static func limit(_ any: Any?) -> Limit? {
        guard let d = any as? [String: Any], let u = d["utilization"] as? Double else { return nil }
        var date: Date?
        if let s = d["resets_at"] as? String {
            let f = ISO8601DateFormatter()
            f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
            date = f.date(from: s)
            if date == nil {
                f.formatOptions = [.withInternetDateTime]
                date = f.date(from: s)
            }
        }
        return Limit(utilization: u, resetsAt: date)
    }
}

