# CleanerMac - Project Context

> **RULE: This file must be updated after every significant change to the project.**

## Project Overview
**CleanerMac** — a native macOS disk cleaning utility built with SwiftUI. Competitor to CleanMyMac X.

## Status: In Development (Phase 2 - UX Polish)

## Tech Stack
- **Language**: Swift 6
- **UI Framework**: SwiftUI
- **Target**: macOS 14+ (Sonoma)
- **Build System**: Xcode / SPM
- **Architecture**: MVVM

## Cleaning Categories
1. System Junk (caches, logs, crash reports, .DS_Store, temp files)
2. User Cache (per-app ~/Library/Caches breakdown)
3. Developer Junk (Xcode DerivedData, iOS DeviceSupport, Simulators, npm/Homebrew/pip/CocoaPods/yarn caches)
4. Large Files (files > 100MB, sorted by size)
5. Duplicates (SHA-256 hash-based detection)
6. Browser Data (Safari, Chrome, Firefox, Edge, Brave, Arc)
7. Mail Attachments
8. iOS Backups
9. Trash (all trash bins)

## Project Structure
```
CleanerMac/
├── CleanerMac.xcodeproj
├── CleanerMac/
│   ├── App/           — Entry point, AppDelegate
│   ├── Models/        — Data models
│   ├── Services/      — Scanner & cleaner engines
│   ├── ViewModels/    — MVVM state management
│   ├── Views/         — SwiftUI views
│   ├── Utilities/     — Helpers, constants
│   └── Resources/     — Assets, entitlements
└── project_context.md
```

## Key Files
- `CleanerMacApp.swift` — App entry point
- `ScannerService.swift` — Core file system scanner
- `CleanerService.swift` — Deletion engine
- `DashboardView.swift` — Main overview screen
- `Constants.swift` — All macOS paths for cleaning

## UX Design Principles (from CleanMyMac X research)
- **Three-tier risk model**: Safe (auto-selected), Moderate (selected with review), Caution (user must opt-in)
- **Blue for positive actions** (Scan, Clean), **red only for destructive** (Delete Permanently)
- **Move to Trash as default** (reversible), Delete Permanently requires extra confirmation
- **Real-time scanning feedback**: floating progress bubble with %, live byte counter, per-category completion
- **Warning banners** for caution-level categories
- **Disk usage mini-bar** always visible in sidebar

## Recent Changes
- 2026-02-14: Project initialized
- 2026-02-14: Created Xcode project structure
- 2026-02-14: Implemented core models and services
- 2026-02-14: Built all SwiftUI views (Dashboard, Sidebar, Categories, Components)
- 2026-02-14: UX overhaul — risk-based auto-selection, floating scan progress bubble, two-tier cleaning flow, improved confirmation dialogs, sidebar disk usage bar, category risk badges

## Known Issues
- None yet

## Next Steps
- Add cleaning progress animation (counter-down effect)
- Add completion celebration screen
- File type filtering in Large Files view
- Sub-grouping items by application within categories
- App icon design
- DMG packaging
