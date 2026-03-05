# ZENO Design System
## This file is the source of truth. Read it before editing any UI file.

### Typography
- Font: Google Fonts 'Nunito' ONLY — NEVER Inter, Roboto, or system fonts
- Add to pubspec.yaml: google_fonts: ^6.2.1
- Screen headlines: Nunito, fontSize 40–48, fontWeight w900, height 1.05
- Subheadings: Nunito, fontSize 22–28, fontWeight w700
- Body: Nunito, fontSize 16, fontWeight w400
- In code always use: GoogleFonts.nunito(fontWeight: FontWeight.w900, fontSize: 44)

### Colours — Per-Screen Backgrounds (FLAT, no gradients)
- Home: #F2F5EF
- Onboarding welcome: #D6EAF8
- Onboarding feature slides: #FFFFFF
- Onboarding stats/results: #D5F5E3
- Onboarding pet intro: #EAE6F0
- Onboarding rating: #FEF9E7
- Onboarding reminders: #FEF0E8
- Scan: #FFF8F0
- Insights: #EAF4FB
- Profile: #F4F0FF

### Accent Colours
- Primary action (buttons): #1A1A1A (near black)
- Selected/active state: #7AB87A (sage green) with #E8F5E8 background tint
- Text primary: #1A1A1A
- Text secondary: #888888
- Button text: #FFFFFF

### Layout Rules — STRICT
1. Max 2 focal elements per screen
2. Radical whitespace — empty space is intentional and good
3. NO white cards with box shadows as the primary layout pattern
4. Buttons: full-width, height 56, borderRadius 50 (pill), black fill
5. Selection tiles: height 64, borderRadius 16, white fill,
   green border + green tint on selected
6. Floating decoratives: 3-4 emoji/shape widgets in Positioned()
   at non-symmetric offsets with Transform.rotate — every screen
7. Headings LEFT-aligned or CENTER-aligned — never both on same screen
8. The heading IS the screen. Make it massive and bold.

### What Is Forbidden
- Inter, Roboto, system fonts anywhere
- White (#FFFFFF) as scaffold background
- Cards with elevation/boxShadow as primary layout
- Symmetric decorative elements
- Subtle animations (all animations must be FELT)
- Generic ListTile for settings/options
