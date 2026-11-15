# UI guide: building the screens with small AI models

Last updated: 12 Nov 2026

This is the entry point of the UI pack. It explains how to use the other files, the rules for every UI session, how to keep dummy data out of the app, how the app name and logo can be swapped later, and the ordered steps to build the interface.

---

## 1. The UI pack

| File | What it holds | Load it when |
|---|---|---|
| `AI_INSTRUCTIONS.md` (project root) | The strict one-page-at-a-time rules for the AI | Every session |
| `PROGRESS.md` (project root) | The ordered list of pages with tick boxes. It decides what is built next | Every session |
| `docs/PROJECT_RULES.md` | Architecture, contracts, security, working agreement | Every session |
| `docs/UI_DESIGN_SYSTEM.md` | Tokens, components, motion, copy and format rules | Every UI session |
| `docs/UI_SCREENS_SHARED.md` | Sign-in, code, role gate, receipt, profile, notifications | Building those screens |
| `docs/UI_SCREENS_OWNER.md` | All owner screens (O1 to O17) | Building owner screens |
| `docs/UI_SCREENS_GUEST.md` | All guest screens (G1 to G5) | Building guest screens |
| `docs/ASSETS_GUIDE.md` | Images, logo, icons, fonts, how to replace them | Asset work |
| `UI_GUIDE.md` (this file) | Rules, steps, checklists | Once, then the opener in section 2 is enough |

**Never load every file into one session.** Small models have limited context and limited free quota. Load `PROJECT_RULES.md`, `UI_DESIGN_SYSTEM.md` and **one** screens file, and name the screen ID to build (for example "A1" or "O6"). `PROJECT_STATUS_AND_ROADMAP.md` is background only.

If two documents disagree: this pack wins on anything visual; `PROJECT_RULES.md` wins on architecture and security.

---

## 2. Rules for every UI session

**The opener (copy this)**

```
Read AI_INSTRUCTIONS.md, then docs/PROJECT_RULES.md, docs/UI_DESIGN_SYSTEM.md and docs/UI_SCREENS_<SHARED|OWNER|GUEST>.md.
Open PROGRESS.md and work only on its first unchecked item (it names the screen to build, exactly as specified).
Task: build screen <ID> exactly as specified. (Or: build component <Name>.)
Before coding: list the files you will create or change, and any detail the spec does not cover. Wait for my OK.
Rules: no dummy data, no hard-coded colours, sizes, text or asset paths, use the existing components, four states, ARB keys exactly as listed.
When done: run flutter analyze, the tests and tool/check_ui_rules.sh, and show me the file list.
```

**The ten rules**

1. **The spec is the law.** Build exactly what is written: sizes, colours, order, wording, behaviour. Do not improve, restyle or add. If something is missing, choose the simplest option that follows the design system and add one line under "UI gaps" in `docs/DECISIONS.md`.
2. **No dummy data.** Section 3. No exceptions.
3. **Tokens only.** Colours, text styles, spacing, radii, sizes and durations come from `lib/core/theme/tokens.dart`. Use `AppColors.surface` for white. Never `Colors.*`, never `Color(0x...)` outside the theme folder.
4. **One component, one file.** Screens use the components in the design system. If a screen needs something new, add the component to the design system first.
5. **Text lives in ARB.** `lib/core/l10n/app_en.arb`, with the keys given in the screen files. The app name only through `{appName}` or `AppConfig.appName`.
6. **Images and icons only through the contract.** `AppAssets` for images, `AppIcons` for icons.
7. **Four states for every screen that loads data:** loading skeleton, empty, error with retry, data.
8. **Data only through the contract.** Each screen lists the views and functions it uses. Read from views, write through `rpc_*` functions, never add up money or decide statuses in Dart.
9. **Features whose backend is not built yet stay hidden behind `AppFlags`.** A hidden control is removed, not greyed out.
10. **One screen (or one component) per session, one commit per session.** Small commits. Test on a real phone.

**Mistakes small models often make (check for them in every review)**

