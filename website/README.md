# CricStatz Website

This folder contains a modern, static landing page that you can host on the web to let users download the CricStatz mobile app.

## Structure

- `index.html` – main landing page with:
  - Hero section describing CricStatz.
  - A **Download Android APK** button.
  - A live-updating mockup scoreboard.
- `styles.css` – Contains the application's design system, including a dark red/black aesthetic inspired by the logo, glassmorphism UI, and keyframe animations.
- `icons/` – Contains static assets like the application logo.

## Design

The UI has been recently upgraded to feature a dark, premium aesthetic that uses `logo.png` as a background element and derives its Crimson Red (`#ae1921`) accent directly from it. The page also features entry animations and hover states to feel responsive and alive.

## How to use

1. **Build a release APK** of your Flutter app:

   ```bash
   cd app
   flutter build apk --release
   ```

   This will create something like:
   - `app/build/app/outputs/flutter-apk/app-release.apk`

2. **Copy the APK into this website folder**:

   ```bash
   mkdir -p website/downloads
   cp app/build/app/outputs/flutter-apk/app-release.apk website/downloads/CricStatz-latest.apk
   ```

   The `index.html` file already points the download button to:
   - `downloads/CricStatz-latest.apk`

3. **Host the `website/` folder** with any static hosting provider (e.g., GitHub Pages, Netlify, Vercel). The document root for the site should be this `website` directory.

4. **Share the URL**: Users can visit your site in the browser, tap **Download Android APK**, and install the app on their devices.
