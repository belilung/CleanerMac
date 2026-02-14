# CleanerMac - Project Context

> **RULE: This file must be updated after every significant change to the project.**

## Project Overview
**CleanerMac** — a native macOS disk cleaning utility built with SwiftUI. Competitor to CleanMyMac X.

## Status: In Development (Phase 1 - Foundation)

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

## Recent Changes
- 2026-02-14: Project initialized
- 2026-02-14: Created Xcode project structure
- 2026-02-14: Implemented core models and services

## Known Issues
- None yet

## Next Steps
- Implement all scanner services
- Build UI views
- Test on real macOS system
- Add app icon and polish
