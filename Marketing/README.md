# SpotClock 2.0 campaign

Quiet luxury: warm ivory, midnight blue, restrained brass, system serif typography. AppScreens (https://appscreens.com) inspired the large benefit headlines and coordinated screenshot story; no AppScreens templates or artwork were copied.

## Assets

- `Captures/duo-outer` and `Captures/duo-inner`: five genuine simulator captures per display, with isolated sample parking data. Outer: 1398 × 2034. Inner: 2853 × 2007.
- `Exports/duo-outer` and `Exports/duo-inner`: the five corresponding App Store posters, plus two optional first-slide headline concepts per display.
- `Exports/product-header.png`: opaque 3840 × 1646.
- `Exports/search-results.png`: opaque 3840 × 2560.
- `Exports/spotclock-2-preview.mp4`: portrait, 886 × 1920.
- `Exports/spotclock-2-inner-preview.mp4`: landscape, 1920 × 886.
- Both previews are 20-second tours assembled from the real app captures, with brief captions, High 4.0 H.264 video at 30 fps (11 Mbps target), and a silent stereo AAC track (48 kHz, 256 kbps target). They are screen montages rather than recordings of continuous interaction.
- `QA/media-validation.json` records the media checks. The decoded frames in `QA/` prove the exported videos render correctly.
- `Source/spotclock-parking-illustration.png` is AI-generated brand artwork, art directed for this campaign. It is used for the header and search image; it does not replace app UI in screenshots.

The listing's referenced assets are copied into `appStoreConnect/`. Source captures, exports, and listing media are intentionally committed so the campaign is reproducible.

## Rebuild

Run from the project root with the selected Xcode toolchain:

```sh
xcrun swiftc -parse-as-library -swift-version 6 -module-cache-path /private/tmp/spotclock-swift-cache Marketing/Tools/ExportCampaign.swift -o /private/tmp/spotclock-export-campaign
/private/tmp/spotclock-export-campaign
xcrun swiftc -parse-as-library -swift-version 6 -module-cache-path /private/tmp/spotclock-swift-cache Marketing/Tools/ExportPreview.swift -o /private/tmp/spotclock-export-preview
/private/tmp/spotclock-export-preview
/private/tmp/spotclock-export-preview --inner
xcrun swiftc -parse-as-library -swift-version 6 -module-cache-path /private/tmp/spotclock-swift-cache Marketing/Tools/VerifyMedia.swift -o /private/tmp/spotclock-verify-media
/private/tmp/spotclock-verify-media
xcrun swiftc -parse-as-library -swift-version 6 -module-cache-path /private/tmp/spotclock-swift-cache Marketing/Tools/StageListingAssets.swift -o /private/tmp/spotclock-stage-assets
/private/tmp/spotclock-stage-assets
```

The video encoder and decoder need access to the Mac's media services. A restricted sandbox can report “Cannot Encode” or “Cannot Decode”; run those export/verification commands with normal local permissions.

## Capture again

In a Debug build, Settings → Development → Open marketing capture studio opens an isolated in-memory store with sample stays. It does not request location or alarm permission, schedule alarms, restore a customer's timer, or write sample history/usage to disk. The `--marketing-capture` launch argument opens the same isolated environment for UI automation. Release builds have no entry to the studio.

Use the real app UI to capture Timer, Directions, duration selection, History, and Insights. Save both Duo displays at their native pixel sizes. Start a fresh studio for consistent sample history; ending a sample timer does not alter real history.

## Product pages and experiment

`Campaigns/campaign.json` contains the remote draft IDs, benefit-specific page orders, hypotheses, and traffic allocation. `Campaigns/remote-state.json` records the verified App Store Connect state: the 2.0 listing is synced, both custom pages have the new Duo screenshots/previews/header/search assets, and both optimization treatments have their checked screenshot orders. City stays leads with the countdown; Find your car leads with the walking route. The draft optimization experiment compares screenshot order: the default countdown, setup first, and directions first. Control gets 60% of traffic; each of two treatments gets 20% when the experiment is eventually started. The optional headline concepts are separate local creative alternatives, not part of that ordering experiment.

No conversion results exist yet. Activate only after version 2.0 is live and the creatives pass App Review. Review Apple’s reported confidence and conversion uplift after sufficient traffic; plan 14–28 days, within Apple’s 90-day maximum.

## Release gap

The installed iOS 27.1 runtime supports iPhone Duo only. Required Pro Max and 13-inch iPad screenshots must be captured on native simulator models when those become available. Existing 1.x iPhone 6.5-inch and iPad assets are retained on the main listing, custom pages, and treatments pending replacement. Duo captures have not been resized or cropped to impersonate those devices. The campaign is not ready for App Store submission until the required groups are updated.

Video delivery follows [Apple’s current App Preview specifications](https://developer.apple.com/help/app-store-connect/reference/app-information/app-preview-specifications/).
