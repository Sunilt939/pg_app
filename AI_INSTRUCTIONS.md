# AI_INSTRUCTIONS: read this first, every session

You are helping a non-technical person build a mobile app (Flutter and Supabase) for PG owners and their guests in India. Follow this file exactly. If the person asks for something that breaks a rule here, say so and follow this file.

All planning documents are in the `docs/` folder. The app is built in `app/`. The database is in `supabase/` and is already written and tested.

---

## 1. The one-page rule (strict, no exceptions)

1. Open `PROGRESS.md`. Find the **first unchecked item from the top**. That is the **only** item you may work on.
2. Do **not** start, prepare, scaffold or "quickly also add" anything for a later item. If asked to, refuse politely: "Page X comes first. Let's finish and approve it, then we continue."
3. An item is **finished** only when **all** of these are true:
   - a. It is built exactly as the spec says (nothing extra, nothing missing).
   - b. `flutter analyze` reports no problems.
   - c. The tests pass.
   - d. `./tool/check_ui_rules.sh` (run from the `app/` folder) prints `UI rules check: clean`.
   - e. You have shown the person the results of b, c and d.
   - f. The person tested it on their real phone with the **Page test** in `PROGRESS.md` and said "approved".
4. Only after the person says "approved": tick the box in `PROGRESS.md`, commit, tell them the name of the next item, and **wait** for them to say "start".
5. **Never tick a box yourself.** Never say something works if you did not run it. If you cannot run or test something, say so clearly.

---

## 2. What to read (and what not to)

Read in this order, and nothing more unless an item points to it:

1. `PROGRESS.md` (find your item)
2. `docs/PROJECT_RULES.md`
3. `docs/UI_DESIGN_SYSTEM.md`
4. The screens file named in the item (`docs/UI_SCREENS_SHARED.md`, `docs/UI_SCREENS_OWNER.md` or `docs/UI_SCREENS_GUEST.md`), and **only that screen's section**.

For foundation items (F1 to F6, N1), read the sections of `docs/UI_GUIDE.md` that the item names.

---

## 3. At the start of every session

Tell the person in plain words:
- which item is next,
- which files you will create or change,
- anything the spec does not cover (you will choose the simplest option and note it in `docs/DECISIONS.md`).

Then **wait for their OK** before writing code.

---

## 4. How to build one page

Work in this order:
1. The data part (a repository: an interface and its Supabase implementation).
2. Providers (Riverpod).
3. The screen widgets, using only components from `docs/UI_DESIGN_SYSTEM.md`.
4. The text strings in `app/lib/core/l10n/app_en.arb`, with the **exact keys and English text** from the spec.
5. Tests.

Every screen that loads data has four states: loading (skeleton), empty, error with a retry button, and data.

If a button or link would lead to a page that is **not approved yet, do not show it** (no dead buttons, no greyed-out buttons, no "coming soon").

---

## 5. Hard rules (never break these)

1. **No dummy data, ever.** No sample names, phone numbers, amounts, lists, images, fake receipts, mock data or demo mode in the app code. Fakes may exist only in `app/test/`. Empty screens must show the real empty state.
2. **Design tokens only.** No hard-coded colours, font sizes, spacing, durations or asset paths. Everything comes from `lib/core/theme/` and `lib/core/assets/app_assets.dart`. Use `AppColors.surface` for white, never `Colors.white`.
3. **Use only the components listed in `docs/UI_DESIGN_SYSTEM.md`.** Do not use default Material widgets the design does not use (`Card`, `ListTile`, `ElevatedButton`, `FloatingActionButton`, `NavigationBar`, `Chip`, `AlertDialog`, floating-label inputs).
4. **All text comes from the ARB file**, with the keys given in the spec. Never hard-code text. Never rewrite the wording. The app name only through `{appName}` or `AppConfig.appName`.
5. **No money or status logic in Dart.** Read the figures from the views (`v_*`). Write only by calling the `rpc_*` functions. Dart only formats and displays.
6. **Never edit** `supabase/migrations/*.sql`, everything in `supabase/_local_tests_FAKE_DATA/`, or any file in `docs/` except `docs/DECISIONS.md` (add lines) and `PROGRESS.md` (tick boxes after approval).
7. **If any SQL fails, STOP.** Do not change the SQL. Ask the person to send the exact error to the big model.
8. **Never write or change security rules** (row-level security policies, storage policies, grants, who can see what). Ask the person to consult the big model.
9. **Secrets:** never put a secret in code, in chat or in git. The `service_role` key must never appear anywhere in the app. Only `app/env/dev.json` and `app/env/prod.json` hold the Supabase URL and anon key, and they are not committed.
10. **Packages:** use only the packages listed in `docs/UI_GUIDE.md` section 5 and the core stack in `docs/PROJECT_RULES.md` section 2. Ask before adding any other.
11. **One page per session and one commit per page.** The commit message says what the owner or guest can now do.
12. **Fake data files are off limits.** Never run, copy from, or adapt anything in `supabase/_local_tests_FAKE_DATA/` against the Supabase project or the app. Never insert test, sample or fake rows into the database. Real test data is created only by the person, through the app screens.
13. **When the spec is unclear**, choose the simplest option that follows the design system and add one line to `docs/DECISIONS.md`. Never invent colours, sizes or wording.

---

## 6. When you think a page is finished

1. From the `app/` folder run: `flutter analyze`, the tests, and `./tool/check_ui_rules.sh`.
2. Tell the person, in plain words:
   - what you built,
   - how to run it on their phone,
   - the **Page test** steps for this page (see `PROGRESS.md`),
   - the results of the three checks.
3. **Stop and wait.** Do not tick the box. Do not start the next page.

---

## 7. If the person reports a problem

Fix only that page. Run the three checks again. Show the results. Wait again. Do not start the next page.

---

## 8. How to talk to the person

Short, plain English. No jargon. One question at a time. Say exactly what to tap and what they should see. If you are unsure, say so and ask. If you fail twice at the same problem, tell the person to take it to the big model with the exact error.
