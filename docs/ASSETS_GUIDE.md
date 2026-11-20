# Assets guide

Last updated: 12 Nov 2026

Everything visual that is a **file** (photo, logo, icon, font) and how to swap it later without touching code. The rule: every image in the app is referenced by a fixed file name through `AppAssets` (see `UI_GUIDE.md` section 4). To change an image, replace the file **keeping the same name and format**. Nothing else changes.

---

## 1. The files the app needs

| File | Path (inside `app/`) | Format and size | Used for | Status |
|---|---|---|---|---|
| Sign-in photo | `assets/images/auth/auth_backdrop.jpg` | JPG, 1080 x 1920 (9:16 portrait), at most 350 KB | Background of sign-in and code screens (A1, A2) | **Placeholder** (flat petrol). Replace with a real photo |
| Logo, petrol tile | `assets/brand/logo_mark.svg` | SVG, square, `viewBox="0 0 64 64"` | Role gate (A3), receipt (S1) | **Placeholder** |
| Logo, white mark | `assets/brand/logo_mark_white.svg` | SVG, transparent background | On the photo (A1) | **Placeholder** |
| App icon | `assets/brand/app_icon_1024.png` | PNG, 1024 x 1024, opaque (no transparency) | Launcher icon source | **Placeholder** |
| Adaptive icon foreground | `assets/brand/app_icon_foreground_1024.png` | PNG, 1024 x 1024, transparent | Android adaptive icon | **Placeholder** |
| Splash mark | `assets/brand/splash_mark.png` | PNG, 512 x 512, transparent, white mark | Splash screen | **Placeholder** |
| Fonts | `assets/fonts/IBMPlexSans-Regular.ttf`, `-Medium.ttf`, `-SemiBold.ttf`, `OFL.txt` | TTF | All text | **Final.** Included. Keep the licence file |

That is all. There are no other images in the app: empty states use icons, and everything else is drawn in code.

---

## 2. The placeholders (already installed)

The placeholder files are already in your project folder, in `app/assets/` (`brand`, `images/auth` and `fonts`). There is nothing to unzip or copy. What is left to do in step F1 of `PROGRESS.md`:

1. Make sure `pubspec.yaml` lists the asset folders and the font family (the exact lines are in `UI_GUIDE.md` section 4).
2. Run `flutter pub get`, then the icon and splash commands from `UI_GUIDE.md` section 4.

The placeholder logo is a white house with a door on a petrol square. It exists only so the app runs and looks tidy while you decide on a name and a logo.

---

## 3. The sign-in photo

This is the only photo in the app. It appears on the sign-in and code screens, behind a dark petrol overlay at 72 percent, with a white sheet covering the lower half.

**What works best: a real photo of your friend's PG.** It is the one thing nobody else has, and it makes the app feel like it belongs to a real place. Ask him for permission and take it yourself:
- the front of the building in soft daylight, or
- a clean corridor with room doors, or
- a tidy room with the window light on a bed.

**Requirements**
- Portrait, 9:16. Crop to **1080 x 1920**.
- The interesting part of the picture must sit in the **top 45 percent** (the white sheet covers the bottom half).
- No people's faces, no readable text, no signboards, no logos, no watermark.
- Medium tones and some detail. A very bright or a very flat photo looks dull under the overlay.
- JPG, quality about 80, at most 350 KB, sRGB colours.

