# vibe-screenshot

A lightweight, modern desktop screenshot utility built with **Qt 6 + QML**, designed for quick and elegant screen captures on Windows.

## ✨ Features

- **Region Capture** — Drag to select any area of the screen, with real-time dimension overlay
- **Full Screen Capture** — Capture the entire screen in one shot
- **Global Hotkeys** — `Ctrl+Shift+A` for region, `Ctrl+Shift+S` for full screen (works even when the app is minimized)
- **Preview Windows** — Each screenshot opens a floating preview card with hover controls
- **One-Click Actions** — Copy to clipboard or save to file directly from the preview
- **System Tray** — Runs quietly in the tray, double-click to show the control panel
- **Material Design** — Clean, modern UI with frameless window, rounded corners, and elevation shadows

## 🛠 Tech Stack

| Layer | Technology |
|-------|-----------|
| UI | Qt Quick (QML), Qt Quick Controls 2 |
| Core Logic | C++17, Qt 6 |
| Build System | CMake 3.16+ |
| Platform | Windows (Win32 global hotkeys via `nativeEventFilter`) |

## 📋 Requirements

- **Qt 6.10+** (Quick, QuickControls2, Widgets modules)
- **CMake 3.16+**
- **MinGW 64-bit** (or MSVC 2019+)
- **Windows 10/11**

## 🚀 Build

```bash
cmake -S . -B build -G "MinGW Makefiles" \
  -DCMAKE_PREFIX_PATH="C:/Qt/6.11.1/mingw_64" \
  -DCMAKE_BUILD_TYPE=Release

cmake --build build
```

Or open `CMakeLists.txt` in Qt Creator and build with the **Desktop Qt 6.11.1 MinGW 64-bit** kit.

## ⌨️ Shortcuts

| Shortcut | Action |
|----------|--------|
| `Ctrl+Shift+A` | Start region capture |
| `Ctrl+Shift+S` | Capture full screen |
| `Esc` | Cancel region selection |

## 📁 Project Structure

```
vibe-screenshot/
├── main.cpp                  # Entry point, system tray, hotkey registration
├── screenshotmanager.h/.cpp  # Core capture logic, clipboard, file I/O
├── Main.qml                  # Control panel UI
├── RegionSelector.qml        # Full-screen overlay for region selection
├── PreviewWindow.qml         # Floating preview card for each screenshot
└── CMakeLists.txt            # CMake project configuration
```

## 📄 License

MIT
