# SubCheck — iCloud, Dynamic Island and App Store guide

Written 2026-11-01, updated 2026-11-05. The app now builds with Xcode (`DEVELOPER_DIR=/Applications/Xcode.app/Contents/Developer`) and the unit tests pass; what is still unverified lives in `TESTPLAN.md` (needs a real iPhone).

## 1. Seeing the Dynamic Island

The Live Activity (`SubCheckLiveActivity.swift`) is shown by the **system**, not inside the app:

1. Use an **iPhone 14 Pro or newer** (physical, or Simulator "iPhone 15 Pro"+). Other iPhones show the same activity on the **Lock Screen** only.
2. iOS Settings > SubCheck > **Live Activities: on** (Simulator: Settings app > SubCheck).
3. In SubCheck: **Ajustes > Ilha Dinâmica > Testar Ilha Dinâmica** (needs Pro or the 7-day trial and at least one active subscription). The message under the button says what happened or why it failed (permission off, no subscriptions, system error).
4. **Leave the app** (swipe home, or lock the phone). While SubCheck is in the foreground the island stays empty — that is normal iOS behaviour.
5. Long-press the island to expand it. Tapping opens the app on that subscription.

The activity is also (re)started automatically on every launch and whenever subscriptions change. iOS ends an activity after 8 hours (12 on the Lock Screen); opening the app starts a fresh one.

## 2. iCloud sync

What was built: optional **Settings > Sincronizar com iCloud** (Pro). It switches the SwiftData store to CloudKit (`iCloud.com.viniciusmicarelli.subcheck`, private database). Takes effect on next launch. The widget extension opens the same file **without** CloudKit; its changes reach iCloud when the app next runs.

Model changes made for CloudKit: every stored property now has a default value; `User` and `PaymentMethod` (unused, and `PaymentMethod` stored a CVV) were removed from the schema because CloudKit rejects `@Attribute(.unique)`. Sample data is now seeded in DEBUG builds only, once, so a second device never uploads fake subscriptions. `PaymentLedger.removeDuplicates` cleans up repeated history rows created by two devices before they synced.

