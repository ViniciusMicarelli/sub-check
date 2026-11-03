# SubCheck — Design Patterns

The single source of truth for SubCheck's visual language. Everything here is
taken from the SwiftUI code; the website (`web/`) mirrors these tokens so the
marketing site and the app look like the same product.

Values were read from `SubCheck/Color.swift`, `SubCheck/DesignSystem/Theme.swift`,
`SubCheck/DesignSystem/Motion.swift`, `SubCheck/Views/Components/BrandMark.swift`
and `SubCheck/Views/Onboarding/OnboardingView.swift`. Do not invent new tokens:
add them to those files first, then mirror them here and in `web/src/styles.css`.

---

## 1. Color

Brand and status colors are fixed (identical in light and dark). Surfaces and
text are semantic system colors that adapt automatically.

### Brand & status (fixed)

| Token | Swift | Hex |
|---|---|---|
| `brand` | `0.33, 0.34, 0.86` | `#5457DB` |
| `brandSecondary` | `0.61, 0.29, 0.94` | `#9C4AF0` |
| `success` | `0.14, 0.72, 0.45` | `#24B873` |
| `warning` | `0.96, 0.65, 0.13` | `#F5A621` |
| `danger` | `0.91, 0.26, 0.29` | `#E8424A` |
| `info` | `0.16, 0.55, 0.96` | `#298CF5` |

Accent color (asset catalog): light `#5457DB`, dark `#8A87FF`.

### Surfaces & text (semantic, adapt to appearance)

| Token | Swift | Light | Dark |
|---|---|---|---|
| `appBackground` | `.systemGroupedBackground` | grouped light gray | near-black |
| `cardBackground` | `.secondarySystemGroupedBackground` | white | elevated dark |
| `elevatedBackground` | `.tertiarySystemGroupedBackground` | grouped light gray + | higher elevation |
| `hairline` | `.separator` | light separator | dark separator |
| `textPrimary` | `.label` | near-black | near-white |
| `textSecondary` | `.secondaryLabel` | gray | gray |
| `textTertiary` | `.tertiaryLabel` | lighter gray | darker gray |

Rule: never hard-code a surface or text color. Use the semantic token so the app
follows the user's appearance setting (`AppearanceOption.system/light/dark`).

### Gradients

```swift
brandGradient   = LinearGradient([brand, brandSecondary], .topLeading → .bottomTrailing)
successGradient = LinearGradient([success, #33D4A6],     .topLeading → .bottomTrailing)
```

`topLeading → bottomTrailing` is `135deg` in CSS.

---

## 2. Typography

System font (SF Pro), Dynamic Type aware. Large numbers use the **rounded**
design; everything else uses the default design.

| Role | Swift | Notes |
|---|---|---|
| Screen title | `.title.weight(.bold)` | onboarding titles |
| Section heading | `.headline` | "Total mensal", card titles |
| Body | `.body` / `.subheadline` | secondary text often in `textSecondary` |
| Caption | `.caption` / `.caption2` | metadata, badges |
| Hero amount | `.system(size: 40, weight: .bold, design: .rounded)` | dashboard hero |
| Ring/stat amount | `.system(size: 30–34, weight: .bold, design: .rounded)` | gauges, savings |
| Timer | `.system(size: 22, weight: .bold, design: .rounded)` + `.monospacedDigit()` | Dynamic Island |

No custom letter spacing or custom fonts anywhere.

---

## 3. Spacing

```swift
enum Spacing { xs = 4, sm = 8, md = 12, lg = 16, xl = 24, xxl = 32 }
```

Screen padding is `Spacing.xl` (24). Cards default to `Spacing.lg` (16) padding
via `cardSurface()`. Gaps between stacked cards are `Spacing.md` (12).

---

## 4. Corner radius

```swift
enum Radius { sm = 10, md = 16, lg = 22, pill = 999 }
```

- `sm` — small tiles, secondary buttons, icon squares
- `md` — cards, rows, primary buttons, text fields
- `lg` — hero card, prominent surfaces
- `pill` — chips, badges, next-charge pill, progress bar

All shapes use the **continuous** corner style.

---

## 5. Elevation

One shadow only, used sparingly (hero cards, floating summaries, floating +):

```swift
.shadow(color: .black.opacity(0.12), radius: 12, x: 0, y: 6)
```

The brand mark adds a colored glow: `Color.brand.opacity(0.35)`, radius
`size * 0.18`, y `size * 0.08`.

---

## 6. Motion

```swift
Motion.snappy = .spring(response: 0.35, dampingFraction: 0.82)   // default
Motion.bouncy = .spring(response: 0.5,  dampingFraction: 0.62)   // celebratory
Motion.stagger = 0.06                                            // 60 ms
```

- **Press** (`PressableStyle`): `scale 0.97` + `opacity 0.88` on `Motion.snappy`.
- **Staggered appear**: `opacity 0 → 1`, `offset y 18 → 0`, delay `index * 0.06`, `Motion.snappy`.
- **Scroll reveal**: `opacity 0.35 → 1`, `scale 0.95 → 1` via `.scrollTransition`.
- **Success burst**: 12 sparks alternating `success`/`brandSecondary` on a 90 pt
  radius, `successGradient` check in an 84 pt circle, 0.8 s ease-out, dismissed
  after 0.85 s.
- Everything is gated behind `accessibilityReduceMotion`.

Approximating springs on the web: `cubic-bezier(.34,1.32,.64,1)` for snappy,
`cubic-bezier(.34,1.56,.64,1)` for bouncy.

---

## 7. Components

