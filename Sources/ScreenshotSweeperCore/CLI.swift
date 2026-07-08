import Foundation

public struct CLIOptions: Sendable {
    public var retention: RetentionDays = .thirty
    public var dryRun = true
    public var assumeYes = false
    public var limit: Int?
    public var help = false
}

public enum CLIError: Error, CustomStringConvertible {
    case invalidRetention(String)
    case invalidLimit(String)
    case unknownArgument(String)

    public var description: String {
        switch self {
        case .invalidRetention(let value):
            return "Invalid retention '\(value)'. Use one of: 30, 60, 90."
        case .invalidLimit(let value):
            return "Invalid limit '\(value)'. Limit must be a positive integer."
        case .unknownArgument(let value):
            return "Unknown argument '\(value)'. Run with --help for usage."
        }
    }
}

public enum CLI {
    public static let usage = """
    screenshot-sweeper

    Find screenshots in your local Apple Photos library, including iCloud Photos items visible on this Mac,
    and move screenshots older than the selected retention window to Recently Deleted.

    Usage:
      screenshot-sweeper [--retention 30|60|90] [--delete] [--yes] [--limit N]

    Options:
      --retention, -r  Retention window in days. Allowed values: 30, 60, 90. Default: 30.
      --delete         Move matching screenshots to Recently Deleted. Without this, the tool is read-only.
      --yes, -y        Skip the confirmation prompt. Only meaningful with --delete.
      --limit          Maximum number of screenshots to process.
      --help, -h       Show this help text.

    Examples:
      screenshot-sweeper --retention 60
      screenshot-sweeper --retention 90 --delete
      screenshot-sweeper -r 30 --delete --yes --limit 100
    """

    public static func parse(_ arguments: [String]) throws -> CLIOptions {
        var options = CLIOptions()
        var index = 0

        while index < arguments.count {
            let argument = arguments[index]

            switch argument {
            case "--help", "-h":
                options.help = true
            case "--delete":
                options.dryRun = false
            case "--yes", "-y":
                options.assumeYes = true
            case "--retention", "-r":
                index += 1
                guard index < arguments.count else {
                    throw CLIError.invalidRetention("")
                }

                guard
                    let days = Int(arguments[index]),
                    let retention = RetentionDays(days: days)
                else {
                    throw CLIError.invalidRetention(arguments[index])
                }

                options.retention = retention
            case "--limit":
                index += 1
                guard index < arguments.count else {
                    throw CLIError.invalidLimit("")
                }

                guard let limit = Int(arguments[index]), limit > 0 else {
                    throw CLIError.invalidLimit(arguments[index])
                }

                options.limit = limit
            default:
                throw CLIError.unknownArgument(argument)
            }

            index += 1
        }

        return options
    }
}