- Default Material widgets: `ElevatedButton`, `Card`, `ListTile`, `FloatingActionButton`, `NavigationBar`, `Chip`, `AlertDialog`, floating-label `InputDecoration`.
- The default purple colour scheme, shadows on rows, gradients, rounded stacked cards.
- Centring text that the spec left-aligns. Wrong or missing hairlines between rows.
- Hard-coded strings (`Text('Save')`), hard-coded `Color`, `fontSize`, `EdgeInsets` numbers outside the tokens.
- A spinner on a blank screen instead of a skeleton.
- Doing money arithmetic or status logic in Dart.
- Adding fake rows "so the screen does not look empty".
- Enabling tabular figures (the font does not need them).
- Changing the wording of a button or message.

---

## 3. Zero dummy data

Deleting dummy data later is painful, so it never goes in.

**What counts as dummy data:** names of people or PGs, phone numbers, amounts, dates, lists of items, sample images, fake receipts, mock repositories wired into the running app, any "demo mode" or "sample data" switch.

**What is allowed**

| Allowed | Where |
|---|---|
| Reference data the app needs to work (roles, payment methods, charge types, room types, amenities, document types, relationship types, UPI apps, states, cities) | In the migrations. These are real, required rows, not test data |
| Hint text that describes a format ("10-digit mobile number", "Building, street") | Screens. Never a realistic-looking value |
| Default form values such as today's date | Screens |
| Fake or in-memory repositories for tests | `test/` only |
| The component gallery with generic labels ("Primary text", `₹1,23,456`) | `lib/dev/`, debug builds only |

**How to test without dummy data**

1. Use **two Supabase projects**: one for development, one for real use. The app reads its address and key from `env/dev.json` or `env/prod.json` (section 6). Never point a development build at the real project.
2. **Create test data through the app itself**: add a PG, rooms, guests and payments with the real screens. That also tests the real flows.
3. Log in with test phone numbers that have a fixed code, if your Supabase setup offers it (check the current Supabase docs).
4. **Wipe the development project in one step** with `dev_reset.sql`. It refuses to run unless you first run `set app.allow_reset = 'yes';` in the same session. It keeps the reference data and removes every person, PG, payment and login. Empty the Storage buckets by hand afterwards. Check the project name before running it.
5. Never seed test data in a migration.

**Automatic check.** Create `app/tool/check_ui_rules.sh` with the content below and run it before every commit. It must print `UI rules check: clean`.

```bash
#!/usr/bin/env bash
# Run from the app folder: ./tool/check_ui_rules.sh
cd "$(dirname "$0")/.." || exit 1
fail=0
report() { echo "PROBLEM: $1"; echo "$2"; echo; fail=1; }

out=$(grep -rniE "lorem|dummy|sample|mock|fake|demo|john|test user" lib --include=*.dart | grep -v "^lib/dev/")
[ -n "$out" ] && report "words that suggest dummy data" "$out"

out=$(grep -rnE "Color\(0x|Colors\.[a-zA-Z]" lib --include=*.dart | grep -v "^lib/core/theme/")
[ -n "$out" ] && report "colours outside lib/core/theme" "$out"

out=$(grep -rnE "(Text|SelectableText)\(\s*['\"]" lib --include=*.dart | grep -v "^lib/dev/")
[ -n "$out" ] && report "hard-coded text (use the ARB strings)" "$out"

out=$(grep -rnE "fontSize:|FontWeight\." lib --include=*.dart | grep -v "^lib/core/theme/")
[ -n "$out" ] && report "font sizes or weights outside lib/core/theme" "$out"

out=$(grep -rnE "Card\(|ListTile\(|FloatingActionButton|ElevatedButton|FilledButton|NavigationBar\(|Chip\(|AlertDialog\(" lib --include=*.dart | grep -v "^lib/dev/")
[ -n "$out" ] && report "default Material widgets that the design does not use" "$out"

out=$(grep -rnE "BoxShadow|LinearGradient" lib --include=*.dart | grep -v "^lib/core/widgets/receipt_paper.dart\|^lib/core/widgets/skeleton.dart")
[ -n "$out" ] && report "shadows or gradients outside the receipt and skeleton" "$out"

out=$(grep -rnE "₹ ?[0-9]|\+91 ?[0-9]{5}" lib --include=*.dart | grep -v "^lib/dev/\|^lib/core/format/")
[ -n "$out" ] && report "hard-coded money or phone numbers" "$out"

out=$(grep -rnE "assets/(images|brand)/" lib --include=*.dart | grep -v "^lib/core/assets/app_assets.dart")
[ -n "$out" ] && report "asset paths outside AppAssets" "$out"

[ $fail -eq 0 ] && echo "UI rules check: clean"
exit $fail
```