**How to prepare it**
1. Crop to 9:16 with any photo editor (the phone's gallery editor works).
2. Resize to 1080 x 1920.
3. Export as JPG at about 80 percent quality. Check the file size.
4. Save it as `auth_backdrop.jpg` and replace the placeholder.
5. Run the app and look at sign-in on a real phone, with and without the keyboard open. The text on top must be easy to read.

**If you generate an image with AI instead.** AI pictures often have small giveaways (warped lines, odd textures), so choose a simple subject and look closely before using it. Use one of these prompts, in portrait 9:16:

*Building exterior*
> Photorealistic photograph, vertical 9:16, the front of a modern three-storey paying-guest hostel building in an Indian city in soft late-afternoon light, plain clean facade with simple balconies, shot at eye level with a 35mm lens, calm muted colours, no people, no text, no signage, no logos, no watermark, straight vertical lines, lower half of the frame uncluttered

*Corridor*
> Photorealistic photograph, vertical 9:16, a clean hostel corridor with evenly spaced plain wooden room doors and a window at the far end with soft daylight, polished floor, muted colours, no people, no text, no numbers on the doors, no posters, no watermark, straight lines, lower half of the frame uncluttered

*Room*
> Photorealistic photograph, vertical 9:16, a tidy shared hostel room with two single beds with plain white linen, a window with soft morning light, wooden floor, minimal furniture, muted colours, no people, no text, no posters, no watermark, lower half of the frame uncluttered

Reject any result that has text, distorted furniture, repeated patterns or an artificial glow. Do not use images of real brands or real people.

---

## 4. Name and logo

**The name** is `AppConfig.appName` and `app_name` in the Android strings file (`UI_GUIDE.md` section 4). Before you decide, check that the name is not already used by another app on the Play Store, that a matching web domain is available, and that it does not clash with a registered trademark.

**The logo.** Ask a designer, or make a simple one yourself. Requirements:
- A simple geometric mark that still reads at 24 x 24. No tiny details, no text in the mark.
- Provide two SVG versions: `logo_mark.svg` (the mark on a petrol rounded square, 64 x 64 viewBox) and `logo_mark_white.svg` (the mark alone in white on a transparent background).
- SVG rules: a proper `viewBox`, no embedded bitmap, no gradients, no live text (convert text to outlines), under 20 KB.

**App icon files**
- `app_icon_1024.png`: 1024 x 1024, fully opaque, the mark centred on petrol.
- `app_icon_foreground_1024.png`: 1024 x 1024, transparent, the white mark inside the **central two thirds** (Android crops the outer part of adaptive icons in different shapes).
- `splash_mark.png`: 512 x 512, transparent, white mark, kept within the central 60 percent.

After replacing files, run the two generator commands in `UI_GUIDE.md` section 4 and test the icon on the home screen, in the app drawer and in the splash screen. Later, for the Play Store listing, you will also need a 512 x 512 PNG icon.

---

## 5. Fonts

IBM Plex Sans is included in the placeholder zip (Regular, Medium, SemiBold) with its licence (SIL Open Font License 1.1). The licence allows bundling in an app; keep `OFL.txt` next to the fonts. Checked in the font files: the ₹ sign is present, and the digits are all the same width, so numbers line up without any font feature.

The font does not include Hindi, Kannada or other Indian scripts. Names typed in those scripts are drawn with the phone's own fonts. Test this with a real name typed in Hindi or Kannada on a real phone during the checklist (`UI_GUIDE.md` section 10). If it looks wrong, ask the big model before adding any font.

---

## 6. Images that people upload (not in the app folder)

Profile photos, ID document photos and payment screenshots are uploaded by users and stored in **private** Supabase Storage buckets. They are not assets and never go in the project.

| Bucket | Path inside the bucket | Who uploads | Who can read |
|---|---|---|---|
| `profile-photos` | `{personId}/{uuid}.jpg` | The person | The person, and the staff of a PG the person has stayed in |
| `documents` | `{personId}/{uuid}.jpg` | The person (or staff for a guest who lives there now) | The person, and staff while the person lives there |
| `payment-screenshots` | `{stayId}/{uuid}.jpg` | The guest of that stay | The guest, and the PG's staff |

Each upload also adds a row to the `files` table; the database already controls who may read those rows. The bucket rules themselves are a security-critical migration (`006_storage_policies.sql`). **Ask the big model to write and review it.** Until it exists, keep `AppFlags.uploadsEnabled` set to false so the upload controls stay hidden.

---

## 7. Replacement checklist

- [ ] Real sign-in photo prepared (9:16, 1080 x 1920, under 350 KB) and saved as `auth_backdrop.jpg`
- [ ] Final name chosen; `AppConfig.appName` and the Android `app_name` changed
- [ ] `logo_mark.svg` and `logo_mark_white.svg` replaced (same names)
- [ ] `app_icon_1024.png`, `app_icon_foreground_1024.png`, `splash_mark.png` replaced
- [ ] Icon and splash regenerated; checked on a real phone
- [ ] Searched the code for the old placeholder name; none found
- [ ] Sign-in checked on a real phone with and without the keyboard
