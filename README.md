# Cinemana TV (Custom Android TV Client)

A modern, high-performance Flutter Android TV frontend for Cinemana Shabakaty (`https://cinemana.shabakaty.com/CTV/`), engineered for 10-foot TV screens and D-Pad remote navigation.

---

## 🌟 Key Features

1. **Cinematic OTT UI (Netflix / Apple TV+ Style)**:
   - Dynamic Hero Banner with featured titles, backdrops, ratings, and instant playback.
   - Horizontal scrolling content shelves (Latest Movies, TV Shows, Trending, Curated Categories).
   - Fluid focus animations with scaling, high-contrast borders, and neon glow indicators.
   - Collapsible TV Side Navigation Dock (Search, Home, Movies, TV Shows, Watchlist, Settings).

2. **Hardware-Accelerated Video Engine**:
   - Powered by `media_kit` (direct native `libmpv` pipeline) with 4K (2160p), 1080p, 720p, and SD stream decoding.
   - Custom Leanback On-Screen Display (OSD) with auto-hide.
   - Quick D-Pad controls: Left/Right to seek (-10s / +10s), Center to Play/Pause, Skip Intro button (+85s).
   - In-player Video Quality selector (2160p / 1080p / 720p / 480p) preserving playback timestamp.
   - Subtitle switcher (Arabic SRT/VTT, English, or Off).

3. **Complete Content Support**:
   - Movies & Series catalog with infinite pagination.
   - Series Seasons tabs and episode selectors with thumbnails and durations.
   - Related titles recommendations.
   - On-screen D-Pad virtual keyboard for instant search.
   - Local Watchlist and Continue Watching playback history with progress tracking.

---

## 📦 Built APK

The Android TV APK is built and ready at:
```
build/app/outputs/flutter-apk/app-debug.apk
```

### Installing onto Android TV / Fire TV via ADB:
```bash
# Connect to your Android TV IP address
adb connect <YOUR_TV_IP>:5555

# Install the APK
adb install -r build/app/outputs/flutter-apk/app-debug.apk
```

---

## 💻 Local Testing on Windows Desktop

You can also run and test the app directly on your PC:
```bash
flutter run -d windows
```
Keyboard / Remote controls:
- **Arrow Keys**: D-Pad Navigation (Up / Down / Left / Right)
- **Enter / Space**: Select / Play / Pause
- **Esc / Backspace**: Back / Close OSD
