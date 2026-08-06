# iOS WebView Apps — Codemagic CI/CD Repo

This repository contains 7 native iOS apps, each a thin WKWebView wrapper around a
web app/site. There is no need for a Mac — builds, code signing, and TestFlight
uploads are all handled by [Codemagic](https://codemagic.io) CI/CD.

Each app lives under `apps/{AppName}/` as a standalone Xcode project
(`{AppName}.xcodeproj`), and `codemagic.yaml` at the repo root defines one build
workflow per app.

## Apps in this repo

- **Creative Music Nexus** (`CreativeMusicNexus`) — wraps [https://creativemusicnexus.com](https://creativemusicnexus.com), bundle ID `com.jameswilliams.creativemusic`
- **CryptoMine Connect** (`CryptoMineConnect`) — wraps [https://crypto-mine-connect--supercleanjames.replit.app](https://crypto-mine-connect--supercleanjames.replit.app), bundle ID `com.jameswilliams.cryptomineconnect`
- **Apple Sentinel Security** (`AppleSentinel`) — wraps [https://apple-sentinel--supercleanjames.replit.app](https://apple-sentinel--supercleanjames.replit.app), bundle ID `com.jameswilliams.applesentinel`
- **WealthSage AI** (`WealthSageAI`) — wraps [https://wealth-sage-supercleanjames.replit.app](https://wealth-sage-supercleanjames.replit.app), bundle ID `com.jameswilliams.wealthsage`
- **IOT AI Chip Market** (`IOTAIChipMarket`) — wraps [https://ai-chip-marketplace-1.replit.app](https://ai-chip-marketplace-1.replit.app), bundle ID `com.jameswilliams.iotaichip`
- **GoodDoctor Wellness** (`GoodDoctorWellness`) — wraps [https://wellness-guide-and-digital-asset.replit.app](https://wellness-guide-and-digital-asset.replit.app), bundle ID `com.jameswilliams.gooddoctor`
- **CoinBot Trade** (`CoinBotTrade`) — wraps [https://coin-bot-trade-supercleanjames.replit.app](https://coin-bot-trade-supercleanjames.replit.app), bundle ID `com.jameswilliams.coinbottrade`

## 1. Connect this repo to Codemagic

1. Push this repository to GitHub (create a new repo and push these files).
2. Go to [codemagic.io](https://codemagic.io) and sign in with your GitHub account.
3. Click **Add application**, select this repository, and let Codemagic detect it.
   Codemagic will pick up the `codemagic.yaml` file at the repo root and show one
   workflow per app (e.g. `creative-music-nexus`, `cryptomine-connect`, etc.).
4. In the app settings in Codemagic, go to **Environment variables** and add the
   following 4 variables (mark the key/secret ones as "Secure"):
   - `APP_STORE_CONNECT_ISSUER_ID`
   - `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - `APP_STORE_CONNECT_PRIVATE_KEY`
   - `CERTIFICATE_PRIVATE_KEY`

   These are used for automatic code signing and TestFlight publishing on Apple's
   App Store Connect API.

## 2. Get your App Store Connect API key

1. Go to [appstoreconnect.apple.com](https://appstoreconnect.apple.com) and sign in.
2. Navigate to **Users and Access** → **Integrations** → **App Store Connect API**.
3. Click the **+** button to generate a new API key with **App Manager** access
   (or higher).
4. Note down:
   - The **Issuer ID** (shown at the top of the Integrations page) →
     `APP_STORE_CONNECT_ISSUER_ID`
   - The **Key ID** of the key you just created →
     `APP_STORE_CONNECT_KEY_IDENTIFIER`
   - Download the `.p8` private key file (you can only download it once) and
     paste its full contents (including the `-----BEGIN PRIVATE KEY-----` /
     `-----END PRIVATE KEY-----` lines) into
     `APP_STORE_CONNECT_PRIVATE_KEY`
5. `CERTIFICATE_PRIVATE_KEY` is used by Codemagic's automatic signing to encrypt
   and reuse your distribution certificate's private key across builds. You can
   generate one yourself (e.g. `openssl genrsa 2048`) and paste its PEM contents,
   or let Codemagic generate/manage this for you the first time automatic signing
   runs — check Codemagic's docs on [iOS code signing](https://docs.codemagic.io/yaml-code-signing/signing-ios/)
   for the latest guidance.

Each app must also already exist as an app record in App Store Connect (matching
its bundle identifier) before the workflow can upload a build to TestFlight.

## 3. Trigger a build

You can trigger a build in two ways:

- **Push to `main`** — every workflow in `codemagic.yaml` is configured to
  trigger automatically on a push to the `main` branch.
- **Manually in Codemagic** — open the app in the Codemagic dashboard, pick the
  workflow for the app you want to build, and click **Start new build**.

A successful build archives the app, exports a signed `.ipa`, and uploads it to
TestFlight automatically.

## Project structure

```
ios-repo/
  codemagic.yaml
  README.md
  apps/
    {AppName}/
      {AppName}.xcodeproj/
        project.pbxproj
      {AppName}/
        AppDelegate.swift
        SceneDelegate.swift
        ViewController.swift
        Info.plist
        LaunchScreen.storyboard
        Assets.xcassets/
          AppIcon.appiconset/Contents.json
          AccentColor.colorset/Contents.json
      exportOptions.plist
```

Each `ViewController.swift` loads its app's URL in a `WKWebView`, showing a
spinner while loading (with a 3 second delay to allow for Replit cold starts) and
a **Retry** button if the load fails.
