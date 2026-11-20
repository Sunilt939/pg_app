# UI design system

Last updated: 12 Nov 2026

Load this file in **every** UI session, together with one screens file. The screens files say *what goes where*. This file says *how everything looks and behaves*. It extends `PROJECT_RULES.md` section 8; if they disagree, this file wins for anything visual.

All sizes are in dp (Flutter logical pixels). The design baseline is a 360 x 800 phone. Everything must also work at 320 wide and at 412 wide.

---

## 1. The look

**Concept: "Passbook".** The app should feel like a well-kept ledger book: quiet, left-aligned, number-first, ruled with thin lines, with one petrol-blue "ink" colour. Status looks like a stamp. The receipt is the one screen with character; everything else stays calm.

### Principles

1. **Rows and rules, not cards.** Content sits on white edge-to-edge "sheets" separated by hairlines. No rounded stacked cards, no shadows on list items.
2. **Numbers lead.** The most important figure on a screen is the biggest thing on it. Amounts are right-aligned in lists.
3. **One accent.** Petrol is used for actions and the active tab. Status colours appear only inside status chips and the figure they describe.
4. **Words, not just colour.** Every status has a word.
5. **Plain language.** The owner's own words: rent, advance, bed, room, collect.
6. **Quiet motion.** Only motion that answers a tap or confirms a result.
7. **Real data only.** No sample names, amounts or images in the app (see `UI_GUIDE.md` section 3).

### What must never appear

Gradients (the only exceptions: the skeleton shimmer), glass or blur effects, drop shadows on list rows, the default Material purple, floating labels inside text fields, floating action buttons, emoji anywhere, stock illustrations, confetti, ALL-CAPS labels above headings, text lines joined with middle dots, arrows added to button text, centred paragraphs of body text, entrance animations on lists.

---

## 2. Tokens

Create `lib/core/theme/tokens.dart` exactly like this. Nothing else in the app may contain a colour, a font size, a spacing number or a duration.

```dart
import 'package:flutter/material.dart';

abstract final class AppColors {
  static const petrol = Color(0xFF1A4D6B);        // actions, active tab, links
  static const petrolPressed = Color(0xFF143D55); // pressed state of petrol
  static const petrolTint = Color(0xFFEDF1F3);    // selected option background, pressed rows
  static const ground = Color(0xFFF2F4F6);        // app background
  static const surface = Color(0xFFFFFFFF);       // sheets, inputs, bars
  static const ink = Color(0xFF1B2631);           // main text
  static const muted = Color(0xFF5B6772);         // secondary text
  static const hairline = Color(0xFFDDE2E7);      // dividers, quiet borders
  static const outline = Color(0xFF7F8A94);       // input borders, switch track (meets 3:1)
  static const handle = Color(0xFFC5CCD3);        // bottom sheet handle only
  static const disabledBg = Color(0xFFE8ECEF);    // disabled buttons
  static const scrim = Color(0xFF0F2A3A);         // photo overlay, always at 72% opacity
  static const snackAction = Color(0xFF9CC4DA);   // action text on the dark snackbar

  static const paidFg = Color(0xFF187544);
  static const paidBg = Color(0xFFE3F3EA);
  static const pendingFg = Color(0xFF8F5A00);
  static const pendingBg = Color(0xFFFCF0D6);
  static const overdueFg = Color(0xFFB42318);
  static const overdueBg = Color(0xFFFDE8E6);
  static const overduePressed = Color(0xFF912018);

  static const skeletonBase = Color(0xFFE7EBEE);
  static const skeletonHighlight = Color(0xFFF5F7F8);
}

abstract final class AppText {
  static const _f = 'IBMPlexSans';
  // fontSize / line height / weight
  static const display = TextStyle(fontFamily: _f, fontSize: 28, height: 36 / 28, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const title = TextStyle(fontFamily: _f, fontSize: 20, height: 28 / 20, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const heading = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600, color: AppColors.ink);
  static const bodyMedium = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const body = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w400, color: AppColors.ink);
  static const secondary = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w400, color: AppColors.muted);
  static const label = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w500, color: AppColors.ink);
  static const caption = TextStyle(fontFamily: _f, fontSize: 12, height: 16 / 12, fontWeight: FontWeight.w500, color: AppColors.muted);
  static const button = TextStyle(fontFamily: _f, fontSize: 16, height: 24 / 16, fontWeight: FontWeight.w600);
  static const buttonSmall = TextStyle(fontFamily: _f, fontSize: 14, height: 20 / 14, fontWeight: FontWeight.w600);
}

abstract final class AppSpace {
  static const double x4 = 4, x8 = 8, x12 = 12, x16 = 16, x24 = 24, x32 = 32, x48 = 48;
  static const double screenPadding = 16;
}

abstract final class AppRadius {
  static const chip = BorderRadius.all(Radius.circular(4));
  static const tile = BorderRadius.all(Radius.circular(6));
  static const control = BorderRadius.all(Radius.circular(8));   // buttons, inputs, option boxes
  static const dialog = BorderRadius.all(Radius.circular(12));
  static const sheetTop = BorderRadius.vertical(top: Radius.circular(16));
}

abstract final class AppSize {
  static const double topBar = 56, bottomNav = 64, tap = 48, tapInline = 44;
  static const double field = 52, button = 48, rowMin = 64, tile = 44;
  static const double chipMin = 20, hairline = 1;
  static const double icon = 24, iconSmall = 20, iconFeature = 28, iconEmpty = 40;
}

abstract final class AppMotion {
  static const fast = Duration(milliseconds: 120);     // press feedback
  static const base = Duration(milliseconds: 220);     // sheets, state changes
  static const slow = Duration(milliseconds: 350);
  static const tick = Duration(milliseconds: 450);     // payment tick drawing
  static const shake = Duration(milliseconds: 320);    // wrong code
  static const shimmer = Duration(milliseconds: 1200); // skeleton loop
  static const curve = Curves.easeOutCubic;
}
```

