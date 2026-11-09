# Comprehensive macOS Disk Cleaning Research

> Reference document for building a professional macOS cleaning utility.
> Verified against a real macOS 15 (Sequoia) system.

---

## 1. ALL KNOWN macOS CACHE LOCATIONS

### 1.1 User-Level Caches (Safe to Delete)

**Primary location:** `~/Library/Caches/`

This is the main user cache directory. Each app stores caches in a subfolder named by its bundle identifier. The entire contents of `~/Library/Caches/` are safe to delete -- apps will regenerate them. Typical size: **5-20 GB**.

```
~/Library/Caches/com.apple.Safari/
~/Library/Caches/com.apple.dt.Xcode/
~/Library/Caches/com.apple.Music/
~/Library/Caches/com.apple.iTunes/
~/Library/Caches/com.spotify.client/
~/Library/Caches/com.google.SoftwareUpdate/
~/Library/Caches/com.apple.nsurlsessiond/
~/Library/Caches/com.apple.helpd/
~/Library/Caches/com.apple.ap.adprivacyd/
~/Library/Caches/CloudKit/
~/Library/Caches/com.apple.cloudd/
~/Library/Caches/com.apple.bird/
```

**How to enumerate programmatically (Swift):**
```swift
let cacheURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
let contents = try FileManager.default.contentsOfDirectory(at: cacheURL, includingPropertiesForKeys: [.fileSizeKey, .isDirectoryKey])
```

### 1.2 System-Level Caches (Require root / caution)

```
/Library/Caches/                              # System-wide app caches
/Library/Caches/com.apple.iconservices.store  # Icon cache
/Library/Caches/com.apple.aned/              # Apple Neural Engine cache
/System/Library/Caches/                       # DO NOT TOUCH - SIP protected
```

**Rule:** `/Library/Caches/` can be cleaned with elevated privileges. `/System/Library/Caches/` is protected by SIP and must NEVER be touched.

### 1.3 Application-Specific Caches

#### Browser Caches

| Browser | Cache Location | Typical Size |
|---------|---------------|--------------|
| Safari | `~/Library/Caches/com.apple.Safari/` | 100MB-2GB |
| Safari (WebKit) | `~/Library/Caches/com.apple.WebKit.WebProcess/` | 50-500MB |
| Chrome | `~/Library/Caches/Google/Chrome/Default/Cache/` | 200MB-2GB |
| Chrome (per profile) | `~/Library/Caches/Google/Chrome/Profile N/Cache/` | varies |
| Firefox | `~/Library/Caches/Firefox/Profiles/<hash>.default-release/` | 200MB-1GB |
| Edge | `~/Library/Caches/Microsoft Edge/Default/Cache/` | 200MB-1GB |
| Brave | `~/Library/Caches/BraveSoftware/Brave-Browser/Default/Cache/` | 200MB-1GB |
| Arc | `~/Library/Caches/company.thebrowser.Browser/` | 200MB-1GB |

#### Xcode Caches (Often the LARGEST consumer)

```
~/Library/Developer/Xcode/DerivedData/                    # Build products (often 5-50GB)
~/Library/Developer/Xcode/Archives/                       # Archived builds
~/Library/Developer/Xcode/iOS DeviceSupport/              # Debug symbols per iOS version (often 5-20GB)
~/Library/Developer/CoreSimulator/Devices/                 # Simulator data (often 5-30GB)
~/Library/Developer/CoreSimulator/Caches/                  # Simulator caches
~/Library/Caches/com.apple.dt.Xcode/                      # Xcode internal caches
~/Library/Caches/org.swift.swiftpm/                        # Swift Package Manager cache
```

**Shell commands to clean Xcode safely:**
```bash
# Delete derived data (always safe)
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Delete old iOS device support (keep latest version)
# List by date:
ls -lt ~/Library/Developer/Xcode/iOS\ DeviceSupport/

# Delete unavailable simulators
xcrun simctl delete unavailable

# Delete all simulator content and settings (nuclear option)
xcrun simctl erase all
```

### 1.4 DNS Cache

```bash
# Flush DNS cache (macOS 12+)
sudo dscacheutil -flushcache
sudo killall -HUP mDNSResponder

# Note: There's no persistent file to delete; DNS cache is in-memory.
# The mDNSResponder process holds the cache.
```

### 1.5 Font Caches

```bash
# Font cache locations:
/private/var/folders/*/*/C/com.apple.FontRegistry/       # Per-user font cache
/private/var/folders/*/*/C/com.apple.IntlDataCache.le/    # International data cache
~/Library/Caches/com.apple.FontRegistry/                  # User font cache

# Command to clear font caches:
sudo atsutil databases -remove
# Then restart the machine
```

### 1.6 Thumbnail / QuickLook Cache

```
~/Library/Caches/com.apple.QuickLook.thumbnailcache/
/private/var/folders/*/*/C/com.apple.QuickLook.thumbnailcache/

# Command to reset:
qlmanage -r cache
```

### 1.7 Temporary Files

```
/tmp/                           # Symlink to /private/tmp/
/private/tmp/                   # System temp directory (cleaned on reboot)
/private/var/tmp/               # Persistent temp directory
$TMPDIR                         # Per-user temp in /private/var/folders/
~/Library/Caches/TemporaryItems/
```

**How to find TMPDIR programmatically:**
```swift
let tmpDir = NSTemporaryDirectory() // e.g. /private/var/folders/gn/xxxxx/T/
```

---

## 2. ALL TYPES OF "JUNK" FILES ON macOS

### 2.1 Log Files

