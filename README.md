# <div align="center">⚡ ErrorX</div>

<div align="center">
  
  <!-- Badges with modern design -->
  [![Release](https://img.shields.io/github/v/release/FakeErrorX/ErrorX?style=for-the-badge&logo=github&color=blue&logoColor=white)](https://github.com/FakeErrorX/ErrorX/releases)
  [![Downloads](https://img.shields.io/github/downloads/FakeErrorX/ErrorX/total?style=for-the-badge&logo=github&color=blue&logoColor=white)](https://github.com/FakeErrorX/ErrorX/releases)
  [![License](https://img.shields.io/github/license/FakeErrorX/ErrorX?style=for-the-badge&color=blue&logoColor=white)](LICENSE)
  [![Telegram](https://img.shields.io/badge/Telegram-Channel-blue?style=for-the-badge&logo=telegram&logoColor=white)](https://t.me/ErrorX_BD)

  <br/>
  
  *A powerful multi-platform ErrorX BDIX client based on ClashMeta*
  
  [📥 Download](#download) • [🚀 Features](#features) • [🛠️ Build](#build) • [📱 Platforms](#platforms)

</div>

---

## 🌟 Highlights

- 🔒 **Privacy First**: Open-source and completely ad-free
- 🎨 **Modern UI**: Material You Design with Surfboard-like interface
- 🌓 **Customizable**: Multiple color themes and dark mode support
- ☁️ **Sync Ready**: WebDAV support for seamless data synchronization
- 🔄 **Flexible**: Subscription link support
- 📱 **Adaptive**: Optimized for all screen sizes

## 🚀 Features

<table>
<tr>
<td>

### 🎯 Core Features
- Material You Design
- WebDAV Sync Support
- Dark Mode
- Subscription Management
- Multi-language Support

</td>
<td>

### 💫 Advanced Features
- Custom Rules
- Traffic Statistics
- Profile Management
- System Proxy
- Quick Actions

</td>
</tr>
</table>

## 📱 Platforms

ErrorX runs seamlessly on:

- **🤖 Android**
- **🪟 Windows**
- **🍎 macOS**
- **🐧 Linux**

## 🛠️ Installation

### 📱 Android

Quick actions support:
```bash
net.errorx.vpn.action.START
net.errorx.vpn.action.STOP
net.errorx.vpn.action.CHANGE
```

### 🐧 Linux

Required dependencies:
```bash
sudo apt-get install appindicator3-0.1 libappindicator3-dev
sudo apt-get install keybinder-3.0
```

## 📥 Download

<div align="center">
  <a href="https://github.com/FakeErrorX/ErrorX/releases">
    <img src="snapshots/get-it-on-github.svg" alt="Get it on GitHub" width="240px"/>
  </a>
</div>

## 🛠️ Build Guide

### Prerequisites
- Flutter SDK
- Golang environment
- Git

### Steps

1. Clone and update submodules:
   ```bash
   git submodule update --init --recursive
   ```

2. Build for your platform:

   <details>
   <summary>🤖 Android Build</summary>
   
   Requirements:
   - Android SDK
   - Android NDK
   - Set ANDROID_NDK environment variable
   
   ```bash
   dart ./setup.dart android
   ```
   </details>

   <details>
   <summary>🪟 Windows Build</summary>
   
   Requirements:
   - Windows system
   - GCC compiler
   - Inno Setup
   
   ```bash
   dart ./setup.dart windows --arch <arm64 | amd64>
   ```
   </details>

   <details>
   <summary>🐧 Linux Build</summary>
   
   ```bash
   dart ./setup.dart linux --arch <arm64 | amd64>
   ```
   </details>

   <details>
   <summary>🍎 macOS Build</summary>
   
   ```bash
   dart ./setup.dart macos --arch <arm64 | amd64>
   ```
   </details>

---

<div align="center">
  Made with ❤️ by ErrorX Team
</div>