**Typography rules**

- Font family: **IBM Plex Sans** (bundled, weights 400, 500, 600). Never use `google_fonts` at runtime.
- Do **not** enable tabular figures. Checked in the font file: it has no tabular feature, but its digits are already all the same width, so numbers line up by default.
- The ₹ sign exists in the font. Hindi, Kannada and other scripts are not in it; the phone's own fonts are used automatically for them.
- Never set a font size or weight outside the styles above. Never use letter spacing. Never use ALL CAPS.
- Allow text to scale up to 1.3. Text wraps or ellipsizes; layouts must never overflow.

**ThemeData essentials** (`lib/core/theme/app_theme.dart`)

```dart
ThemeData(
  useMaterial3: true,
  fontFamily: 'IBMPlexSans',
  scaffoldBackgroundColor: AppColors.ground,
  colorScheme: const ColorScheme.light(
    primary: AppColors.petrol, onPrimary: Colors.white,
    surface: AppColors.surface, onSurface: AppColors.ink,
    error: AppColors.overdueFg,
  ),
  splashFactory: NoSplash.splashFactory,   // our own pressed states are used instead
  dividerColor: AppColors.hairline,
  textSelectionTheme: const TextSelectionThemeData(cursorColor: AppColors.petrol),
)
```

Date picker, switch and snackbar are themed from the tokens. Everything else is built from the components in section 5, **not** from default Material widgets.

---

## 3. Icons

One family: **Phosphor** (`phosphor_flutter`), regular weight. The only use of the fill weight is the active bottom-navigation icon. Sizes: 24 default, 20 small (inside fields, chips, buttons), 28 feature (gate screen rows), 40 empty states.

All screens use icons through `lib/core/theme/app_icons.dart`. Switching the family later is a one-file change.