```
~/Library/Logs/                              # User application logs
~/Library/Logs/DiagnosticReports/            # Crash reports & diagnostics
~/Library/Logs/DiagnosticReports/Retired/    # Old crash reports
/Library/Logs/                               # System-level logs
/Library/Logs/DiagnosticReports/             # System crash reports
/private/var/log/                            # Unix system logs
/private/var/log/system.log                  # Main system log
/private/var/log/system.log.*.gz             # Rotated system logs
/private/var/log/wifi.log                    # Wi-Fi debug logs
/private/var/log/install.log                 # Installation logs
/private/var/log/asl/                        # Apple System Logger archives
/private/var/log/cups/                       # Print system logs
```

**Safe to delete:** All of the above. Logs are regenerated. User logs at `~/Library/Logs/` need no special permissions.

### 2.2 Crash Reports

```
~/Library/Logs/DiagnosticReports/            # User crash reports (.crash, .diag, .ips)
~/Library/Logs/DiagnosticReports/Retired/    # Older reports moved here
/Library/Logs/DiagnosticReports/             # System-level crash reports
/Library/Logs/CrashReporter/                 # Legacy location
/cores/                                      # Core dumps (can be massive, 500MB+ each)
```

**Shell command:**
```bash
# Delete all user crash reports
rm -rf ~/Library/Logs/DiagnosticReports/*

# Delete core dumps (requires root)
sudo rm -f /cores/core.*
```

### 2.3 .DS_Store Files

Created by Finder in every directory it opens. Contain folder view settings.

```bash
# Find all .DS_Store files
find / -name ".DS_Store" -type f 2>/dev/null

# Delete all .DS_Store files in a directory tree
find ~/Documents -name ".DS_Store" -delete

# Prevent .DS_Store on network volumes
defaults write com.apple.desktopservices DSDontWriteNetworkStores true

# Prevent .DS_Store on USB volumes
defaults write com.apple.desktopservices DSDontWriteUSBStores true
```

**Note:** `.DS_Store` files are tiny (4-12KB each) but there can be thousands. Deleting them is harmless -- Finder recreates them.

### 2.4 Spotlight Index

```
/.Spotlight-V100/                            # Volume root Spotlight index
/private/var/db/Spotlight/                   # System Spotlight data
/private/var/db/Spotlight-V100/              # Alternate location

# Rebuild Spotlight index (useful if index is corrupted/bloated):
sudo mdutil -E /                             # Erase and rebuild for boot volume
sudo mdutil -i off /Volumes/ExternalDrive    # Disable for a volume
sudo mdutil -i on /Volumes/ExternalDrive     # Re-enable for a volume

# Check index status:
mdutil -s /
```

### 2.5 Mail Attachments / Downloads

```
~/Library/Mail/                                          # Mail.app data (CAUTION: contains emails)
~/Library/Containers/com.apple.mail/Data/Library/Mail Downloads/  # Downloaded attachments
~/Library/Mail Downloads/                                # Legacy location
```

**Important:** Only clean `Mail Downloads/` -- deleting from `~/Library/Mail/` will destroy actual mail data.

### 2.6 iOS Device Backups

```
~/Library/Application Support/MobileSync/Backup/         # iTunes/Finder iOS backups

# List backups programmatically:
ls -la ~/Library/Application\ Support/MobileSync/Backup/
```

Each backup can be **5-60+ GB**. These are often the single largest space consumer.

**Shell command to list backup sizes:**
```bash
du -sh ~/Library/Application\ Support/MobileSync/Backup/*/
```

### 2.7 Xcode Derived Data (Detailed)

```
~/Library/Developer/Xcode/DerivedData/           # Build intermediates & indices
  ├── <ProjectName>-<hash>/
  │   ├── Build/                                  # Compiled products
  │   ├── Index/                                  # Code indexing data
  │   ├── Logs/                                   # Build logs
  │   └── SourcePackages/                         # Resolved SPM packages
  ├── ModuleCache.noindex/                        # Swift/Clang module cache
  ├── SDKStatCaches.noindex/                      # SDK stat caches
  ├── SymbolCache.noindex/                        # Debug symbol caches
  └── CompilationCache.noindex/                   # Compilation cache
```

### 2.8 Docker Images / Volumes

```
~/Library/Containers/com.docker.docker/Data/     # Docker Desktop data
~/Library/Containers/com.docker.docker/Data/vms/ # Docker VM disk images
~/.docker/                                        # Docker config & CLI plugins

# Docker cleanup commands:
docker system prune -a                            # Remove all unused images/containers/networks
docker volume prune                               # Remove unused volumes
docker builder prune                              # Remove build cache
docker system df                                  # Show Docker disk usage
```

Docker VM disk can grow to **20-60+ GB** and doesn't always shrink when images are deleted.

### 2.9 Homebrew Cache

```
~/Library/Caches/Homebrew/                       # Downloaded bottles and source
$(brew --cache)                                   # Canonical cache path (same as above usually)
$(brew --prefix)/var/homebrew/linked/            # Symlinks
/usr/local/var/log/                              # Homebrew service logs (Intel)
/opt/homebrew/var/log/                           # Homebrew service logs (Apple Silicon)

# Cleanup commands:
brew cleanup                                      # Remove outdated versions
brew cleanup -s                                   # Remove all cached downloads
brew autoremove                                   # Remove unused dependencies
```

### 2.10 Package Manager Caches

#### npm
```
~/.npm/                                           # npm cache directory
~/.npm/_cacache/                                  # Content-addressable cache

# Cleanup:
npm cache clean --force
```

#### yarn (v1)
```
~/Library/Caches/Yarn/                           # Yarn v1 cache
~/.yarn/cache/                                    # Alternative location

# Cleanup:
yarn cache clean
```

#### yarn (Berry / v2+)
```
.yarn/cache/                                      # Per-project (PnP mode)
~/.yarn/berry/cache/                              # Global cache
```