---

## 4. App name, logo and assets (decide later, change in minutes)

**The name is a placeholder.** `AppConfig.appName` is `PG App` for now. No screen writes the name; they use `{appName}` in strings or read `AppConfig.appName`. To rename the app:

1. Change `AppConfig.appName` (one line).
2. Change `app_name` in `android/app/src/main/res/values/strings.xml` and make sure `AndroidManifest.xml` uses `android:label="@string/app_name"`. (iOS later: the display name in `Info.plist`.)
3. Replace the logo files (below) and regenerate the icons.

Nothing else mentions the name. Search the code for the old name to be sure (it should not be found).

**The logo is a placeholder** (a house with a door in a petrol square). To change it, replace these files **keeping the same names and the same format**, then regenerate:

| File | Used for |
|---|---|
| `assets/brand/logo_mark.svg` | Petrol tile logo on light screens (A3 and the receipt) |
| `assets/brand/logo_mark_white.svg` | White mark on the photo screens (A1) |
| `assets/brand/app_icon_1024.png` | Launcher icon source |
| `assets/brand/app_icon_foreground_1024.png` | Android adaptive icon foreground |
| `assets/brand/splash_mark.png` | Splash screen mark |
| `assets/images/auth/auth_backdrop.jpg` | The photo on sign-in and code screens |

Regenerate icons and splash after replacing files:

```
dart run flutter_launcher_icons
dart run flutter_native_splash:create
```

`pubspec.yaml` additions (the packages are listed in section 5):

```yaml
flutter:
  uses-material-design: true
  generate: true
  assets:
    - assets/brand/
    - assets/images/auth/
  fonts:
    - family: IBMPlexSans
      fonts:
        - asset: assets/fonts/IBMPlexSans-Regular.ttf
          weight: 400
        - asset: assets/fonts/IBMPlexSans-Medium.ttf
          weight: 500
        - asset: assets/fonts/IBMPlexSans-SemiBold.ttf
          weight: 600

flutter_launcher_icons:
  android: true
  ios: false
  image_path: "assets/brand/app_icon_1024.png"
  adaptive_icon_background: "#1A4D6B"
  adaptive_icon_foreground: "assets/brand/app_icon_foreground_1024.png"

flutter_native_splash:
  color: "#1A4D6B"
  image: assets/brand/splash_mark.png
  android_12:
    color: "#1A4D6B"
    image: assets/brand/splash_mark.png
```

If a tool complains about a key, check that package's current README; the names may have changed.

**Config and asset contract files**

```dart
// lib/core/config/app_config.dart
abstract final class AppConfig {
  static const appName = 'PG App';          // placeholder. Change here only.
  static const countryCode = '+91';
  static const termsUrl = '';               // empty = no link is shown
  static const privacyUrl = '';
  static const playStoreUrl = '';           // empty = the invite message has no link
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabaseAnonKey = String.fromEnvironment('SUPABASE_ANON_KEY');
}

abstract final class AppFlags {
  static const remindersEnabled = false;    // true after roadmap step 11
  static const uploadsEnabled = false;      // true after the storage policies migration
  static const giveNoticeEnabled = false;   // true after rpc_give_notice exists
}
```

```dart
// lib/core/assets/app_assets.dart
abstract final class AppAssets {
  static const logoMark = 'assets/brand/logo_mark.svg';
  static const logoMarkWhite = 'assets/brand/logo_mark_white.svg';
  static const authBackdrop = 'assets/images/auth/auth_backdrop.jpg';
}
```

When `AppFlags.uploadsEnabled` is false, hide the profile photo, ID document photo and payment screenshot controls (S2 and G3). Uploads need the private Storage buckets and their policies, which are security-critical: **ask the big model to write that migration** (`005_storage_policies.sql`) and review it, instead of letting a small model write it.

---

## 5. Packages

These are approved by this pack (they extend `PROJECT_RULES.md` section 2). Anything else: ask first.