| Semantic name | Phosphor icon | Where |
|---|---|---|
| `home` | house | Nav |
| `guests` | users | Nav |
| `payments` | receipt | Nav |
| `more` | dotsThree | Nav |
| `history` | clockCounterClockwise | Guest nav |
| `profile` | userCircle | Guest nav, profile |
| `back` | arrowLeft | Top bar |
| `close` | x | Modal top bar |
| `chevronRight` | caretRight | Rows |
| `chevronDown` | caretDown | Select fields, PG switcher |
| `chevronLeft` | caretLeft | Month selector |
| `add` | plus | Add actions |
| `minus` | minus | Beds stepper |
| `check` | check | Selected option, done |
| `search` | magnifyingGlass | Search field |
| `bell` | bell | Notifications |
| `phone` | phone | Call |
| `copy` | copy | Copy |
| `share` | shareNetwork | Share |
| `lock` | lock | Read-only values |
| `clock` | clock | Waiting for confirmation |
| `warning` | warning | Error state |
| `camera` | camera | Photo |
| `image` | image | Screenshot, gallery |
| `edit` | pencilSimple | Edit |
| `trash` | trash | Remove |
| `signOut` | signOut | Sign out |
| `settings` | gear | PG settings |
| `building` | buildings | PG, "I run a PG" |
| `user` | user | "I'm a guest" |
| `bed` | bed | Bed, empty room tile |
| `room` | door | Rooms |
| `bank` | bank | Bank account |
| `upi` | qrCode | UPI account |
| `cash` | money | Cash |
| `calendar` | calendarBlank | Date fields |
| `rupee` | currencyInr | Money rows |
| `filter` | funnel | Filter |
| `info` | info | Helper rows |

If a Phosphor name differs in the installed version, use the nearest icon and note it in `docs/DECISIONS.md`. Do not substitute another icon family.

---

## 4. Layout rules

- **Screen horizontal padding:** 16. **Vertical rhythm:** multiples of 4.
- **Page background:** `ground`. **Sheets** (`LedgerSheet`) are `surface`, full width, 1 dp `hairline` border on top and bottom, no radius, no shadow. Sheets are separated by a 12 dp gap of `ground`.
- **Safe areas:** respect the status bar and the system navigation bar. Bottom bars add the bottom inset to their own padding.
- **Orientation:** portrait only.
- **Keyboard:** `resizeToAvoidBottomInset: true`. A sticky bottom action stays above the keyboard. The focused field scrolls into view.
- **Scrolling:** every screen that can exceed the screen height scrolls. Pull-to-refresh on every list screen.
- **Shells**
  - *Auth page:* photo area on top, white sheet below (see `UI_SCREENS_SHARED.md` A1).
  - *Tab page:* top bar, body, bottom navigation.
  - *Form page:* top bar with back or close, scrolling form, sticky bottom action.
  - *Detail page:* top bar with back, scrolling sheets, optional sticky bottom action.
- **Sticky bottom action** (`bottomAction`): `surface` background, top hairline, padding 16 (+ bottom inset), holds one primary button (or a secondary and a primary side by side with a 12 gap).
- **Width on tablets:** content is centred with a maximum width of 600. Not a priority in version 1.
- **Dark mode:** not in version 1. Force light.

---

## 5. Components

Put every component in `lib/core/widgets/`, one file each, named as below. Screens use these and nothing else. If a screen needs something that does not exist, add it to this list first.

### AppTopBar
- Height 56, background `surface`, 1 dp `hairline` bottom border, no elevation.
- Title: `title` style, left-aligned, one line, ellipsis. With a leading icon the title starts after the 48 leading area; without it the title starts at 16.
- Leading: back (`AppIcons.back`) or close, 24 dp, ink, in a 48 x 48 tap area.
- Actions: icons 24 dp, ink, each in a 48 x 48 tap area. Right padding 4.
- Status bar icons are dark.
- *Photo variant* (auth screens): transparent, white icons, light status bar icons.

### PgSwitcherTitle
A row used as the title of owner tab pages: PG name (`title`, one line, ellipsis) + 4 gap + `chevronDown` 20 in `muted`. The whole row is tappable (minimum height 48) and opens the PG switcher sheet.

### AppBottomNav
- Height 64 + bottom inset, `surface`, 1 dp `hairline` top border. 3 or 4 equal items.
- Each item: icon 24 on top, label (`caption`) 4 below.
- Inactive: regular icon, `muted`, label `caption`. Active: **fill** icon, `petrol`, label `petrol`, weight 600, plus a 2 dp `petrol` bar across the very top edge of the item, 32 wide, centred.
- Pressed: `petrolTint` background. No pill indicator. No ripple.
- Badge (optional count): sits top-right of the icon, minimum 16 x 16, radius 8, `petrol` background, white `caption` text. Counts above 99 show `99+`.