#### pnpm
```
~/.pnpm-store/                                    # pnpm content-addressable store
~/Library/pnpm/store/                             # Alternative location

# Cleanup:
pnpm store prune
```

#### pip (Python)
```
~/Library/Caches/pip/                             # pip HTTP & wheel cache
~/Library/Caches/pip/http/                        # HTTP response cache
~/Library/Caches/pip/wheels/                      # Built wheel cache

# Cleanup:
pip cache purge
```

#### gem (Ruby)
```
~/.gem/                                           # RubyGems data
~/Library/Caches/CocoaPods/                       # CocoaPods cache

# Cleanup:
gem cleanup
pod cache clean --all
```

#### Cargo (Rust)
```
~/.cargo/registry/                                # Crate registry index + source
~/.cargo/git/                                     # Git dependency checkouts

# Cleanup:
cargo cache -a                                    # Requires cargo-cache
```

#### Go
```
~/Library/Caches/go-build/                        # Go build cache
~/go/pkg/mod/                                     # Go module cache

# Cleanup:
go clean -cache
go clean -modcache
```

#### Gradle (Android/Java)
```
~/.gradle/caches/                                 # Gradle build cache
~/.gradle/daemon/                                 # Gradle daemon logs
~/.gradle/wrapper/dists/                          # Downloaded Gradle distributions

# Cleanup:
rm -rf ~/.gradle/caches/
```

#### Carthage
```
~/Library/Caches/org.carthage.CarthageKit/        # Carthage dependency cache
Carthage/Build/                                    # Per-project built frameworks
```

#### Composer (PHP)
```
~/.composer/cache/                                # Composer package cache
```

#### Maven (Java)
```
~/.m2/repository/                                 # Maven local repository
```

---

## 3. BEST PRACTICES FOR SAFELY CLEANING macOS

### 3.1 Files That Should NEVER Be Deleted

```
ABSOLUTELY NEVER DELETE:
├── /System/                           # SIP-protected system files
├── /usr/ (except /usr/local/)         # SIP-protected Unix utilities
├── /bin/                              # Core Unix binaries
├── /sbin/                             # System binaries
├── /private/var/db/                   # System databases (except Spotlight for reindex)
├── ~/Library/Keychains/               # Keychain/passwords - IRREPLACEABLE
├── ~/Library/Mail/                    # Actual email data (not just cache)
├── ~/Library/Messages/                # iMessage history
├── ~/Library/Calendars/               # Calendar data
├── ~/Library/Contacts/                # Contacts data
├── ~/Library/Photos/                  # Photo library
├── ~/Library/Preferences/             # App preferences (small files, critical)
├── ~/Library/Application Support/     # App data (NOT cache - real data)
│   ├── MobileSync/                    # iOS backups (only with user consent)
│   └── AddressBook/                   # Contacts data
├── ~/Library/Containers/              # Sandboxed app data
├── ~/Library/Group Containers/        # Shared app data
├── /Library/Preferences/              # System preferences
├── /Library/Keychains/                # System keychain
├── ~/.ssh/                            # SSH keys
├── ~/.gnupg/                          # GPG keys
├── ~/.config/                         # Application configs
├── ~/Library/Accounts/                # User account data
└── Any .plist in Preferences/         # Could break apps if deleted
```

**Golden Rule:** Only delete from locations explicitly designated as "cache", "tmp", "log", or "Caches" directories. When in doubt, DO NOT DELETE.

### 3.2 How to Calculate Space Saved

```swift
// APPROACH 1: Pre-scan with FileManager
func directorySize(at url: URL) -> Int64 {
    let resourceKeys: Set<URLResourceKey> = [.fileSizeKey, .isDirectoryKey, .isRegularFileKey]
    guard let enumerator = FileManager.default.enumerator(
        at: url,
        includingPropertiesForKeys: Array(resourceKeys),
        options: [.skipsHiddenFiles], // or [] to include hidden
        errorHandler: nil
    ) else { return 0 }

    var totalSize: Int64 = 0
    for case let fileURL as URL in enumerator {
        guard let resourceValues = try? fileURL.resourceValues(forKeys: resourceKeys),
              let isRegularFile = resourceValues.isRegularFile,
              isRegularFile,
              let fileSize = resourceValues.fileSize else { continue }
        totalSize += Int64(fileSize)
    }
    return totalSize
}

// APPROACH 2: Using stat (more accurate for actual disk usage)
func diskUsage(at path: String) -> Int64 {
    var statInfo = stat()
    guard stat(path, &statInfo) == 0 else { return 0 }
    return statInfo.st_blocks * 512 // blocks are 512-byte units
}

// APPROACH 3: Using NSFileManager allocatedSizeKey (accounts for compression)
// .totalFileAllocatedSizeKey or .fileAllocatedSizeKey
let resourceValues = try fileURL.resourceValues(forKeys: [.totalFileAllocatedSizeKey])
let allocatedSize = resourceValues.totalFileAllocatedSize ?? 0
```

**Important considerations:**
- Use `totalFileAllocatedSizeKey` for APFS (accounts for clones and compression)
- Always show "space that will be freed" vs "file sizes on disk" - they can differ due to APFS clones
- Scan BEFORE deletion, record sizes, then verify AFTER deletion
- Account for hard links (same file counted multiple times)
- Account for APFS snapshots (space might not be freed immediately)

### 3.3 How to Handle SIP (System Integrity Protection)

**SIP protects these paths:**
```
/System/
/usr/ (except /usr/local/)
/bin/
/sbin/
/var/ (some subdirectories)
/Applications/ (pre-installed Apple apps only)
```

**What your app CAN do without disabling SIP:**
- Delete anything in `~/Library/` (user domain)
- Delete anything in `/Library/Caches/` (with admin privileges)
- Delete `/private/var/log/` files (with admin privileges)
- Delete `/tmp/` and `/private/tmp/` contents
- Delete user files anywhere in `~/`