| Package | For | Notes |
|---|---|---|
| `flutter_riverpod`, `go_router`, `supabase_flutter` | Core stack | Already in the rules |
| `intl`, `flutter_localizations` (SDK) | Text, dates, Indian number grouping | `generate: true` in `pubspec.yaml`, strings in `app_en.arb` |
| `flutter_svg` | Logo marks | New |
| `phosphor_flutter` | Icons | New |
| `image_picker` | Profile photo, ID document photo, payment screenshot | New |
| `url_launcher`, `share_plus`, `flutter_secure_storage` | UPI link and dialer, sharing, storing the selected PG | Already in the rules |
| `flutter_launcher_icons`, `flutter_native_splash` | Icon and splash generation | **Dev dependencies** |

**Do not use:** `google_fonts` (fonts are bundled), `shared_preferences` (use secure storage), any UI kit, any animation package, Lottie.

**Android manifest** needs, so that the UPI scheme can be opened on Android 11 and above:

```xml
<queries>
  <intent>
    <action android:name="android.intent.action.VIEW"/>
    <data android:scheme="upi"/>
  </intent>
  <intent>
    <action android:name="android.intent.action.DIAL"/>
  </intent>
</queries>
```

Lock the app to portrait in the manifest or with `SystemChrome.setPreferredOrientations`.

---

## 6. Folder additions

```
app/
  assets/
    brand/                  logo_mark.svg, logo_mark_white.svg, app icons, splash_mark.png
    images/auth/            auth_backdrop.jpg
    fonts/                  IBMPlexSans-Regular.ttf, -Medium.ttf, -SemiBold.ttf, OFL.txt
  env/                      dev.json, prod.json   (NOT committed: add env/ to .gitignore)
  tool/                     check_ui_rules.sh
  lib/
    core/
      assets/app_assets.dart
      config/app_config.dart
      theme/                tokens.dart, app_theme.dart, app_icons.dart
      format/               money.dart, dates.dart, phone.dart
      l10n/                 app_en.arb
      widgets/              one file per component (file name = snake_case of the component;
                            SkeletonBlock and SkeletonList live in skeleton.dart)
    dev/                    component_gallery.dart   (debug builds only)
```

`env/dev.json` holds `{"SUPABASE_URL": "...", "SUPABASE_ANON_KEY": "..."}` for the development project (the anon key is meant to be public, but keep the file out of git anyway). Run with `flutter run --dart-define-from-file=env/dev.json`. A release build uses `env/prod.json`. The `service_role` key is never used in the app.

---

## 7. Navigation map

```
Startup  (native splash, then: signed in? yes -> rpc_my_context ; no -> /sign-in)
 │
 ├─ /sign-in (A1) ──> /verify (A2) ──> after sign-in:
 │                                      ├─ works in a PG  ───> /owner/home
 │                                      ├─ has a stay    ───> /guest/home
 │                                      └─ neither       ───> /gate (A3)
 │                                                             ├─ "I run a PG"  ──> /owner/pg/new (O1)
 │                                                             └─ "I'm a guest" ──> /gate/guest (A4)
 │
 ├─ /owner  (shell with bottom navigation: Home | Guests | Payments | More)
 │    ├─ /owner/home (O2)          ─ PG switcher sheet (O3), /notifications (S3)
 │    ├─ /owner/guests (O4) ─ /owner/guests/new (O5)
 │    │        └─ /owner/guests/:stayId (O6) ─ actions sheets (O17)
 │    │                  └─ /owner/guests/:stayId/pay (O7) ──> /receipt/:paymentId (S1)
 │    ├─ /owner/payments (O9) ─ /owner/payments/:paymentId (O8) ─ /owner/collections (O10)
 │    └─ /owner/more (O13)
 │         ├─ /owner/rooms (O11) ─ /owner/rooms/:roomId ─ /owner/rooms/new (O12)
 │         ├─ /owner/accounts (O14) ─ /owner/accounts/new, /owner/accounts/:id
 │         ├─ /owner/reminders (O15)
 │         ├─ /owner/settings (O16)
 │         └─ /profile (S2)
 │
 └─ /guest  (shell with bottom navigation: Home | History | Profile)
      ├─ /guest/home (G1) ─ /guest/pay/:stayId (G2) ─ report sheet (G3)
      ├─ /guest/history (G4) ─ /guest/stay/:stayId (G5)
      └─ /profile (S2)

Shared: /receipt/:paymentId (S1), /notifications (S3), /profile (S2)
Debug only: /dev/gallery
```

