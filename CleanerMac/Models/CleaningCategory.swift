import Foundation
import SwiftUI

enum CleaningCategoryType: String, CaseIterable, Identifiable {
    case systemJunk = "System Junk"
    case userCache = "User Cache"
    case developerJunk = "Developer Junk"
    case largeFiles = "Large Files"
    case duplicates = "Duplicates"
    case browserData = "Browser Data"
    case mailAttachments = "Mail Attachments"
    case iOSBackups = "iOS Backups"
    case trash = "Trash"
    case messengerData = "Messenger Data"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .systemJunk: return "gearshape.2.fill"
        case .userCache: return "archivebox.fill"
        case .developerJunk: return "hammer.fill"
        case .largeFiles: return "doc.fill"
        case .duplicates: return "doc.on.doc.fill"
        case .browserData: return "globe"
        case .mailAttachments: return "paperclip"
        case .iOSBackups: return "iphone"
        case .trash: return "trash.fill"
        case .messengerData: return "message.fill"
        }
    }

    var color: Color {
        switch self {
        case .systemJunk: return .orange
        case .userCache: return .blue
        case .developerJunk: return .purple
        case .largeFiles: return .red
        case .duplicates: return .yellow
        case .browserData: return .green
        case .mailAttachments: return .cyan
        case .iOSBackups: return .pink
        case .trash: return .gray
        case .messengerData: return .indigo
        }
    }

    var description: String {
        switch self {
        case .systemJunk: return "System caches, logs, crash reports, temporary files"
        case .userCache: return "Application caches in ~/Library/Caches"
        case .developerJunk: return "Xcode DerivedData, simulators, package manager caches"
        case .largeFiles: return "Files larger than 50 MB"
        case .duplicates: return "Duplicate files wasting disk space"
        case .browserData: return "Browser caches, history, and cookies"
        case .mailAttachments: return "Downloaded email attachments"
        case .iOSBackups: return "Old iOS device backups"
        case .trash: return "Files in Trash"
        case .messengerData: return "Telegram, WhatsApp, Discord, Slack cached data"
        }
    }

    var riskLevel: RiskLevel {
        switch self {
        case .systemJunk, .userCache, .trash: return .safe
        case .developerJunk, .mailAttachments: return .moderate
        case .largeFiles, .duplicates, .browserData, .iOSBackups, .messengerData: return .caution
        }
    }
}

enum RiskLevel: String {
    case safe = "Safe"
    case moderate = "Moderate"
    case caution = "Caution"

    var color: Color {
        switch self {
        case .safe: return .green
        case .moderate: return .orange
        case .caution: return .red
        }
    }

    /// Whether items in this risk level should be auto-selected after scan
    var autoSelect: Bool {
        switch self {
        case .safe: return true
        case .moderate: return true
        case .caution: return false
        }
    }

    /// Whether cleaning requires extra confirmation
    var requiresConfirmation: Bool {
        switch self {
        case .safe: return false
        case .moderate: return false
        case .caution: return true
        }
    }

    var warningMessage: String? {
        switch self {
        case .safe: return nil
        case .moderate: return nil
        case .caution: return "These files may include personal content. Please review before deleting."
        }
    }
}