You must do (cannot be done from code):
1. **Paid Apple Developer Program account** (US$99/yr). Free "Personal Team" signing cannot use iCloud/CloudKit, push or in-app purchases to production — the build will fail to sign with the new entitlements until the team is a paid one.
2. Xcode > SubCheck target > **Signing & Capabilities**: confirm *iCloud (CloudKit)* with container `iCloud.com.viniciusmicarelli.subcheck`, *Push Notifications*, *Background Modes > Remote notifications*, *App Groups*. Xcode creates the container in your account on first build.
3. Run on **two real devices** (or one device + one simulator signed in to iCloud), turn the toggle on in both, relaunch, add a subscription on one and watch it arrive on the other.
4. **Before App Store release:** open the [CloudKit Dashboard](https://icloud.developer.apple.com), select the container, and **Deploy Schema Changes to Production**. Without this, sync works in development builds and silently does nothing for App Store users. Re-deploy whenever a model gains a field.
5. `aps-environment` in `Config/SubCheck.entitlements` is `development`; Xcode swaps it to `production` when archiving for distribution.

Known limits: no conflict UI (last writer wins per record); the widget does not sync live; notifications are rescheduled on launch for subscriptions that arrived from another device.

## 3. App Store checklist

**Decide first (cannot change later):**
- **Bundle ID.** Current: `com.viniciusmicarelli.subcheck` (reverse-DNS, permanent once the app record exists in App Store Connect). It is already applied across `project.yml` (app + widgets + tests), both `.entitlements` (App Group, iCloud container), `SharedModelContainer` (`appGroupID`, `cloudKitContainerID`), `KeychainStore.service`, `StoreService.proProductID`, `Config/SubCheck.storekit` and `Config/Info.plist`; if you ever change it again, update all of them together and re-run `xcodegen generate`.
- **Deployment target** is iOS 17.0 in `project.yml`, so iOS 17 and newer are supported.

**Accounts and records**
1. Enroll in the Apple Developer Program. Create the **App ID** with capabilities: App Groups, iCloud/CloudKit, Push, In-App Purchase.
2. App Store Connect > New App: name, primary language pt-BR, bundle ID, SKU. Check the name "SubCheck" is available.
3. **In-App Purchase**: create a *Non-Consumable* with product ID `com.viniciusmicarelli.subcheck.pro.lifetime`, price, localized name/description (pt-BR + en), and a review screenshot of the paywall. Attach it to the first app version.
4. Agreements, Tax and Banking: complete the *Paid Apps* agreement or IAP will not work in review.

**Metadata**
- Ready-to-paste copy (name, subtitle, description, keywords, promotional text, what's new — pt-BR + en) and the required URLs/IAP fields are in `APPSTORE_LISTING.md`.
- Privacy Policy URL and Support URL (required). They are already set in `SubCheck/Services/AppLinks.swift` and served from the `docs/` folder via GitHub Pages (`https://viniciusmicarelli.github.io/sub-check/`); enable Pages under Settings > Pages > Deploy from a branch (`main` / `/docs`).
- App Privacy ("nutrition label"): the app has no analytics or tracking → *Data Not Collected*. It calls `api.frankfurter.app` for exchange rates (no user data) and fetches icon URLs the user types. iCloud data lives in the user's own private database. Keep `PrivacyInfo.xcprivacy` (added, UserDefaults reason codes) in both targets; re-check if you add SDKs.
- Export compliance: `ITSAppUsesNonExemptEncryption = NO` is set in Info.plist (only standard HTTPS/Keychain).
- Age rating questionnaire, category (Finance or Productivity), keywords, description, promotional text, what's new — in pt-BR and en.
- **Screenshots**: 6.9" iPhone only (the 1.0 build is iPhone-only: `TARGETED_DEVICE_FAMILY: "1"`, Mac "Designed for iPad" opted out). Show the dashboard, insights, widgets, Dynamic Island, paywall. In the simulator, `-onboardingDone 1 -seedSampleData` launches straight into a populated dashboard (Debug builds only).
- Review notes: explain the 7-day local trial and how to reach the Pro paywall; no login needed.

**Build and submit**
1. Set `MARKETING_VERSION` (e.g. 1.0) and bump `CURRENT_PROJECT_VERSION` for every upload (in `project.yml`, then `xcodegen generate`).
2. Xcode > Product > **Archive** (Release) > Distribute App > App Store Connect > Upload.
3. **TestFlight first**: internal testers, then a small external group. Test purchase with a Sandbox tester, restore purchase on a second device, iCloud sync, widgets, Live Activity from a TestFlight build (not Xcode-run).
4. Submit for review. Typical rejection causes for this kind of app: missing privacy policy URL, IAP not attached to the version, paywall not showing the price or a restore button (both present), broken links (the cancel-guide URLs were written from memory — click every one), crashes on a clean install (verify with the app deleted first).

**Before the first release, also**
- Remove or review `.kilo/`, `AGENTS.md`, `PLAN.md`, `TIMELINE.md` (stale planning files, untracked).
- Run `TESTPLAN.md` on a real iPhone (about 30 minutes) before the first TestFlight build.
- The trial start date lives in the Keychain; a reinstall keeps it by design.
- Verify the app on a clean install: it now opens with an empty list (no sample data) and the onboarding.

## 4. Branches

| Branch | Para quê |
|---|---|
| `main` | O que já está publicado e estável (inclui o site em `docs/`, servido pelo GitHub Pages). Só recebe merges de `release/*`. |
| `develop` | Integração: onde as novidades se juntam e onde o TestFlight é gerado. |
| `feature/<nome>` | Uma novidade por branch, criada a partir de `develop` e mesclada de volta nela. |
| `fix/<nome>` | Correção pequena, mesmo fluxo da `feature/*`. |
| `release/<versão>` | Congela uma versão (ex.: `release/1.0`): só bugs de última hora. Depois entra na `main` e ganha a tag `v1.0`. |

Fluxo:

```bash
git switch develop && git pull
git switch -c feature/historico-reajustes     # trabalha e faz commits
git switch develop && git merge --no-ff feature/historico-reajustes
git push -u origin develop

# Ao lançar:
git switch -c release/1.0 develop             # sobe o build para a App Store aqui
git switch main && git merge --no-ff release/1.0
git tag v1.0 && git push origin main --tags
git switch develop && git merge main          # traz de volta qualquer ajuste da release
```

Regras: nunca fazer `push --force` na `main` nem na `develop`; subir o número de build (`CURRENT_PROJECT_VERSION`) a cada envio ao TestFlight.
