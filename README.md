# <div align="center"><img src="snapshots/logo.png" width="150px" alt="ErrorX Logo"/></div>

<div align="center">
  <h1>ErrorX</h1>
  <p><em>A powerful multi-platform ErrorX BDIX client based on ClashMeta</em></p>

  <!-- Modern Badges -->
  <p>
    <a href="https://github.com/FakeErrorX/ErrorX/releases">
      <img src="https://img.shields.io/github/v/release/FakeErrorX/ErrorX?style=flat-square&logo=github&color=00B0FF&logoColor=white&labelColor=000000" alt="Release"/>
    </a>
    <a href="https://github.com/FakeErrorX/ErrorX/releases">
      <img src="https://img.shields.io/github/downloads/FakeErrorX/ErrorX/total?style=flat-square&logo=github&color=00B0FF&logoColor=white&labelColor=000000" alt="Downloads"/>
    </a>
    <a href="LICENSE">
      <img src="https://img.shields.io/github/license/FakeErrorX/ErrorX?style=flat-square&color=00B0FF&logoColor=white&labelColor=000000" alt="License"/>
    </a>
    <a href="https://t.me/ErrorX_BD">
      <img src="https://img.shields.io/badge/Telegram-Channel-00B0FF?style=flat-square&logo=telegram&logoColor=white&labelColor=000000" alt="Telegram"/>
    </a>
  </p>

  <!-- Preview Images -->
  <div>
    <img src="snapshots/desktop.gif" width="600px" alt="Desktop Preview"/>
    <br/>
    <img src="snapshots/mobile.gif" height="400px" alt="Mobile Preview"/>
  </div>

  <!-- Quick Links -->
  <p>
    <a href="#-download"><kbd>Download</kbd></a> •
    <a href="#-features"><kbd>Features</kbd></a> •
    <a href="#%EF%B8%8F-build-guide"><kbd>Build</kbd></a> •
    <a href="#-platforms"><kbd>Platforms</kbd></a>
  </p>
</div>

## ✨ Why ErrorX?

<table>
<tr>
<td width="50%">

### 🛡️ Privacy & Security
- **Open Source**: Transparent and community-driven
- **Ad-Free**: No tracking, no ads, just pure functionality
- **Secure Core**: Built on reliable ClashMeta technology

</td>
<td width="50%">

### 🎨 Modern Design
- **Material You**: Adaptive and beautiful interface
- **Dark Mode**: Easy on your eyes
- **Responsive**: Perfect on any screen size

</td>
</tr>
</table>

## 🚀 Features

<table>
<tr>
<td width="33%">

### 🎯 Core
- Material You Design
- WebDAV Sync
- Multi-language
- Profile Management
- System Proxy

</td>
<td width="33%">

### ⚡ Advanced
- Custom Rules Engine
- Traffic Analytics
- Quick Actions
- Subscription Manager
- Real-time Stats

</td>
<td width="33%">

### 🌈 Experience
- Intuitive Interface
- Seamless Updates
- Cross-platform Sync
- Easy Configuration
- Active Community

</td>
</tr>
</table>

## 💻 Platforms

<div align="center">
  <table>
    <tr>
      <td align="center" width="25%">
        <img src="snapshots/android.png" width="64px" alt="Android"/>
        <br/>
        <b>Android</b>
      </td>
      <td align="center" width="25%">
        <img src="snapshots/windows.png" width="64px" alt="Windows"/>
        <br/>
        <b>Windows</b>
      </td>
      <td align="center" width="25%">
        <img src="snapshots/macos.png" width="64px" alt="macOS"/>
        <br/>
        <b>macOS</b>
      </td>
      <td align="center" width="25%">
        <img src="snapshots/linux.png" width="64px" alt="Linux"/>
        <br/>
        <b>Linux</b>
      </td>
    </tr>
  </table>
</div>

## 📱 Quick Actions

### Android Integration
```kotlin
// Start VPN Service
net.errorx.vpn.action.START

// Stop VPN Service
net.errorx.vpn.action.STOP

// Change Profile
net.errorx.vpn.action.CHANGE
```

### Linux Dependencies
```bash
# Install required packages
sudo apt-get install appindicator3-0.1 libappindicator3-dev
sudo apt-get install keybinder-3.0
```

## 🛠️ Build Guide

### Prerequisites
<table>
<tr>
<td width="33%">

### 🔧 Required
- Flutter SDK
- Golang
- Git

</td>
<td width="33%">

### 📱 Android
- Android SDK
- Android NDK
- ANDROID_NDK env

</td>
<td width="33%">

### 🖥️ Desktop
- GCC compiler
- Inno Setup (Windows)
- Platform SDKs

</td>
</tr>
</table>

### Build Commands

1. **Setup Repository**
   ```bash
   git submodule update --init --recursive
   ```

2. **Platform Builds**
   ```bash
   # Android Build
   dart ./setup.dart android

   # Windows Build (arm64/amd64)
   dart ./setup.dart windows --arch <arm64|amd64>

   # Linux Build (arm64/amd64)
   dart ./setup.dart linux --arch <arm64|amd64>

   # macOS Build (arm64/amd64)
   dart ./setup.dart macos --arch <arm64|amd64>
   ```

## 📥 Download

<div align="center">
  <a href="https://github.com/FakeErrorX/ErrorX/releases">
    <img src="snapshots/get-it-on-github.svg" alt="Get it on GitHub" width="240px"/>
  </a>
</div>

---

<div align="center">
  <p>Made with ❤️ by ErrorX Team</p>
  <p>
    <a href="https://github.com/FakeErrorX/ErrorX/issues">Report Bug</a>
    •
    <a href="https://github.com/FakeErrorX/ErrorX/discussions">Discussions</a>
    •
    <a href="https://t.me/ErrorX_BD">Join Community</a>
  </p>
</div>