**What your app CANNOT do (SIP blocks it):**
- Modify `/System/Library/` anything
- Delete or modify system binaries
- Modify SIP-protected `/var/db/` directories
- Inject code into system processes

**How to request elevated privileges in Swift:**
```swift
// Using AuthorizationServices for privileged operations
import Security

func executePrivilegedCommand(_ command: String, arguments: [String]) throws {
    var authRef: AuthorizationRef?
    let status = AuthorizationCreate(nil, nil, [], &authRef)
    guard status == errAuthorizationSuccess, let auth = authRef else {
        throw NSError(domain: "Auth", code: Int(status))
    }

    // Use SMJobBless or privileged helper tool for production apps
    // Direct AuthorizationExecuteWithPrivileges is deprecated
}

// RECOMMENDED: Use a privileged helper tool installed via SMAppService
// 1. Create a helper tool (separate target)
// 2. Install it via SMAppService.loginItem or SMJobBless
// 3. Communicate via XPC
```

### 3.4 Proper Permissions Handling

```swift
// Check if file is deletable before attempting
let fileManager = FileManager.default

func canDelete(at url: URL) -> Bool {
    return fileManager.isDeletableFile(atPath: url.path)
}

// Check if directory is writable
func canWrite(to url: URL) -> Bool {
    return fileManager.isWritableFile(atPath: url.path)
}

// Move to Trash instead of permanent delete (safer, reversible)
func moveToTrash(url: URL) throws {
    var trashedURL: NSURL?
    try fileManager.trashItem(at: url, resultingItemURL: &trashedURL)
}

// For sandboxed apps: Request access via NSOpenPanel or security-scoped bookmarks
// For non-sandboxed apps: Direct file access works for user-domain files

// Handle "Full Disk Access" requirement (macOS 10.14+):
// Your app needs Full Disk Access to read:
//   ~/Library/Mail/
//   ~/Library/Messages/
//   ~/Library/Safari/
//   ~/Library/Cookies/
//   ~/Library/HomeKit/
// Check via: access(path, R_OK) == 0
// If access denied, prompt user to grant Full Disk Access in System Preferences

// Check Full Disk Access
func hasFullDiskAccess() -> Bool {
    let testPaths = [
        NSHomeDirectory() + "/Library/Safari/Bookmarks.plist",
        NSHomeDirectory() + "/Library/Mail",
    ]
    for path in testPaths {
        if access(path, R_OK) == 0 {
            return true
        }
    }
    return false
}
```

**Full Disk Access (FDA) is required for:**
- Scanning Safari data
- Scanning Mail data
- Scanning Messages data
- Scanning Cookies
- Accessing most `~/Library/` subdirectories on modern macOS

**How to guide users to grant FDA:**
```swift
// Open System Preferences -> Privacy -> Full Disk Access
NSWorkspace.shared.open(URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")!)
```

---

## 4. LARGE FILE DETECTION STRATEGIES

### 4.1 Efficient Filesystem Scanning

```swift
// STRATEGY 1: FileManager enumerator (most common)
func findLargeFiles(in directory: URL, largerThan threshold: Int64) -> [(URL, Int64)] {
    var results: [(URL, Int64)] = []
    let keys: [URLResourceKey] = [.fileSizeKey, .isRegularFileKey, .isDirectoryKey]

    guard let enumerator = FileManager.default.enumerator(
        at: directory,
        includingPropertiesForKeys: keys,
        options: [.skipsPackageDescendants], // Skip .app bundles etc.
        errorHandler: { url, error in
            // Log error, continue scanning
            return true
        }
    ) else { return [] }

    for case let url as URL in enumerator {
        guard let values = try? url.resourceValues(forKeys: Set(keys)),
              values.isRegularFile == true,
              let size = values.fileSize,
              size > threshold else { continue }
        results.append((url, Int64(size)))
    }

    return results.sorted { $0.1 > $1.1 } // Sort by size descending
}

// STRATEGY 2: POSIX fts (fastest, C-level)
// Use fts_open/fts_read for maximum performance
// See Apple docs: https://developer.apple.com/library/archive/documentation/System/Conceptual/ManPages_iPhoneOS/man3/fts.3.html

// STRATEGY 3: Spotlight metadata (for indexed volumes)
func findLargeFilesViaSpotlight(largerThan bytes: Int) -> [String] {
    let query = NSMetadataQuery()
    query.predicate = NSPredicate(format: "kMDItemFSSize > %d", bytes)
    query.searchScopes = [NSMetadataQueryLocalComputerScope]
    // ... run query asynchronously
}

// STRATEGY 4: du command (for quick estimates)
// du -sh * | sort -rh | head -20
```

**Performance tips:**
- Use `DispatchQueue.global(qos: .utility)` for background scanning
- Skip `/System/`, `/usr/`, `/bin/`, `/sbin/` (SIP protected, not user data)
- Skip `.Spotlight-V100/`, `.fseventsd/`, `.Trashes/` (system metadata)
- Use `URLResourceKey.volumeAvailableCapacityForImportantUsageKey` for available space
- Report progress incrementally to the UI
- Cancel scanning if user navigates away
- Cache scan results with timestamps

### 4.2 Common Locations for Large Files