### LedgerSheet
`surface` container, top and bottom `hairline` borders, no radius. Parameters: `padding`. Margin bottom 12 when stacked.

### SectionHeader
Padding left 16, top 24, right 16, bottom 8. Title in `label` style with weight 600 and colour `muted`. Optional trailing: count or text in `secondary`, or a small text button.

### LedgerRow
- Minimum height 64. Padding 16 left and right, 12 top and bottom.
- Optional leading (usually `RoomTile`) + 12 gap.
- Title: `bodyMedium`, one line, ellipsis. Subtitle: `secondary`, one line, ellipsis.
- Trailing column, right-aligned: amount (`heading`, via `Money`), then 4 gap, then `StatusChip`.
- Optional **inline actions** row under the subtitle: 4 gap above, text buttons (`buttonSmall`, `petrol`), 44 dp tall, 16 between them, left-aligned with the title.
- Divider: 1 dp `hairline`, starting where the title text starts (16 if no leading, 72 if there is a 44 leading) and running to the right edge. The last row of a sheet has no divider.
- Pressed: `petrolTint` background.

### RoomTile
44 x 44, radius 6, background `ground`, 1 dp `hairline` border. Label (room number) in `label` weight 600, ink, centred, one line, scales down to fit. No label: `bed` icon 20 in `muted`.

### StatusChip
Minimum height 20, horizontal padding 8, radius 4, text `caption` weight 600.

| Kind | Text | Background | Border |
|---|---|---|---|
| `paid` | `paidFg` | `paidBg` | none |
| `pending` | `pendingFg` | `pendingBg` | none |
| `overdue` | `overdueFg` | `overdueBg` | none |
| `due` | `muted` | `surface` | 1 dp `hairline` |

### Money
`Money(paise, style, color)`. Renders the rupee sign at 85 percent of the font size followed by the amount with Indian digit grouping. Zero shows `₹0`. A negative amount shows a real minus sign (U+2212) before the rupee sign. Whole-rupee amounts show no decimals; amounts with paise show two (`₹6,500.50`). Never format money anywhere else.

### Buttons: `AppButton`
Constructors: `.primary`, `.secondary`, `.text`, `.destructive`. Parameters: `label`, `onPressed` (null = disabled), `loading`, `icon` (optional), `expand` (full width).
- Height 48 (`.text`: 44), radius 8, label `button` (`.text`: `buttonSmall`), icon 20 with 8 gap.
- **Primary:** background `petrol`, text white; pressed `petrolPressed`.
- **Secondary:** background `surface`, 1 dp `petrol` border, text `petrol`; pressed `petrolTint`.
- **Text:** no background, text `petrol`; pressed `petrolTint`; horizontal padding 12.
- **Destructive:** background `overdueFg`, text white; pressed `overduePressed`. Used only on confirm sheets.
- **Disabled:** background `disabledBg`, text `muted`; `.text` disabled: text `muted`.
- **Loading:** label replaced by a 20 dp white circular indicator (2 dp stroke; `petrol` on secondary and text). The button keeps its width. Taps are ignored.
- Press feedback: scale to 0.98 over `AppMotion.fast`. No ripple.

### AppTextField
- Label above the field: `label` style, 6 gap. **No floating labels.** Optional "(optional)" is part of the label text.
- Field: height 52 (multi-line: minimum 96), `surface`, 1 dp `outline` border, radius 8, horizontal padding 14, text `body`, hint `body` in `muted`.
- Focus: 2 dp `petrol` border. Error: 2 dp `overdueFg` border. Disabled: background `ground`, border `hairline`, text `muted`.
- Helper text under the field: `secondary`, 4 gap. Error text replaces it: `secondary` in `overdueFg`. No character counters.
- Optional prefix or suffix inside the field.

### PhoneField
`AppTextField` with a fixed prefix block: `+91` in `bodyMedium`, 56 wide, a 1 dp `hairline` divider on its right. Digits only, maximum 10. Shown as `98765 43210` (a space after the fifth digit). Pasting `+91 98765 43210`, `098765 43210` or `9198765 43210` keeps only the last 10 digits. Valid when 10 digits starting with 6, 7, 8 or 9. The value handed to code is `+91` followed by the 10 digits.

