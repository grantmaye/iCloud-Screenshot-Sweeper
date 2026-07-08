import Foundation
import Testing
@testable import ScreenshotSweeperCore

@Suite("Retention policy")
struct RetentionPolicyTests {
    private let calendar = Calendar(identifier: .gregorian)
    private let now = Date(timeIntervalSince1970: 1_800_000_000)

    @Test("accepted retention windows are fixed")
    func acceptedWindows() {
        #expect(RetentionDays(days: 30) == .thirty)
        #expect(RetentionDays(days: 60) == .sixty)
        #expect(RetentionDays(days: 90) == .ninety)
        #expect(RetentionDays(days: 7) == nil)
    }

    @Test("dates before the cutoff match")
    func olderThanCutoff() throws {
        let policy = RetentionPolicy(days: .thirty, calendar: calendar, now: now)
        let older = try #require(calendar.date(byAdding: .day, value: -31, to: now))
        let newer = try #require(calendar.date(byAdding: .day, value: -29, to: now))

        #expect(policy.isOlderThanRetention(older))
        #expect(policy.isOlderThanRetention(newer) == false)
        #expect(policy.isOlderThanRetention(nil) == false)
    }
}

@Suite("CLI")
struct CLITests {
    @Test("defaults to 30 day dry run")
    func defaults() throws {
        let options = try CLI.parse([])

        #expect(options.retention == .thirty)
        #expect(options.dryRun)
        #expect(options.assumeYes == false)
        #expect(options.limit == nil)
    }

    @Test("parses delete mode")
    func deleteMode() throws {
        let options = try CLI.parse(["--retention", "90", "--delete", "--yes", "--limit", "25"])

        #expect(options.retention == .ninety)
        #expect(options.dryRun == false)
        #expect(options.assumeYes)
        #expect(options.limit == 25)
    }
}