```
~/Downloads/                                  # Often 10-50GB+ of forgotten downloads
~/Desktop/                                    # Users dump files here
~/Documents/                                  # Large documents, VMs
~/Movies/                                     # Video files
~/Music/                                      # Music library
~/.Trash/                                     # Deleted but not purged
~/Library/Developer/Xcode/DerivedData/        # 5-50GB for active developers
~/Library/Developer/Xcode/iOS DeviceSupport/  # 5-20GB
~/Library/Developer/CoreSimulator/            # 5-30GB
~/Library/Application Support/MobileSync/Backup/ # 5-60GB per device backup
~/Library/Containers/com.docker.docker/       # 10-60GB Docker data
~/Library/Caches/                             # 5-20GB combined caches
~/Library/Application Support/Steam/          # Game data (varies wildly)
~/.npm/                                       # 2-10GB for active Node developers
~/Library/Caches/Homebrew/                    # 1-5GB
~/Library/Group Containers/group.com.apple.*/  # Various Apple app data
/private/var/vm/sleepimage                    # Equal to RAM size (can be huge)
```

### 4.3 Duplicate File Detection

```swift
// STRATEGY 1: Size-based pre-filtering + hash comparison
// Step 1: Group files by size (fast - just stat calls)
// Step 2: For same-size files, compare first 4KB (fast hash)
// Step 3: For matching partial hashes, compute full file hash

import CryptoKit

func fileHash(at url: URL, partial: Bool = false) -> String? {
    guard let handle = try? FileHandle(forReadingFrom: url) else { return nil }
    defer { handle.closeFile() }

    var hasher = SHA256()
    if partial {
        // Read only first 4KB for quick comparison
        let data = handle.readData(ofLength: 4096)
        hasher.update(data: data)
    } else {
        // Read full file in chunks
        while autoreleasepool(invoking: {
            let data = handle.readData(ofLength: 1024 * 1024) // 1MB chunks
            if data.isEmpty { return false }
            hasher.update(data: data)
            return true
        }) {}
    }
    return SHA256.hash(data: Data()).description
}

// STRATEGY 2: Using fdupes/jdupes concepts
// 1. Build map: fileSize -> [URL]
// 2. Filter to groups with 2+ files
// 3. Compare partial hashes within each group
// 4. Compare full hashes for partial matches
// 5. Optionally verify with byte-by-byte comparison

// STRATEGY 3: Hardlink detection (APFS clones)
func areHardLinked(_ url1: URL, _ url2: URL) -> Bool {
    var stat1 = stat(), stat2 = stat()
    guard stat(url1.path, &stat1) == 0, stat(url2.path, &stat2) == 0 else { return false }
    return stat1.st_dev == stat2.st_dev && stat1.st_ino == stat2.st_ino
}
```

**Important for APFS:** Use `clonefile()` system call awareness -- APFS clones share storage and deleting one clone may not free space.

---

## 5. APP UNINSTALLER / LEFTOVER DETECTION

### 5.1 Where Apps Store Their Data

When a macOS app is installed, it scatters files across many directories. An app with bundle ID `com.example.app` typically creates:

```
MAIN APPLICATION:
/Applications/AppName.app                                    # The .app bundle itself
~/Applications/AppName.app                                   # User-installed apps

PREFERENCES:
~/Library/Preferences/com.example.app.plist                  # Main preferences
~/Library/Preferences/ByHost/com.example.app.*.plist         # Per-host preferences
~/Library/Preferences/com.example.app.helper.plist           # Helper preferences
/Library/Preferences/com.example.app.plist                   # System-wide preferences

APPLICATION SUPPORT (persistent data):
~/Library/Application Support/AppName/                        # Main app data
~/Library/Application Support/com.example.app/               # Alternative naming

CACHES:
~/Library/Caches/com.example.app/                            # App cache

LOGS:
~/Library/Logs/AppName/                                       # App logs

COOKIES & WEB DATA:
~/Library/Cookies/com.example.app.binarycookies              # Cookies
~/Library/HTTPStorages/com.example.app/                      # HTTP storage
~/Library/WebKit/com.example.app/                            # WebKit data

SAVED STATE:
~/Library/Saved Application State/com.example.app.savedState/ # Window positions etc.

CONTAINERS (sandboxed apps):
~/Library/Containers/com.example.app/                        # Sandbox container
~/Library/Group Containers/group.com.example.*/              # Shared containers

LAUNCH AGENTS/DAEMONS:
~/Library/LaunchAgents/com.example.app.plist                 # User-level auto-launch
/Library/LaunchAgents/com.example.app.plist                  # System-level auto-launch
/Library/LaunchDaemons/com.example.app.plist                 # System daemon

PRIVILEGED HELPERS:
/Library/PrivilegedHelperTools/com.example.app.helper        # Privileged helper

KERNEL EXTENSIONS (legacy):
/Library/Extensions/AppNameDriver.kext                        # Kernel extension

SYSTEM EXTENSIONS (modern):
/Library/SystemExtensions/                                    # System extensions

LOGIN ITEMS:
~/Library/Application Support/com.apple.backgroundtaskmanagementagent/ # Login items

RECEIPTS:
/Library/Receipts/                                            # Installer receipts
/private/var/db/receipts/com.example.app.*                   # Package receipts

CRASH REPORTS:
~/Library/Logs/DiagnosticReports/AppName_*.crash             # Crash logs
~/Library/Logs/DiagnosticReports/AppName_*.ips               # Newer format

APPLICATION SCRIPTS:
~/Library/Application Scripts/com.example.app/               # Sandboxed app scripts
```

### 5.2 How to Detect App Leftovers After Uninstallation