### MoneyField
`AppTextField` with a `₹` prefix (`bodyMedium`, `muted`, 40 wide). Digits only, whole rupees, maximum 9 digits, live Indian grouping (`125000` shows `1,25,000`). Number keypad. The value handed to code is paise (rupees x 100). *Large variant* (record payment): text in the `display` style.

### SelectField
Looks like `AppTextField`; shows the chosen value (or hint) and `chevronDown` 20 in `muted` on the right. Tapping opens an `OptionSheet`. No dropdown menus anywhere.

### OptionSheet
A bottom sheet with a title, an optional search field (44 high) and rows of 56: title (`body`), optional subtitle (`secondary`), a `check` icon in `petrol` on the selected row. Choosing a row closes the sheet.

### DateField
`SelectField` with the `calendar` icon on the right. Shows `12 Nov 2026`. Opens the Material date picker themed with `petrol`.

### OtpField
Six boxes sharing the available width equally with 8 gaps, each 56 high, radius 8, 1 dp `outline` border, digit in `display` centred. The box that is next to be filled has a 2 dp `petrol` border. Error: all borders 2 dp `overdueFg` and a shake (section 7). One hidden text field captures the input (also paste). Filling the sixth digit submits.

### OptionRow
A row of equal-width option boxes with 8 gaps. With more than 3 options, a 2-column grid. Each box 44 high, radius 8, label centred.
- Unselected: `surface`, 1 dp `outline` border, `label` text.
- Selected: `petrolTint` background, 2 dp `petrol` border, text `petrol` weight 600.

### BedsStepper
A small control for a whole number, in one row: a `minus` button, the number, an `add` button. Width 136, height 44. Parameters: `value`, `min` (1), `max` (12), `onChanged`.
- Each button has a 44 x 44 tap area and a visible 36 x 36 square, radius 8, `surface`, 1 dp `outline` border, icon 20 in `petrol`. Pressed: `petrolTint` background.
- At a limit that button is disabled: border `hairline`, icon `muted`, taps ignored.
- The number between the buttons: `heading`, `ink`, centred, 48 wide. It is not typed into.
- Accessibility: the buttons are named `bedsFewer` and `bedsMore`; the number is read with `layoutBedsCount`. Used first by O12 (`UI_SCREENS_OWNER.md`). Add it to the gallery.

### UnderlineTabs
Height 44, `surface`, 1 dp `hairline` bottom border, scrolls horizontally if needed. Each tab: horizontal padding 16, label `buttonSmall`, optional count after it (4 gap, `caption`). Selected: `ink` text, 2 dp `petrol` underline the full width of the tab. Unselected: `muted`.

### SwitchRow
Minimum height 56, padding 16 and 12. Label `body`, optional helper `secondary` under it, switch on the right. Switch: on = `petrol` track and white thumb; off = `outline` track and white thumb.

### KeyValueRow
Minimum height 48, padding 16 and 12. Label `secondary` on the left (flex 2). Value `body`, right-aligned (flex 3), up to two lines. Optional `lock` icon (16, `muted`) after the value for read-only values. Divider like `LedgerRow` (inset 16).

### AppBottomSheet and ConfirmSheet
- `surface`, top radius 16, barrier `ink` at 40 percent. Handle: 32 x 4, radius 2, `handle` colour, 8 below the top, centred.
- Padding 16. Title `title`. Content scrolls. Maximum height 90 percent of the screen. Pinned actions use the sticky bottom action style. Keyboard-aware.
- `ConfirmSheet`: title, body (`body`), an optional reason field, then a primary or destructive button and a text button "Cancel".

### AppSnack
Floating, 16 above the bottom navigation or bottom inset, margin 16 on the sides, background `ink`, text `secondary`-size in white, radius 8, padding 14 x 12. Optional action (`buttonSmall`, `snackAction`). Shown 3 seconds (4 with an action). One at a time. Use `AppSnack.show(context, message, actionLabel, onAction)`.