A person who is both an owner and a guest switches views from "More" (owner) or "Profile" (guest). The last view is stored locally.

---

## 8. Database pieces the screens depend on

All are in the migrations and have been tested.

| Migration | What it adds for the UI |
|---|---|
| `003_ui_read_views.sql` | `v_guest_list`, `v_payment_feed`, `v_receipt_detail`, `v_pg_overview`, `v_pg_setup_status`, `v_bed_occupancy`, `v_collections_month_total`. Each screen reads one of these |
| `004_ui_write_functions.sql` | `rpc_add_rooms` (bulk rooms and beds), `rpc_correct_guest_name` |
| `002_core_functions.sql` | `rpc_report_payment` now accepts an optional `p_screenshot_file_id` |
| `dev_reset.sql` | Dev-only wipe (section 3) |

Still to write when needed (tell the big model): `005_storage_policies.sql`, `rpc_give_notice`, `rpc_send_reminder_now`, and the reminder-sending Edge Function.

---

## 9. Build steps

The strict order and the tick boxes live in `PROGRESS.md` at the project root. It splits this table into smaller pages (one screen per item) and adds the rule that a page is finished only after it is tested on a real phone and approved. If this table and `PROGRESS.md` differ, `PROGRESS.md` decides the order.

Each step is one or a few small sessions. Every screen session follows the project's slice recipe: repository (domain interface, then Supabase implementation, then a fake for tests), providers, screen, ARB strings, tests. The roadmap step each one belongs to is in brackets.

**Checkpoints** are moments to look at the result on a real phone before going on. Send the big model screenshots and the relevant spec section (use the review request in section 10).

| Step | What | Load | Done when |
|---|---|---|---|
| **U0** | **Setup** [roadmap 3]. Create the Flutter project in `app/` (the placeholder assets and fonts are already in `app/assets/`), add the packages, `pubspec.yaml` entries, `AppConfig`, `AppFlags`, `AppAssets`, the manifest `<queries>`, `.gitignore`, `env/` files, the ARB setup and `tool/check_ui_rules.sh` | Guide sections 3 to 6 | The app runs on the phone showing an empty page, `flutter analyze` is clean, the check script prints clean |
| **U1** | **Tokens and helpers.** `tokens.dart`, `app_theme.dart`, `app_icons.dart`, formatting (`money.dart`, `dates.dart`, `phone.dart`) with unit tests: 650000 paise gives `₹6,500`; 12500000 gives `₹1,25,000`; 650050 gives `₹6,500.50`; 0 gives `₹0`; negative amounts; phone `+919876543210` shown as `+91 98765 43210`; the date and month formats | Design system sections 2, 3, 9 | Tests pass |
| **U2** | **Components, part 1:** `Money`, `StatusChip`, `AppButton`, `SectionHeader`, `LedgerSheet`, `LedgerRow`, `RoomTile`, `KeyValueRow`, `EmptyState`, `ErrorState`, `SkeletonBlock`, `SkeletonList`, `ProgressBarThin`, `ProfileAvatar` | Design system section 5 | Each exists, uses tokens only |
| **U3** | **Components, part 2:** `AppTextField`, `PhoneField`, `MoneyField`, `SelectField`, `OptionSheet`, `DateField`, `OtpField`, `OptionRow`, `UnderlineTabs`, `SwitchRow`, `AppBottomSheet`, `ConfirmSheet`, `AppSnack`, `AppTopBar`, `PgSwitcherTitle`, `AppBottomNav`, `TickBadge`, `Stamp`, `ReceiptPaper` | Design system sections 5, 7 | Each exists, uses tokens only |
| **U4** | **Component gallery** at `/dev/gallery` (design system section 11). **Checkpoint 1:** check every component against the design system on a real phone; confirm the ₹ sign and the figures line up | Design system section 11 | You and the big model agree it matches |
| **U5** | **Sign-in** (A1, A2), **role gate** (A3, A4) and the startup routing from the navigation map [roadmap 4]. Replace the placeholder backdrop with the real photo first if you have it. **Checkpoint 2** | `docs/UI_SCREENS_SHARED.md` | All four routes work with test numbers |
| **U6** | **Owner shell** (bottom nav), **O1** Add your PG, **O3** PG switcher, **O13** More, **S2** Profile (owner parts) [roadmap 5] | `UI_SCREENS_OWNER.md`, `UI_SCREENS_SHARED.md` | Two PGs can exist and switching changes what you see |
| **U7** | **O12** Add rooms, **O11** Rooms and beds, **O14** Receiving accounts [roadmap 6] | `docs/UI_SCREENS_OWNER.md` | Your friend's real rooms and accounts are entered |
| **U8** | **O4** Guests, **O5** Add guest, **O6** Guest detail, **O17** sheets [roadmap 7]. **Checkpoint 3:** enter the 10 real guests | `docs/UI_SCREENS_OWNER.md` | Real guests show correct balances |
| **U9** | **O7** Record payment, **S1** Receipt, **O8** Payment detail, **O9** Payments, **O10** Money received [roadmap 8 and 9]. **Checkpoint 4:** your friend records a day's cash | `UI_SCREENS_OWNER.md`, `UI_SCREENS_SHARED.md` | A payment can be recorded, shared as a receipt, and reversed |
| **U10** | **O2** Owner home (it needs the data from U8 and U9) [roadmap 8] | `docs/UI_SCREENS_OWNER.md` | The work queue shows real overdue and pending items |
| **U11** | **Guest app** G1 to G5 and the guest parts of S2 [roadmap 10]. **Checkpoint 5:** a real guest signs in on their own phone | `UI_SCREENS_GUEST.md`, `UI_SCREENS_SHARED.md` | A guest can pay by UPI, report it, and the owner can confirm it |
| **U12** | **S3** Notifications, **O15** Reminders, and switching on `AppFlags` when their backend exists [roadmap 11] | `UI_SCREENS_SHARED.md`, `UI_SCREENS_OWNER.md` | Flags are on only for features that work |
| **U13** | **Polish and audit** [roadmap 12]: the review checklist below on every screen, text size 1.3, 320 wide screen, reduce motion, a low-end phone | This guide | Checklist passes |