```swift
// APPROACH 1: Bundle ID search
func findLeftovers(forBundleID bundleID: String) -> [URL] {
    var leftovers: [URL] = []
    let home = FileManager.default.homeDirectoryForCurrentUser

    // Search patterns based on bundle ID
    let searchDirs: [(URL, Bool)] = [ // (directory, searchRecursively)
        (home.appendingPathComponent("Library/Preferences"), false),
        (home.appendingPathComponent("Library/Application Support"), false),
        (home.appendingPathComponent("Library/Caches"), false),
        (home.appendingPathComponent("Library/Logs"), false),
        (home.appendingPathComponent("Library/Cookies"), false),
        (home.appendingPathComponent("Library/HTTPStorages"), false),
        (home.appendingPathComponent("Library/WebKit"), false),
        (home.appendingPathComponent("Library/Saved Application State"), false),
        (home.appendingPathComponent("Library/Containers"), false),
        (home.appendingPathComponent("Library/Group Containers"), false),
        (home.appendingPathComponent("Library/Application Scripts"), false),
        (home.appendingPathComponent("Library/LaunchAgents"), false),
    ]

    for (dir, _) in searchDirs {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: nil
        ) else { continue }

        for item in contents {
            let name = item.lastPathComponent.lowercased()
            if name.contains(bundleID.lowercased()) {
                leftovers.append(item)
            }
        }
    }

    return leftovers
}

// APPROACH 2: App name search (catches non-standard naming)
func findLeftovers(forAppName appName: String) -> [URL] {
    // Search the same directories but match on app name
    // e.g., "Spotify" matches "Spotify" folder in Application Support
    // Be careful with short/generic names to avoid false positives
}

// APPROACH 3: Pre-install snapshot comparison
// Take a snapshot of all Library/ contents before install
// Compare after install to see what was added
// Store this mapping for later uninstall

// APPROACH 4: Monitor filesystem changes with FSEvents
// Watch for file creation during app installation
// Record all paths created by the app
```

### 5.3 Building an App Inventory

```swift
// Get all installed apps and their bundle IDs
func getInstalledApps() -> [(name: String, bundleID: String, path: URL, size: Int64)] {
    var apps: [(String, String, URL, Int64)] = []

    let appDirs = [
        URL(fileURLWithPath: "/Applications"),
        FileManager.default.homeDirectoryForCurrentUser.appendingPathComponent("Applications"),
    ]

    for dir in appDirs {
        guard let contents = try? FileManager.default.contentsOfDirectory(
            at: dir,
            includingPropertiesForKeys: [.fileSizeKey],
            options: [.skipsHiddenFiles]
        ) else { continue }

        for appURL in contents where appURL.pathExtension == "app" {
            let infoPlist = appURL.appendingPathComponent("Contents/Info.plist")
            guard let info = NSDictionary(contentsOf: infoPlist),
                  let bundleID = info["CFBundleIdentifier"] as? String else { continue }

            let name = info["CFBundleName"] as? String ?? appURL.deletingPathExtension().lastPathComponent
            let size = directorySize(at: appURL) // from earlier

            apps.append((name, bundleID, appURL, size))
        }
    }

    return apps
}

// Alternative: Use mdls for bundle ID
// mdls -name kMDItemCFBundleIdentifier /Applications/AppName.app
```

---

## 6. PRIVACY CLEANING

### 6.1 Browser History / Cookies / Cache Per Browser

#### Safari

```
HISTORY:
~/Library/Safari/History.db                      # Browsing history (SQLite)
~/Library/Safari/History.db-wal
~/Library/Safari/History.db-shm

COOKIES:
~/Library/Cookies/Cookies.binarycookies           # Safari cookies
~/Library/Safari/LocalStorage/                    # Local storage data

CACHE:
~/Library/Caches/com.apple.Safari/                # Safari cache
~/Library/Caches/com.apple.WebKit.WebProcess/     # WebKit process cache

DOWNLOADS LIST:
~/Library/Safari/Downloads.plist                  # Download history

TOPSITES:
~/Library/Safari/TopSites.plist                   # Frequently visited

LAST SESSION:
~/Library/Safari/LastSession.plist                # Last open tabs

FORM DATA:
~/Library/Safari/Form Values                      # Autofill data

FAVICONS:
~/Library/Safari/Favicon Cache/                   # Website icons
~/Library/Safari/Touch Icons Cache/               # Touch icons

TABS:
~/Library/Safari/CloudTabs.db                     # iCloud tabs

NOTE: Safari data requires Full Disk Access to read/delete.
```

#### Google Chrome

```
PROFILE ROOT: ~/Library/Application Support/Google/Chrome/Default/
(Replace "Default" with "Profile N" for additional profiles)

HISTORY:
.../Default/History                               # SQLite database
.../Default/History-journal

COOKIES:
.../Default/Cookies                               # SQLite database
.../Default/Cookies-journal

CACHE:
~/Library/Caches/Google/Chrome/Default/Cache/     # Disk cache
~/Library/Caches/Google/Chrome/Default/Code Cache/ # JS compiled cache

LOCAL STORAGE:
.../Default/Local Storage/leveldb/               # Website local storage

SESSION:
.../Default/Sessions/                            # Session data
.../Default/Current Session
.../Default/Current Tabs

AUTOFILL:
.../Default/Web Data                             # SQLite (autofill, search engines)

FAVICONS:
.../Default/Favicons                             # SQLite

LOGIN DATA:
.../Default/Login Data                           # CAUTION: Contains saved passwords

BOOKMARKS:
.../Default/Bookmarks                            # JSON file

DOWNLOADS:
.../Default/DownloadMetadata                     # Download history

MEDIA:
.../Default/Media History                        # Media playback history
```

#### Firefox

```
PROFILE ROOT: ~/Library/Application Support/Firefox/Profiles/<random>.default-release/

HISTORY & BOOKMARKS:
.../places.sqlite                                # History + bookmarks (SQLite)
.../places.sqlite-wal

COOKIES:
.../cookies.sqlite                               # Cookies

CACHE:
~/Library/Caches/Firefox/Profiles/<random>.default-release/cache2/ # Disk cache

LOCAL STORAGE:
.../webappsstore.sqlite                          # Local storage
.../storage/default/                             # IndexedDB etc.

SESSION:
.../sessionstore.jsonlz4                         # Current session
.../sessionstore-backups/                        # Session backups

FORM DATA:
.../formhistory.sqlite                           # Form autofill

FAVICONS:
.../favicons.sqlite                              # Favicons

DOWNLOADS:
.../downloads.sqlite                             # Download history (older Firefox)
# Newer Firefox stores downloads in places.sqlite
```