### EmptyState and ErrorState
Centred column filling the available space, padding 32: icon 40 in `muted`, 16 gap, title (`heading`, centred), 8 gap, body (`secondary`, centred, maximum width 280), 24 gap, optional button (minimum width 160). `ErrorState` uses the `warning` icon, always has a "Try again" button, and shows a plain-language reason.

### Skeleton
`SkeletonBlock(width, height)`: radius 4, `skeletonBase`, with a highlight sweeping left to right over `AppMotion.shimmer`, looped. `SkeletonList` shows 6 skeleton rows: a 44 square, two bars (60 percent and 40 percent of the text width, 14 high, 8 apart) and a 56-wide bar on the right. Skeletons stand in for content only; a bare spinner on an empty screen is not allowed. Buttons may show their own loading indicator.

### ProgressBarThin
Height 6, radius 3, track `hairline`, fill `petrol`. The caller gives a value from 0 to 1 (clamped).

### ProfileAvatar
Circle (size parameter: 72 on profile). Photo with cover fit, or a fallback: `ground` fill, 1 dp `hairline` border, first letter of the name in `title`.

### TickBadge
64 x 64 circle filled `paidBg` with a check mark drawn in `paidFg` (3 dp stroke, round caps). The check draws from nothing to complete over `AppMotion.tick` with `easeOutCubic`. Plays once when the widget first appears. If the system disables animations it appears fully drawn.

### Stamp
A rotated (-6 degrees) rectangle: 2 dp border and text (`heading`) in a status colour (`paidFg`, `pendingFg` or `overdueFg`), radius 4, padding 4 x 10, at 90 percent opacity. Sentence case, never all caps.

### ReceiptPaper
`surface`, no radius, 1 dp `hairline` border, and the **only shadow in the app**: offset (0, 1), blur 3, colour `ink` at 12 percent. A dashed divider (1 dp `hairline`, 6 on, 4 off) crosses the paper between header and body. At each end of the divider, a half circle (radius 8) is cut out of the paper edge (filled `ground`) so it looks like a torn ticket.

---

## 6. Backgrounds and images

- Default page background is the flat `ground` colour. No patterns, no gradients, no textures.
- **Photos are used only on the auth screens** (sign-in and code entry): one portrait photo, `assets/images/auth/auth_backdrop.jpg`, `BoxFit.cover`, covered by a flat `scrim` colour at **72 percent** opacity (tested: white text keeps at least 4.8:1 contrast even on a pure-white photo). No gradient overlay.
- If an image file fails to load, show a flat `petrol` fill instead. The screen must never break because an image is missing.
- Brand marks are SVG: `logo_mark.svg` (petrol tile) and `logo_mark_white.svg` (white mark for dark backgrounds). Rendered with `flutter_svg`.
- Empty states use icons only. No illustrations in version 1.
- Every image path comes from `AppAssets` (`UI_GUIDE.md` section 4). Replacing a file with the same name changes it everywhere.

---

## 7. Motion

Respect the system "reduce motion" setting (`MediaQuery.disableAnimations`): when on, skip every animation below except instant state changes.

| Where | What | Duration |
|---|---|---|
| Page changes | The platform default. Do not customise | default |
| Bottom sheet, dialog | Default slide and fade | `base` |
| Button press | Scale 0.98 and colour change | `fast` |
| Tab underline | Slides to the new tab | `base` |
| Skeleton | Shimmer loop | `shimmer` |
| Wrong OTP code | Boxes shake sideways: offsets 0, -8, 8, -6, 6, -3, 3, 0 dp | `shake` |
| Payment recorded or confirmed | `TickBadge` draws, the receipt paper slides up 12 dp while fading in, one light haptic tap | `tick` and `base` |
| List item removed | Fades and collapses | `base` |

Nothing else moves. No animated backgrounds, no parallax, no staggered list entrances, no bouncing, no pulsing.

**Haptics:** one light impact when a payment is recorded or confirmed and when the OTP is accepted. Nowhere else.

---

## 8. Copy rules

