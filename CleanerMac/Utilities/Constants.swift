import Foundation

enum CleaningPaths {
    static let home = FileManager.default.homeDirectoryForCurrentUser

    // MARK: - System Junk
    static var systemCaches: [URL] {
        [
            URL(fileURLWithPath: "/Library/Caches"),
            home.appendingPathComponent("Library/Caches"),
        ]
    }

    static var systemLogs: [URL] {
        [
            URL(fileURLWithPath: "/private/var/log"),
            home.appendingPathComponent("Library/Logs"),
            URL(fileURLWithPath: "/Library/Logs"),
        ]
    }

    static var crashReports: [URL] {
        [
            home.appendingPathComponent("Library/Logs/DiagnosticReports"),
            URL(fileURLWithPath: "/Library/Logs/DiagnosticReports"),
        ]
    }

    static var temporaryFiles: [URL] {
        [
            URL(fileURLWithPath: NSTemporaryDirectory()),
            URL(fileURLWithPath: "/private/var/folders"),
            URL(fileURLWithPath: "/private/tmp"),
        ]
    }

    // MARK: - Developer Junk
    static var xcodeDerivedData: URL {
        home.appendingPathComponent("Library/Developer/Xcode/DerivedData")
    }

    static var xcodeArchives: URL {
        home.appendingPathComponent("Library/Developer/Xcode/Archives")
    }

    static var xcodeDeviceSupport: URL {
        home.appendingPathComponent("Library/Developer/Xcode/iOS DeviceSupport")
    }

    static var coreSimulator: URL {
        home.appendingPathComponent("Library/Developer/CoreSimulator")
    }

    static var xcodeCache: URL {
        home.appendingPathComponent("Library/Caches/com.apple.dt.Xcode")
    }

    static var swiftPackageCache: URL {
        home.appendingPathComponent("Library/Caches/org.swift.swiftpm")
    }

    // Package Manager Caches
    static var npmCache: URL {
        home.appendingPathComponent(".npm/_cacache")
    }

    static var yarnCache: URL {
        home.appendingPathComponent("Library/Caches/Yarn")
    }

    static var pipCache: URL {
        home.appendingPathComponent("Library/Caches/pip")
    }

    static var homebrewCache: URL {
        home.appendingPathComponent("Library/Caches/Homebrew")
    }

    static var cocoapodsCache: URL {
        home.appendingPathComponent("Library/Caches/CocoaPods")
    }

    static var gradleCache: URL {
        home.appendingPathComponent(".gradle/caches")
    }

    static var cargoCache: URL {
        home.appendingPathComponent(".cargo/registry/cache")
    }

    static var poetryCache: URL {
        home.appendingPathComponent("Library/Caches/pypoetry")
    }

    // MARK: - Browser Data
    static var safariCache: URL {
        home.appendingPathComponent("Library/Caches/com.apple.Safari")
    }

    static var chromeCache: URL {
        home.appendingPathComponent("Library/Caches/Google/Chrome")
    }

    static var chromeProfile: URL {
        home.appendingPathComponent("Library/Application Support/Google/Chrome")
    }

    static var firefoxProfiles: URL {
        home.appendingPathComponent("Library/Application Support/Firefox/Profiles")
    }

    static var firefoxCache: URL {
        home.appendingPathComponent("Library/Caches/Firefox")
    }

    static var edgeCache: URL {
        home.appendingPathComponent("Library/Caches/Microsoft Edge")
    }

    static var braveCache: URL {
        home.appendingPathComponent("Library/Caches/BraveSoftware/Brave-Browser")
    }

    static var arcCache: URL {
        home.appendingPathComponent("Library/Caches/company.thebrowser.Browser")
    }

    // MARK: - Mail Attachments
    static var mailAttachments: URL {
        home.appendingPathComponent("Library/Containers/com.apple.mail/Data/Library/Mail Downloads")
    }

    static var mailData: URL {
        home.appendingPathComponent("Library/Mail")
    }

    // MARK: - iOS Backups
    static var iOSBackups: URL {
        home.appendingPathComponent("Library/Application Support/MobileSync/Backup")
    }

    // MARK: - Docker
    static var dockerData: URL {
        home.appendingPathComponent("Library/Containers/com.docker.docker/Data")
    }

    static var dockerDesktop: URL {
        home.appendingPathComponent(".docker")
    }

    // MARK: - Trash
    static var userTrash: URL {
        home.appendingPathComponent(".Trash")
    }

    // MARK: - Downloads
    static var downloads: URL {
        home.appendingPathComponent("Downloads")
    }

    // MARK: - App Leftovers directories
    static var appLeftoverLocations: [URL] {
        [
            home.appendingPathComponent("Library/Application Support"),
            home.appendingPathComponent("Library/Preferences"),
            home.appendingPathComponent("Library/Caches"),
            home.appendingPathComponent("Library/Containers"),
            home.appendingPathComponent("Library/Group Containers"),
            home.appendingPathComponent("Library/LaunchAgents"),
            home.appendingPathComponent("Library/HTTPStorages"),
            home.appendingPathComponent("Library/Saved Application State"),
            home.appendingPathComponent("Library/Cookies"),
            home.appendingPathComponent("Library/WebKit"),
        ]
    }

    // MARK: - Never Delete (Safety)
    static var neverDelete: Set<String> {
        [
            "Library/Keychains",
            "Library/Preferences/com.apple.",
            "Library/Mail/V",
            "Library/Messages",
            "Library/Contacts",
            "Library/Calendars",
            "Library/Photos",
            ".ssh",
            ".gnupg",
            "Library/Accounts",
            "Library/Biome",
            "Library/PersonalizationPortrait",
        ]
    }
}
