# BiteNYC iOS

SwiftUI client for BiteNYC — the AI-powered NYC restaurant, cafe, and date-night
discovery app. It consumes the `apps/api` Fastify backend (search, chat,
restaurants, filters, moderation).

## Requirements

- macOS with **Xcode 15+** (the app targets iOS 17)
- [XcodeGen](https://github.com/yonyz/XcodeGen): `brew install xcodegen`

> The repo intentionally does not commit a generated `.xcodeproj`. It is created
> from `project.yml` so the project file never drifts or conflicts.

## Generate & run

```bash
cd apps/ios
xcodegen generate
open BiteNYC.xcodeproj
```

Then pick an iPhone simulator and Run.

## Point the app at your API

The API base URL is read from `Info.plist` -> `BiteNYCAPIBaseURL`
(default `http://localhost:4000`).

- **Simulator:** `http://localhost:4000` works (run `pnpm dev:api` first).
- **Physical device:** change it to your Mac's LAN IP, e.g.
  `http://192.168.1.20:4000`, and make sure the device is on the same network.
  (App Transport Security already allows local networking.)

## Structure

```
BiteNYC/
├── App/            # @main entry + root TabView
├── Core/           # config, theme, navigation routes
├── Networking/     # Codable models + async URLSession APIClient
├── UI/             # shared components (cards, chips, flow layout, badges)
└── Features/
    ├── Home/       # Ask-AI entry, occasion chips, neighborhood presets
    ├── Search/     # grounded AI search results
    ├── Explore/    # list/map toggle + filters
    ├── Detail/     # hero, dishes, booking, clips, gallery, map, similar
    ├── Chat/       # conversational concierge
    └── Saved/      # local saved lists (UserDefaults)
```

## Notes

- Reservations open official deep links (Resy → OpenTable → Tock → Direct);
  no in-app booking yet, matching the MVP plan.
- Saved lists persist locally via `UserDefaults` (no account required yet).
- Clips open TikTok/YouTube URLs in the browser (embeds come later).