- Sentence case. Plain verbs. Short.
- The same word for the same action everywhere: the button "Mark as received" leads to the toast "Marked as received" and the history entry "Marked as received".
- Errors say what happened and what to do next. They never apologise or blame.
- Empty states invite one action.
- No filler greetings, no exclamation marks, no emoji, no "Let's get started".
- Do not write the app name in text. Use the `{appName}` placeholder (filled from `AppConfig.appName`) where it is needed.
- **All text lives in `lib/core/l10n/app_en.arb`.** The screen files list every string with its key. Use the keys exactly. Never concatenate translated pieces; use placeholders (`{name}`, `{amount}`) and ICU plurals.
- Hint text inside fields describes the format. It never looks like real data (no sample names, no real-looking numbers).

**Common strings.** Because only one screens file is loaded per session, every key that is used by more than one screens file is defined here, once. A key is never defined twice, and a screens file may only use its own keys and these.

| Key | Text |
|---|---|
| `actionCancel` | Cancel |
| `actionSave` | Save |
| `actionDone` | Done |
| `actionRetry` | Try again |
| `actionClose` | Close |
| `actionEdit` | Edit |
| `actionCopy` | Copy |
| `actionShare` | Share |
| `actionSeeAll` | See all |
| `actionSignOut` | Sign out |
| `statusPaid` | Paid |
| `statusPending` | Pending |
| `statusOverdue` | Overdue |
| `statusDue` | Due |
| `errorGeneric` | Something went wrong. Please try again. |
| `errorNetwork` | No internet connection. Check your connection and try again. |
| `errorNotAllowed` | You don't have access to this. |
| `errorSessionEnded` | Your session has ended. Please sign in again. |
| `optionalSuffix` | (optional) |
| `readOnlyHelper` | Set by your PG owner. |
| `copied` | Copied. |
| `statusConfirmed` | Confirmed |
| `statusRejected` | Rejected |
| `statusReversed` | Reversed |
| `chargeDue` | Due {date} |
| `chargePartPaid` | Part paid |
| `chargeCancelled` | Cancelled |
| `accountNotSure` | Not sure |
| `utrHelper` | The reference number in the UPI app or your bank message. |
| `profileDueDay` | Day {day} of every month |
| `receiptRecorded` | Payment recorded |
| `receiptConfirmed` | Marked as received |

---

## 9. Formatting rules

One file, `lib/core/format/`, and nothing else formats these things.

| Thing | Format | Example |
|---|---|---|
| Money | rupee sign, Indian grouping, decimals only if there are paise | `₹6,500`, `₹1,25,000`, `₹6,500.50` |
| Date | day, short month, year | `12 Nov 2026` |
| Short date (same year) | day, short month | `12 Nov` |
| Month | full month, year | `November 2026` |
| Time | 12-hour, lower-case am or pm | `3:42 pm` |
| Phone | `+91` then groups of 5 | `+91 98765 43210` |
| Relative time (inbox) | under 1 min `Just now`; under 1 hour `{n} min ago`; under 24 hours `{n} h ago`; yesterday `Yesterday`; older: short date | `2 h ago` |
| Bed and room | `Room {room}, bed {bed}` or `Bed {bed}` | `Room 101, bed A` |
| Counts | ICU plural | `1 guest`, `3 guests` |

Dates and times come from the database in UTC (or as plain dates) and are shown in India time.

---

## 10. Accessibility

- Tap targets are at least 48 x 48. The one exception is inline text actions inside list rows (44).
- Every icon-only button has a semantic label.
- Text and background pairs in this file meet 4.5:1; input borders and the switch track meet 3:1.
- Status is never colour-only.
- Layout survives system text size 1.3 and a 320 dp wide screen without overflow.
- Focus order follows reading order. Errors are announced (use semantics live region on error text).

---

## 11. The component gallery (debug only)

A hidden screen at `lib/dev/component_gallery.dart`, registered as the route `/dev/gallery` **only when `kDebugMode` is true**. It shows every component in section 5 in every state, on a `ground` background, plus a type specimen (each text style with the label "Aa 0123456789 ₹1,23,456") and a colour swatch list.

It may use generic labels such as "Primary text", "Secondary text", "Label", and the figure `₹1,23,456` to check formatting. It must **never** contain names of people, PGs, phone numbers or realistic data. It is the only place allowed to show a component with placeholder content, and it is not part of release builds.