#### Microsoft Edge

```
PROFILE ROOT: ~/Library/Application Support/Microsoft Edge/Default/
CACHE: ~/Library/Caches/Microsoft Edge/Default/Cache/

# Same structure as Chrome (Chromium-based):
History, Cookies, Local Storage, Web Data, Login Data, Bookmarks, etc.
```

#### Brave Browser

```
PROFILE ROOT: ~/Library/Application Support/BraveSoftware/Brave-Browser/Default/
CACHE: ~/Library/Caches/BraveSoftware/Brave-Browser/Default/Cache/

# Same structure as Chrome (Chromium-based)
```

#### Arc Browser

```
PROFILE ROOT: ~/Library/Application Support/Arc/User Data/Default/
CACHE: ~/Library/Caches/company.thebrowser.Browser/

# Chromium-based, similar structure to Chrome
```

### 6.2 Recent Items Lists

```
# Finder recent items
~/Library/Application Support/com.apple.sharedfilelist/
  com.apple.LSSharedFileList.RecentDocuments.sfl2
  com.apple.LSSharedFileList.RecentApplications.sfl2
  com.apple.LSSharedFileList.RecentServers.sfl2
  com.apple.LSSharedFileList.RecentHosts.sfl2
  com.apple.LSSharedFileList.FavoriteItems.sfl2
  com.apple.LSSharedFileList.FavoriteVolumes.sfl2
  com.apple.LSSharedFileList.ProjectsItems.sfl2

# Recent items in preferences
~/Library/Preferences/com.apple.recentitems.plist

# Spotlight recent searches
~/Library/Preferences/com.apple.Spotlight.plist

# Finder Go To Folder recents
~/Library/Preferences/com.apple.finder.plist  (GoToField key)

# Open/Save dialog recents
~/Library/Preferences/com.apple.finder.plist  (FXRecentFolders key)
~/Library/Preferences/.GlobalPreferences.plist (NSNavRecentPlaces key)

# Shell history
~/.zsh_history                                # Zsh command history
~/.bash_history                               # Bash command history

# Terminal saved state
~/Library/Saved Application State/com.apple.Terminal.savedState/

# Application-specific recent files (stored in each app's .plist)
# e.g., defaults read com.apple.Preview NSRecentDocumentRecords
```

**How to clear recent items programmatically:**
```swift
// Clear recent documents list
import AppKit

// Using SFL (shared file list) APIs:
// Note: NSRecentDocumentController for your own app's recents
// For system-wide: use LSSharedFileList (deprecated but still functional)

// Clear via shell:
// defaults delete com.apple.recentitems
// osascript -e 'tell application "System Events" to delete every recent item of application process "Finder"'
```

### 6.3 Trash Management

```
USER TRASH:
~/.Trash/                                        # User's trash folder

VOLUME TRASH:
/Volumes/<VolumeName>/.Trashes/<UID>/           # Per-volume, per-user trash

# Empty Trash programmatically (Swift):
import AppKit

// Modern API (macOS 10.14+):
NSWorkspace.shared.recycleURLs([url]) { newURLs, error in
    // Items moved to trash
}

// Or use FileManager:
try FileManager.default.trashItem(at: url, resultingItemURL: nil)

// Secure empty trash (overwrite):
// No longer available as API since macOS 10.12 (APFS doesn't support it)
// SSD TRIM handles secure deletion at hardware level

# Empty trash via shell:
rm -rf ~/.Trash/*
# or for all volumes:
sudo rm -rf /Volumes/*/.Trashes/*

# Get trash size:
du -sh ~/.Trash/
```

---

## 7. ADDITIONAL CLEANING CATEGORIES

### 7.1 Language & Localization Files

```
# Remove unused language files from .app bundles (saves 1-5GB):
# Each .app contains .lproj folders for every supported language
# e.g., /Applications/Xcode.app/Contents/Resources/*.lproj

# Find all localizations in an app:
ls /Applications/AppName.app/Contents/Resources/*.lproj

# Common approach: Keep en.lproj and Base.lproj, remove others
# CAUTION: This can break code signing! Only do for non-Apple apps
# and re-codesign after modification:
# codesign --force --deep --sign - /Applications/AppName.app
```

### 7.2 Universal Binary Architectures

```
# Strip unused architectures from universal binaries:
# On Apple Silicon: remove x86_64 slices
# On Intel: remove arm64 slices

# Check architecture:
lipo -info /Applications/AppName.app/Contents/MacOS/AppName
# Output: "Architectures in the fat file: x86_64 arm64"

# Strip (CAUTION: breaks code signing):
lipo /path/to/binary -remove x86_64 -output /path/to/binary

# Note: This is aggressive and can break apps. Not recommended for most users.
```

### 7.3 Time Machine Local Snapshots

```bash
# List local snapshots
tmutil listlocalsnapshots /

# Delete specific snapshot
sudo tmutil deletelocalsnapshots <date>

# Delete all local snapshots
tmutil listlocalsnapshots / | grep "com.apple" | while read snap; do
    sudo tmutil deletelocalsnapshots $(echo $snap | cut -d'.' -f4)
done

# Note: macOS manages these automatically when disk space is low
# Snapshots can consume 10-100+ GB
```

### 7.4 System Sleep Image

```bash
# Check sleep image size (usually equal to RAM)
ls -lh /private/var/vm/sleepimage

# Disable hibernation to prevent sleep image (saves RAM-size of space):
sudo pmset -a hibernatemode 0
sudo rm -f /private/var/vm/sleepimage

# Re-enable:
sudo pmset -a hibernatemode 3
```

