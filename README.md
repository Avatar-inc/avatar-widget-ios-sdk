# AvatarWidget iOS SDK

Thin iOS helper SDK that presents the shared Avatar chat panel in a native WebView, distributed via Swift Package Manager.

Customers never pass a panel URL — the host is baked into each release.

| Release | Panel host |
|---|---|
| UAT | `https://widget-uat.myegdev2.com` |
| Production | `https://widget.avatar.inc` |

Public API: `configure` · `identify` · `present` · `shutdown` · `events`

Current release: **`0.2.0-uat`**

---

## Installation (Swift Package Manager)

In Xcode: **File → Add Package Dependencies…**

> **⚠️ Common mistake:** Xcode has two similar-looking windows — **"Add Package Dependency"** (what you want here) and **"Add Package Collection"** (for a curated JSON list of many packages, not a single repo). If you paste this URL and see *"Received invalid response… Please make sure it is a package collection URL"*, you're in the wrong window. Cancel it and paste the URL into the search field of the **Add Package Dependency** window opened via **File → Add Package Dependencies…**.

```
https://github.com/Avatar-inc/avatar-widget-ios-sdk
```

Set **Dependency Rule** to **Exact Version**, then pick **`0.2.0-uat`** (UAT panel host).

Or in `Package.swift`:

```swift
.package(url: "https://github.com/Avatar-inc/avatar-widget-ios-sdk", exact: "0.2.0-uat")
```

Then add the `AvatarWidget` product to your target.

## Usage

```swift
import AvatarWidget

AvatarWidget.configure(publishableKey: "pk_live_xxxxxxxx")
AvatarWidget.identify(userId: "usr_123", hmac: token) // when identity_verification is enabled
AvatarWidget.present(from: UIApplication.shared.topController!)
```

Default resolve (no `AVATAR_WIDGET_ENV`) uses the UAT panel. Production builds set `AVATAR_WIDGET_ENV=production` at package resolve / CI.

---

## Requirements

| Platform | Minimum |
|---|---|
| iOS | 15.0 · UIKit + WebKit · no third-party deps |

## Repo layout

```
Package.swift                 # SPM manifest
Sources/AvatarWidget/         # SDK sources
```

## Versioning

| Tag | SPM |
|---|---|
| `0.2.0-uat` | UAT panel |

## Android

The Android SDK is published separately to Maven — see the Android SDK documentation.

## License

MIT — see [LICENSE](LICENSE).