### Card surface
`cardSurface(padding: 16, radius: 16)` → `RoundedRectangle(16, .continuous)` filled
with `cardBackground`, padded 16. Used for KPIs, list containers and info blocks.

### Hero card (dashboard summary)
`brandGradient` background, `Radius.lg` (22), padding `Spacing.xl` (24), `softShadow()`.
Contents in order:

1. Greeting — `.headline`, white *(only when the user set a name)*
2. "Total mensal" — `.subheadline`, white at 85 %
3. Amount — 40 pt rounded bold, white
4. Meta row — `.caption`, white at 90 % (yearly total · active count)
5. Next-charge pill — white text on white at 18 %, capsule

### Metric card
`VStack(leading, spacing 8)` in `cardSurface(padding 12, radius 16)`:
SF Symbol in a tinted rounded square (tint at 15 %), value `.title3.bold`,
label `.caption` in `textSecondary`, optional subtitle `.caption2` in the tint.

### Subscription row
`HStack(spacing 12)`, vertical padding 4. Icon 44 pt, then name
`.body.semibold` + frequency `.caption` in `textSecondary`, spacer, then cost
`.body.semibold` + monthly equivalent `.caption2` in `textSecondary`.
Cancelled rows drop to `opacity 0.55`.

### Buttons
- Primary: `brandGradient` fill, `Radius.md`, `.vertical(16)` padding, `.headline` white, `PressableStyle`.
- Secondary: `brand.opacity(0.12)` fill, `brand` text, `Radius.sm`.

### Chips / badges
Capsule. Category chip: `category.color.opacity(0.15)` fill, `category.color`
text, `.caption.semibold`, 12/8 padding. Trial badge: `danger`/`warning` at 15 %
with matching text, `.caption2.bold`, 6/2 padding.

### Progress bar (onboarding)
5 pt tall capsule track in `hairline` at 45 %, fill in `brandGradient`, minimum
width 12, animated with `Motion.snappy`.

### Empty state
Centered `VStack(spacing 12)`, 24 padding: 44 pt `.light` SF Symbol in `brand`,
`.headline` title, `.subheadline` message in `textSecondary`, optional bordered
prominent button tinted `brand`.

### Brand mark
Rounded square, `cornerRadius = size * 0.225`, `brandGradient`, brand glow.
Glyph drawn on a 1024-unit canvas, center (512,512), radius 285:
a cycle ring (70°→370°), an arrow head tangent at 370°, and a check from
(395,504) → (480,592) → (640,416). Stroke widths: ring `74/1024`, check `86/1024`.
`filled: false` renders the glyph in `brand` with no background.

---

## 8. Onboarding (5 steps)

Ordered, with a growing progress bar instead of dots.

| # | Title | Message |
|---|---|---|
| 1 | Bem-vindo ao SubCheck | Veja todas as suas assinaturas num só lugar e descubra para onde vai o seu dinheiro. |
| 2 | Adicione suas assinaturas | Toque em + e escolha o serviço. O ícone, a categoria e a próxima cobrança são preenchidos para você. |
| 3 | Entenda seus gastos | O painel mostra o total mensal, o custo por dia e o que mais pesa no seu bolso. |
| 4 | Nada de cobrança surpresa | Avisamos antes de cada cobrança, na véspera do fim de um teste e na Ilha Dinâmica. |
| 5 | Economize de verdade | Insights, previsão de 12 meses e o simulador de cancelamento mostram onde cortar. |

Step 1 also shows the name field — placeholder **"Como podemos te chamar?"**,
helper **"Serve só para personalizar o resumo. Você pode pular."**, 320 pt max
width, `cardBackground` fill, `hairline` 1 pt stroke, `Radius.md`.
The name is stored under `Profile.nameKey` and drives the dashboard greeting.
Finishing shows `LoadingOverlay` ("Preparando tudo…") then sets `onboardingDone`.

---

## 9. Dashboard anatomy

1. Hero card (see above).
2. Metric grid — 2 flexible columns, 12 gap, 8 cards: Assinaturas ativas, Custo
   anual, Vencem em 7 dias, Média por serviço, A pagar em 30 dias, Custo por dia,
   Maior assinatura, Economia anual.
3. Category donut — 210 pt tall, inner radius ratio 0.62, 2 pt angular inset,
   6 pt segment rounding, unselected segments at 0.28. Center shows the category
   (or "Total mensal") and its amount. Legend rows: 10 pt dot + icon, name +
   count badge, amount + percentage.
4. Upcoming payments — header "Próximas cobranças" with a "30 dias" badge; rows
   show icon, name, next billing date, cost and a days label coloured by
   urgency: `danger` (0–2 days), `warning` (3–7), `textSecondary` (8+).

---

## 10. Website mapping

`web/src/styles.css` mirrors this file:

```css
--brand-1: #5457db;   /* brand */
--brand-2: #9c4af0;   /* brandSecondary */
--success: #24b873;
--warning: #f5a621;
--danger:  #e8424a;
--info:    #298cf5;

--radius-sm: 10px;  --radius-md: 16px;  --radius-lg: 22px;  --radius-pill: 999px;
--space-xs: 4px; --space-sm: 8px; --space-md: 12px;
--space-lg: 16px; --space-xl: 24px; --space-xxl: 32px;

--brand-grad: linear-gradient(135deg, #5457db, #9c4af0);
--shadow-soft: 0 6px 12px rgba(0, 0, 0, 0.12);
--ease-snappy: cubic-bezier(0.34, 1.32, 0.64, 1);
```

The phone mock on the site renders the real screens: onboarding (step 1 with the
name field), "Nova assinatura" and the dashboard — and the name typed by the
visitor flows into the dashboard greeting.
