import Foundation
import ScreenshotSweeperCore

@main
struct ScreenshotSweeper {
    static func main() async {
        do {
            let options = try CLI.parse(Array(CommandLine.arguments.dropFirst()))

            if options.help {
                print(CLI.usage)
                return
            }

            let policy = RetentionPolicy(days: options.retention, calendar: .current, now: Date())
            let client = PhotoLibraryClient()

            try await client.requestAccess()

            let candidates = client.fetchScreenshots(olderThan: policy, limit: options.limit)
            printSummary(candidates: candidates, policy: policy, dryRun: options.dryRun)

            guard options.dryRun == false else {
                print("Dry run only. Re-run with --delete to move these screenshots to Recently Deleted.")
                return
            }

            guard candidates.isEmpty == false else {
                return
            }

            if options.assumeYes == false && confirmDeletion(count: candidates.count) == false {
                print("Deletion cancelled.")
                return
            }

            try await client.deleteAssets(with: candidates.map(\.localIdentifier))
            print("Moved \(candidates.count) screenshot\(candidates.count == 1 ? "" : "s") to Recently Deleted.")
        } catch let error as CustomStringConvertible {
            fputs("Error: \(error.description)\n", stderr)
            exit(1)
        } catch {
            fputs("Error: \(error.localizedDescription)\n", stderr)
            exit(1)
        }
    }

    private static func printSummary(candidates: [ScreenshotCandidate], policy: RetentionPolicy, dryRun: Bool) {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short

        print("Retention: \(policy.days.rawValue) days")
        print("Cutoff: \(formatter.string(from: policy.cutoffDate))")
        print("Mode: \(dryRun ? "dry run" : "delete")")
        print("Matches: \(candidates.count)")

        guard candidates.isEmpty == false else {
            return
        }

        print("")
        for candidate in candidates {
            let date = candidate.creationDate.map { formatter.string(from: $0) } ?? "unknown date"
            let name = candidate.filename ?? candidate.localIdentifier
            print("- \(date) | \(candidate.pixelWidth)x\(candidate.pixelHeight) | \(name)")
        }
        print("")
    }

    private static func confirmDeletion(count: Int) -> Bool {
        print("Move \(count) screenshot\(count == 1 ? "" : "s") to Recently Deleted? Type DELETE to continue: ", terminator: "")
        let response = readLine()?.trimmingCharacters(in: .whitespacesAndNewlines)
        return response == "DELETE"
    }
}