### 7.5 Swap Files

```bash
# Location:
/private/var/vm/swapfile*

# DO NOT manually delete swap files - the kernel manages these.
# Restarting the Mac will clear swap.
```

---

## 8. IMPLEMENTATION ARCHITECTURE RECOMMENDATIONS

### 8.1 Scanning Categories for UI

```
CATEGORY                    | RISK LEVEL | TYPICAL SAVINGS
---------------------------|-----------|----------------
System Caches              | LOW       | 2-10 GB
User Caches                | LOW       | 3-15 GB
Browser Caches             | LOW       | 1-5 GB
Log Files                  | LOW       | 100MB-2 GB
Crash Reports              | LOW       | 10MB-500 MB
.DS_Store Files            | LOW       | 1-50 MB
Xcode Derived Data         | LOW       | 5-50 GB
Xcode Device Support       | MEDIUM    | 5-20 GB
iOS Simulators             | MEDIUM    | 5-30 GB
iOS Device Backups         | HIGH      | 5-60 GB per backup
Mail Attachments           | MEDIUM    | 100MB-5 GB
Downloads Folder           | MEDIUM    | 5-50 GB
Trash                      | LOW       | 0-100+ GB
Package Manager Caches     | LOW       | 2-10 GB
Docker Data                | MEDIUM    | 10-60 GB
Language Files             | HIGH      | 1-5 GB
Old iOS Device Support     | LOW       | 5-20 GB
Application Leftovers      | LOW       | 100MB-5 GB
Browser History/Cookies    | MEDIUM    | 10-500 MB
Recent Items Lists         | LOW       | <1 MB
Duplicate Files            | MEDIUM    | varies
Large Files                | MEDIUM    | varies
Time Machine Snapshots     | MEDIUM    | 10-100 GB
```

### 8.2 Required Entitlements and Permissions

```
FOR APP STORE DISTRIBUTION:
- com.apple.security.app-sandbox (required)
- com.apple.security.files.user-selected.read-write
- com.apple.security.files.bookmarks.app-scope
- com.apple.security.temporary-exception.files.absolute-path.read-write
  (Note: Apple may reject broad filesystem access in sandboxed apps)

FOR DIRECT DISTRIBUTION (non-App Store):
- No sandbox required (can access full filesystem with user permission)
- Hardened runtime required for notarization
- com.apple.security.automation.apple-events (for scripting bridges)

FULL DISK ACCESS:
- Must be granted manually by user in System Preferences
- Required for: Safari data, Mail data, Messages, Cookies
- Check with: access(path, R_OK) == 0

PRIVILEGED OPERATIONS:
- Use SMAppService for installing helper tools
- XPC for communication between app and helper
- Privileged helper can access /Library/*, /private/var/log/*, etc.
```

### 8.3 Critical Safety Checklist

```
BEFORE DELETING:
[ ] Verify the path is NOT under /System/, /usr/, /bin/, /sbin/
[ ] Verify the path is NOT a Keychain, Preferences, or critical data file
[ ] Check if file is currently in use (lsof or fcntl lock check)
[ ] Calculate size BEFORE deletion for accurate reporting
[ ] Log every deletion action for undo capability
[ ] Provide "Move to Trash" option instead of permanent delete
[ ] Show preview of what will be deleted BEFORE acting
[ ] Never delete files while apps that own them are running (for caches)

AFTER DELETING:
[ ] Verify space was actually freed (APFS clones may not free space)
[ ] Update the UI with actual space recovered
[ ] Offer to empty Trash if items were moved there
[ ] Log results for user reference
```

---

## 9. SHELL COMMANDS REFERENCE

```bash
# ---- SPACE ANALYSIS ----
# Total disk usage
df -h /

# Directory sizes (top-level)
du -sh ~/* ~/Library/* 2>/dev/null | sort -rh | head -30

# Find files larger than 500MB
find ~ -size +500M -type f 2>/dev/null

# APFS container info
diskutil apfs list

# ---- CACHE CLEANING ----
# Clear all user caches
rm -rf ~/Library/Caches/*

# Clear DNS cache
sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder

# Clear font caches
sudo atsutil databases -remove

# Clear QuickLook cache
qlmanage -r cache

# ---- DEVELOPER CLEANUP ----
# Xcode derived data
rm -rf ~/Library/Developer/Xcode/DerivedData/*

# Unavailable simulators
xcrun simctl delete unavailable

# CocoaPods cache
pod cache clean --all

# Homebrew cleanup
brew cleanup -s && brew autoremove

# npm cache
npm cache clean --force

# ---- PRIVACY ----
# Clear recent items
defaults delete com.apple.recentitems 2>/dev/null

# Clear shell history
rm -f ~/.zsh_history ~/.bash_history

# ---- SYSTEM MAINTENANCE ----
# Rebuild Spotlight index
sudo mdutil -E /

# Repair disk permissions (legacy, less relevant on APFS)
sudo diskutil resetUserPermissions / $(id -u)

# Rebuild Launch Services database
/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user

# Force empty Trash
rm -rf ~/.Trash/*
```

---

## 10. SIZE ESTIMATION FORMULAS

For showing users estimated savings before scanning:

```
ESTIMATED RANGES (based on industry data):
- Light user (basic apps, no development): 3-10 GB recoverable
- Average user: 10-25 GB recoverable
- Developer (Xcode + tools): 30-80 GB recoverable
- Heavy developer (Docker + multiple IDEs): 50-150+ GB recoverable

CATEGORY HEURISTICS:
- User caches: ~1-2% of used disk space
- Logs: ~0.1-0.5% of used disk space
- Xcode (if present): 10-50 GB flat
- iOS backups (if present): 5-60 GB per device
- Downloads folder age: files older than 90 days are candidates
```
