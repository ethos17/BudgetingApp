# LedgerLens iOS

SwiftUI iOS app (iOS 17+) that connects to the LedgerLens NestJS backend.

## Run the backend

From the monorepo root:

```bash
pnpm install
pnpm -C apps/api exec prisma migrate deploy
pnpm -C apps/api exec prisma db seed
pnpm -C apps/api start
```

The API runs at **http://localhost:3000** (or set `PORT`).

Demo user: `demo@ledgerlens.local` / `Password123!`

## Create the Xcode project

1. Open Xcode → **File → New → Project**.
2. Choose **App** (iOS), then:
   - Product Name: **LedgerLens**
   - Team: your team
   - Organization Identifier: e.g. `com.ledgerlens`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployments: **iOS 17.0**
   - Uncheck "Include Tests" if you want to add them later.
3. Save the project inside this folder: `apps/ios/` (so the project lives at `apps/ios/LedgerLens.xcodeproj` and the app code is in `apps/ios/LedgerLens/`).
4. **Add the existing LedgerLens source files** to the app target:
   - In the Project Navigator, right‑click the `LedgerLens` group (the one that already has `LedgerLensApp.swift` and `ContentView.swift`).
   - Delete the default `ContentView.swift` if Xcode created one (we use our own views).
   - **Add the rest of the source tree**: drag the `LedgerLens` folder (Models, Services, ViewModels, Views, Utilities) into the LedgerLens group and ensure **Copy items if needed** is unchecked and **Add to targets: LedgerLens** is checked.
   - Ensure these are in the target:
     - `LedgerLensApp.swift`
     - `Models/Models.swift`
     - `Services/APIClient.swift`, `Services/SessionStore.swift`
     - `ViewModels/*.swift`
     - `Views/**/*.swift`
     - `Utilities/MoneyFormatter.swift`
     - `RootView.swift`, `MainTabView.swift`
5. **Info.plist**: In the project’s **Info** tab (or target **Info**), add App Transport Security so the Simulator can call `http://localhost` or `http://127.0.0.1`:
   - Add **App Transport Security Settings** (Dictionary).
   - Under it add **Exception Domains** (Dictionary).
   - Add key **localhost** (Dictionary) with **Allow Insecure HTTP Loads** = YES.
   - Add key **127.0.0.1** (Dictionary) with **Allow Insecure HTTP Loads** = YES.
   - Alternatively, add the existing `Info.plist` from this repo to the target and remove the default one if your template generated it.

## Base URL

The app uses **http://127.0.0.1:3000** by default so the Simulator can reach the backend on your Mac.

- To change it: edit `APIClient.shared.baseURL` in code (e.g. in `Services/APIClient.swift`), or add a simple settings screen that sets `APIClient.shared.baseURL` (e.g. from UserDefaults) before any requests.
- If the backend runs on the same Mac as the Simulator, **http://localhost:3000** or **http://127.0.0.1:3000** both work; 127.0.0.1 is often more reliable in Simulator.

## Build and run

1. Select the **LedgerLens** scheme and a Simulator (e.g. iPhone 16).
2. **Product → Run** (⌘R).
3. On the login screen use the demo user above, or sign up.

## Features

- **Auth**: Login, signup, logout; cookie-based session; on launch `GET /me` determines logged-in state; 401 forces logout.
- **Dashboard**: Month selector, summary cards (spent, income, count, excluded), recent transactions.
- **Transactions**: Month/account/status/search filters, include excluded toggle, list grouped by date, cursor pagination (“Load more”), swipe to exclude/include, tap for detail sheet (category picker, excluded toggle, save).
- **Accounts**: List of linked accounts; “Add account” sheet with provider/name/type and `POST /accounts/mock-link`; 409 shows “Account already linked”.
- **Settings**: Toggles for `include_pending_in_budget` and `notify_on_pending` (GET/PATCH); “Saved” feedback; Log out.

All API calls use a single `APIClient` with cookie-capable `URLSession`; no manual cookie handling.
