# JSMStat

A native macOS dashboard for JIRA Service Management metrics. Built with SwiftUI for macOS 26 (Tahoe).

JSMStat connects to your JIRA Cloud instance, discovers service desks automatically, and presents real-time metrics across multiple visual dashboards.

## Features

- **Overview Dashboard** — KPIs, open/closed trends, and volume charts at a glance
- **Priority Dashboard** — Breakdown by priority level with distribution analysis
- **SLA Dashboard** — SLA compliance tracking and breach monitoring
- **By Category** — Metrics grouped by request type
- **By Person** — Workload distribution across assignees and reporters
- **End User** — Customer-facing request patterns
- **Ticket Trends** — Historical volume and resolution trends over time
- **Issues Dashboard** — Detailed issue-level metrics and lifecycle analysis
- **Operations Center** — Full-screen rotating dashboard for wall-mounted displays
- **Menu Bar Extra** — Persistent menu bar widget showing open ticket count
- **Change Notifications** — Real-time alerts for new tickets, status changes, and assignments

## Requirements

- macOS 26.0 (Tahoe) or later
- JIRA Cloud instance with Service Management
- API token from [Atlassian Account Settings](https://id.atlassian.com/manage-profile/security/api-tokens)

## Getting Started

1. Launch JSMStat
2. Open **Settings** (Cmd+,) and enter your JIRA Cloud site URL, email, and API token
3. JSMStat discovers your service desks and begins loading metrics

## Building from Source

```bash
# Clone the repository
git clone https://github.com/FyrbyAdditive/JSMStat.git
cd JSMStat

# Open in Xcode
open JSMStat.xcodeproj

# Or build from the command line
xcodebuild -project JSMStat.xcodeproj -scheme JSMStat -configuration Debug build
```

### Running Tests

```bash
xcodebuild -project JSMStat.xcodeproj -scheme JSMStat test
```

### Release Build

The project includes a release script that handles code signing, notarisation, and .pkg creation:

```bash
# One-time: store your Apple notarisation credentials
./scripts/store-credentials.sh

# Build, sign, notarise, and package
./scripts/build-release.sh

# With version override
./scripts/build-release.sh --version 1.0.0
```

This produces signed and notarised artifacts in `build/release/`:
- `JSMStat.app` — standalone application
- `JSMStat-{version}.pkg` — installer package (installs to /Applications)

**Prerequisites for release builds:**
- Apple Developer ID Application certificate
- Apple Developer ID Installer certificate
- App-specific password for notarisation (see `scripts/store-credentials.sh`)

## Tech Stack

- **Swift 6** with strict concurrency
- **SwiftUI** — declarative UI with Charts framework
- **macOS 26 SDK** — latest platform APIs
- **Keychain Services** — secure credential storage
- **UserNotifications** — native change alerts
- **os.Logger** — unified logging

## Project Structure

```
JSMStat/
├── App/              # App entry point and shared state
├── Auth/             # Keychain and connection configuration
├── API/              # JIRA REST API client and endpoints
├── Discovery/        # Service desk auto-discovery
├── Models/           # Data models
├── Metrics/          # Aggregation engine and time periods
├── Notifications/    # Change polling and notification delivery
├── Utilities/        # Colours, date formatting, design tokens
├── ViewModels/       # Dashboard and ops center view models
└── Views/            # All SwiftUI views
    ├── Charts/       # Reusable chart components
    ├── Dashboard/    # Per-section dashboard views
    ├── MenuBar/      # Menu bar extra
    ├── OpsCenter/    # Full-screen operations center
    ├── Settings/     # Settings and about
    └── Setup/        # First-run connection setup
```

## License

MIT License. See [LICENSE.md](LICENSE.md) for details.

---

Copyright &copy; 2026 Timothy Ellis, Fyrby Additive Manufacturing & Engineering