---

## 10. Review checklist

Use it at every checkpoint and before calling a screen done.

**Look**
- Page background is `ground`; sheets are white, edge to edge, with hairlines, no rounded cards.
- Left-aligned text; amounts right-aligned in lists; the main figure is the biggest thing.
- Spacing is a multiple of 4; side padding 16; tap targets at least 48 (inline row actions 44).
- Status shows a word and uses the right chip colours.
- No shadows except the receipt; no gradients except the skeleton; no emoji; icons from `AppIcons` only.
- Receipt: notches, dashed divider, stamp, share image looks right.

**Behaviour**
- Loading skeleton, empty, error with retry, data: all four exist and look right.
- Buttons show loading and ignore taps while loading. Pull to refresh on lists.
- Keyboard never hides the focused field or the sticky button.
- Forms show errors under the field with the exact keys' wording.
- Hidden features (flags and roles) are hidden, not greyed.

**Data and copy**
- `tool/check_ui_rules.sh` prints clean.
- Every string uses the ARB key given in the spec, with the exact English text.
- Money, dates and phone numbers are formatted only by the format helpers.
- No money arithmetic or status logic in Dart.

**Device**
- Real Android phone. System text size at 1.3: nothing overflows or is cut off.
- A 320 dp wide screen and a 412 dp wide screen.
- Slow network and no network: errors are plain and retry works.
- A guest name in Hindi or Kannada displays correctly.
- Light sunlight readability: all text is `ink` or `muted` on white or `ground`.

**Asking the big model to review a screen** (paste this, then the spec section, the code files and a screenshot):

```
Review screen <ID>. Below are the spec section, the code and a screenshot from a real phone.
List every deviation from the spec (sizes, colours, order, copy, states, behaviour, forbidden widgets).
For each, give a one-line fix instruction written for a small model.
```

---

## 11. Known gaps and later

- No dark theme; portrait only; phones only (tablets later).
- No illustrations; empty states use icons. Add custom illustrations later only if they match the quiet style.
- Languages: English only in version 1. Hindi and Kannada are added later as new `.arb` files; the layouts must already survive longer text.
- Receipt PDF is not in version 1 (image share only).
- Reminder sending, uploads, notice-to-vacate and the reliability score appear only when their backend is built (`AppFlags`).
- The app name and logo are placeholders until you decide (section 4).
