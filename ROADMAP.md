# SubCheck — Roadmap & Brand

> `PLAN.md` / `TIMELINE.md` are stale (they describe an Android/Room app with 7 tabs). This file reflects the real iOS code as of 2026-10-31.

## Where the app is

SwiftUI + SwiftData, iOS 27, XcodeGen. Shipped: dashboard KPIs, subscriptions CRUD, categories, history, analysis charts (timeline, forecast, heatmap, cost/day), 3 widgets + Live Activity, localization (pt-BR/en), multi-currency, reminders, one-time Pro purchase (StoreKit 2) with 7-day local trial.

## Gaps found

| Area | Gap | Status |
|---|---|---|
| Identity | AppIcon and AccentColor catalogs were empty | **Done** — icon (light/dark/tinted), accent color, `BrandMark` |
| KPIs | Only 4 tiles | **Done** — +4 (30-day outflow, cost/day, biggest sub, yearly savings) + next-charge pill in hero |
| Value of Pro | Paywall was a feature list only | **Done** — Insights (Pro), Free-vs-Pro table, teaser of 1 insight for free users |
| Tests | No unit tests at all | **Done (first pass)** — `SubCheckTests` covers insights + billing math; `PaymentLedger` still untested |
| Trial | Stored in UserDefaults; reinstall resets it | **Done** — Keychain + UserDefaults, oldest date wins |
| Paywall | No restore-on-launch banner, no price anchoring | Todo |
| Docs | PLAN/TIMELINE obsolete | Todo — delete or archive |

## Free vs Pro strategy

Free must be useful and honest (5 subscriptions, dashboard, widgets, reminders, history) so the app earns the word-of-mouth. Pro sells **savings**, not features: every Pro item should answer "how do I pay less?"

- Free: 5 active subs, 8 KPIs, widgets, reminders, 1 insight.
- Pro (lifetime): unlimited subs, all insights, analysis + 12-month forecast, budget alerts, cancellation simulator, Live Activity, PDF/CSV, Face ID.

### Next Pro candidates (ordered by value / effort)
1. ~~Free-trial tracker~~ **Done** (free tier): trial toggle on add, eve-of-end notification, dashboard card, row badge.
2. ~~Price-change log~~ **Done (last change only)**: detail screen records the previous price; Pro insight flags hikes ≥5%. Full history would need a `PriceChange` model.
3. **Shared subscriptions** — split cost by N people, show "your share".
4. ~~iCloud sync~~ **Built, unverified** (Pro toggle in Settings; see `PUBLISHING.md` for the required Xcode/CloudKit steps).
5. ~~Cancel guides~~ **Done**: `CancelGuide` opens the brand's management page (Netflix, Spotify, YouTube, App Store, Google Play…) or a search fallback. Add more brands as verified.
   Also done: first-launch onboarding (`OnboardingView`).
6. **Extra widgets / custom app icons** (Pro cosmetics: the 3 icon variants make a good unlockable set).
7. **Family plan + tip-jar tier** if lifetime conversion is low (consider $/yr alternative later).

## Visual identity

- **Concept (v2, 2026-11):** a mint billing *cycle* (ring + arrowhead) around a white disc with an indigo *check* — "recurring charges, under control".
- **Palette:** brand mint `#4DE8AB` (ring, savings highlights) on top of brand indigo `#5457DB` → violet `#9C4AF0` gradient (`Color.brandGradient`); status green/amber/red/blue stay semantic. Dark: lighter lavender accent `#8A87FF`.
- **Icon:** `AppIcon.png` (gradient), `AppIcon-Dark.png` (deep indigo, lavender glyph), `AppIcon-Tinted.png` (grayscale for system tint). Regenerate with `tools/make-icon.swift` (header has the command); the geometry is mirrored in `BrandMark.swift`.
- **In-app mark:** `BrandMark(size:filled:)` — used on the paywall; use it for empty states and onboarding next.
- **Type & shape:** SF Rounded for hero numbers, continuous corners (`Radius`), soft shadows only on hero/floating elements.
- **Voice:** direct and a little wry — "Mesmo sem abrir nenhuma delas."

## Motion language

`DesignSystem/Motion.swift`: short damped springs (`Motion.snappy`/`bouncy`), `PressableStyle` (press-down feedback), `staggeredAppear(_:)` (cascade entrance), `revealOnScroll()` (cards fade/scale as they scroll in), all gated by Reduce Motion. Interactive piece: `CostProjectionCard` (slider + tappable bars + yearly-increase toggle, with haptics). Patterns follow Apple HIG; Spotify's desktop client was deliberately not decompiled (ToS, and it is a web UI that would not map to SwiftUI).

## Automations (Shortcuts / Siri)

`Intents/SubCheckIntents.swift`: *Próxima cobrança*, *Total mensal*, *Cobranças dos próximos dias* (param: days), *Adicionar assinatura* (name, amount, frequency; respects the 5-sub free limit). Phrases for Siri in `AppShortcuts.strings` (pt-BR/en). Use them in the Shortcuts app > Automation (time of day, arrive/leave a place, Focus, charging…). Ideas next: *Registrar pagamento* (needs an `AppEntity` for subscriptions), *Cancelar assinatura*, a Focus-filter, and a Control Center toggle.

See `PUBLISHING.md` for iCloud setup, seeing the Dynamic Island and the App Store checklist.

## Not verified

The app builds and 69 unit tests pass in the simulator (Xcode 27). Still **never run on a real device**: iCloud sync between two devices, StoreKit purchase/restore (Sandbox), the Dynamic Island drawing, widgets, Siri phrases, notification actions, and a real bank CSV for statement import. The checklist is `TESTPLAN.md`.

1.0 scope: iPhone only. iPad, Mac and full price-change history are 1.1 candidates.
