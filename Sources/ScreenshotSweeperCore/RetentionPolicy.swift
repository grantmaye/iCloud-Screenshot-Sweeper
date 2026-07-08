import Foundation

public enum RetentionDays: Int, CaseIterable, Sendable {
    case thirty = 30
    case sixty = 60
    case ninety = 90

    public init?(days: Int) {
        self.init(rawValue: days)
    }
}

public struct RetentionPolicy: Sendable {
    public let days: RetentionDays
    public let calendar: Calendar
    public let now: Date

    public init(days: RetentionDays, calendar: Calendar, now: Date) {
        self.days = days
        self.calendar = calendar
        self.now = now
    }

    public var cutoffDate: Date {
        calendar.date(byAdding: .day, value: -days.rawValue, to: now) ?? now
    }

    public func isOlderThanRetention(_ date: Date?) -> Bool {
        guard let date else {
            return false
        }

        return date < cutoffDate
    }
}
