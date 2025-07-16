## v1.0.3

- Update Build template (#18)


- v1.0.3 (#17)


- Update Build template

- Updated .github/release_template.md and README.md with improved formatting, modern badges, clearer download/platform sections, and enhanced instructions for users. Also updated macOS build target in build.yaml to use macos-15 for arm64 builds. These changes improve clarity, accessibility, and visual appeal for users and contributors.

- Added Proxies UI with modern glassmorphism style

- Refactors the proxies UI components to use a modern glassmorphism-inspired design, including animated gradients, rounded corners, and updated iconography. Enhances ProxyCard, group headers, action buttons, and tab bars with new layouts, transitions, and visual effects. Updates the group and proxy selection interactions for improved clarity and feedback. Bumps version to 1.0.3+202507151.

- Add info for TUN and System Proxy

- Introduced TunInfoDialog and SystemProxyInfoDialog components to provide users with detailed explanations of TUN and System Proxy modes. Updated quick options UI to include info buttons that open these dialogs. Added new localized strings for the mode descriptions.

- Add outbound mode info dialog

- Introduces an info dialog for outbound modes, accessible via an info icon in the OutboundMode widget. Adds localized descriptions for Rule, Global, and Direct modes in the l10n files. Updates CommonCard and InfoHeader to support custom actions, enabling the new info button.

- Remove QR code scanning feature

- This commit removes the QR code scanning feature, including the scan page, related UI, and all code paths for adding profiles via QR code. It also removes the image_picker dependency and cleans up plugin registrations and references for file_selector and image_picker across all platforms. The pubspec and lock files are updated to reflect these dependency removals.

- Update CHANGELOG.md
- Update build.yaml
- Update CHANGELOG.md

## v1.0.2
- Added AES-256 encryption in Go core
- Added some security improvements
- Switched to in-memory encryption
- Refactored profile system for full disk encryption
- Removed YAML profile editor and legacy components
- Redesigned login UI with modern layout
- Enhanced error handling, retry logic, and default settings

## v1.0.1
- Added BDIX FTP Support
- Fix License Re-entry issues

## v1.0.0
- Added support for: Windows ARM64, Linux ARM64, macOS ARM64, Android
- Core: Performance optimization, stability improvements, storage corruption detection
- Build: Updated Flutter version, Go version, build scripts and workflows
- System: Windows admin auto-launch, system proxy switch, WebDAV support
- Android VPN: IPv6 inbound, system DNS, immersion display, shortcuts, process optimization
- Windows: TUN support, country flags, storage corruption detection
- Network: Proxy-only traffic stats, IP detection, URL testing, delay optimization
- DNS: Strategy optimization, override support, default options improvement
- Traffic: Connection monitoring, request tracking, proxy management
- Dashboard & Desktop: Complete remake, background performance optimization
- Navigation: Window position memory, hotkeys, animate optimization
- Proxies UI: Expansion panels, adjustable card size, column configuration
- Theme: New lightBlue color, font family options, popup menu updates
- Search: Added for connections, requests, logs, access control
- Profiles: Sorting, backup/recovery, QR code import, auto-update
- Proxy: Group sorting, provider optimization, icon configuration
- Security: VPN protection, bypass domain settings, access control
- Performance: Delayed sorting, TCP concurrent switch, memory optimization
- Logging: Export support, optimization, keyword search
- Android: Hidden from recent tasks, shortcuts, immersion mode
- Windows: Administrator auto-launch, storage protection, tray optimization
- Cross-platform: File editor, geoip support, UA selector
- Settings: Route address, timeout configuration, test URL customization
- Traffic: Proxy-only statistics, connection tracking
- Health: URL testing, proxy checking, network monitoring
- Resources: Page optimization, geoData URL configuration
- System: Memory management, IPv6 switch, auto GC on trim
- Auto-changelog generation
- Local backup and recovery
- Compatibility mode
- Telegram integration
- Mobile scanner update
- File picker enhancement
- Better window management
- Mouse drag scroll support
- Hidden group support
- Tab index memory
- Access control improvements
- Release automation
