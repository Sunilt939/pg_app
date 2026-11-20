# PG Rent App: project rules

Read this file at the start of every session, then read the files the task touches. If a request conflicts with a rule here, say so before writing any code.

## 1. What we are building

A mobile app (Android first) for PG owners and their guests in India.

- **Owner:** creates one or more PGs, adds rooms and beds, adds guests by phone number, sees who has paid, records cash and UPI payments, sends reminders.
- **Guest:** logs in with phone OTP (only if an owner added the number), sees rent due, history and receipts, pays by UPI, and tells the owner "I have paid".
- One phone number can be both an owner and a guest. The app decides which view to show from the database (`rpc_my_context`), never from a button the user taps.

**Out of scope for version 1:** payment gateway, rent reliability score, complaints, announcements, web dashboard. Text must still be translatable from day one (see section 8).

## 2. Stack (do not change without asking)

| Layer | Choice |
|---|---|
| App | Flutter (Dart), Android first |
| State management | Riverpod |
| Navigation | go_router |
| Backend | Supabase: PostgreSQL 15+, phone OTP auth, Storage, Edge Functions (TypeScript) |
| Push notifications | Firebase Cloud Messaging |
| Money | Integer paise everywhere. Rupees only on screen |

Allowed extra packages: `intl`, `url_launcher`, `share_plus`, `pdf`, `printing`, `flutter_secure_storage`, and the ones the UI pack approves: `flutter_svg`, `phosphor_flutter`, `image_picker`, plus the dev dependencies `flutter_launcher_icons` and `flutter_native_splash`. Ask before adding any other package. Never use `google_fonts` (fonts are bundled).

## 3. Independence rules (the most important section)

The goal: changing one part must not force changes in another.

1. **Three contracts. Parts talk to each other only through these.**
   - **Database contract:** the app *reads* from views (`v_*`) and a few plain tables, and *writes* only by calling `rpc_*` functions (section 5). The tables behind them can be reorganised freely.
   - **Data contract:** each feature has an abstract repository in `domain/`. Only `data/` implements it, and only `data/` talks to Supabase.
   - **Design contract:** every colour, font size, spacing and radius comes from `core/theme`. No hard-coded values inside screens.
2. **Dependencies point one way:** `presentation` depends on `domain`; `data` depends on `domain`. `presentation` never imports `data`. A feature never imports another feature's `data/` or `presentation/`. Shared code lives in `core/`.
3. **Business rules live in SQL, not in Dart.** Balances, statuses (paid, partial, due, overdue), who may do what, and how a payment is split across charges are calculated by the database. Dart only formats and displays. If you find yourself adding up money in Dart, stop and use a view or function.
4. **Settings are data, not code.** Payment methods, charge types, room types, amenities, reminder timing and billing rules are rows in tables.
5. **Every database change is a new migration file** in `supabase/migrations/` (`003_name.sql`, `004_name.sql`, ...). Never edit a migration that has already been applied. Never change the database by hand in the dashboard.
6. **Expand, then contract.** Old app versions stay installed on phones. Add new columns, tables and functions first. Remove or rename old ones only after no released app uses them. Never change the inputs or result shape of an existing `rpc_*` function; add a new function or a new optional parameter with a default.
7. **Modules point upwards only** (listed in the header of `001_core_schema.sql`). Billing never calls Comms. Comms reacts to billing events.

## 4. Folder layout

```
pg_app/
  START_HERE.md  AI_INSTRUCTIONS.md  PROGRESS.md     (read first; PROGRESS.md decides what is next)
  docs/                     all planning documents and DECISIONS.md
  supabase/
    migrations/             001 to 004, then new numbered files
    functions/              Edge Functions: send-reminders, daily-charges, ... (later)
    _local_tests_FAKE_DATA/ database checks with FAKE people. Scratch PostgreSQL only, locked, never on Supabase
    dev/                    dev_reset.sql (dev project only)
  app/
    assets/                 brand/, images/auth/, fonts/
    env/                    dev.json and prod.json (never committed), dev.json.example
    tool/                   check_ui_rules.sh
    lib/
      core/                 theme/ (tokens.dart, app_theme.dart), l10n/, router/, config/,
                            errors/, format/ (money.dart, dates.dart), widgets/ (shared components)
      features/
        auth/               { data/, domain/, presentation/ }
        pg/                 create PG, switcher, payment accounts, settings
        rooms/              rooms and beds
        tenants/            add guest, list, detail, vacate
        billing/            charges, payments, receipts
        reminders/
        guest_home/         dues, history, pay, profile
```

Assets, `env/` files and the UI check script are listed in `UI_GUIDE.md` section 6.

Each feature folder has the same three parts: `domain/` (plain Dart models and abstract repository), `data/` (Supabase implementation), `presentation/` (screens, widgets, Riverpod providers).

## 5. The database contract

Source of truth: `supabase/migrations/` (`001` tables, `002` write functions, `003` read views for the screens, `004` two more functions). Money columns end in `_paise`.

### Reads (views and tables the app may select from)

| Name | Use |
|---|---|
| `v_stay_balances` | One row per stay: charged, outstanding, overdue, credit (advance), pending verification, oldest unpaid due date. Guest home and owner tenant list |
| `v_charge_balances` | One row per charge with paid, outstanding and status (`paid`, `partial`, `due`, `overdue`, `void`) |
| `v_pg_monthly_summary` | Owner dashboard: expected, collected, pending, overdue per month |
| `v_collections_by_account` | How much reached each receiving account, by month and method |
| `v_guest_list` | One row per stay with the guest, room, bed, balances, `attention_state`, pay-now and next-due figures. Owner home, guest list, guest detail, guest home |
| `v_payment_feed` | Every payment with guest, room, method, account and optional UPI details joined in. Payments tab, payment detail, guest history |
| `v_receipt_detail` | Everything the receipt prints, in one row (with what the payment paid for) |
| `v_pg_overview` | Per PG: counts for the guest filter tabs, overdue total, number of payments waiting |
| `v_pg_setup_status` | Per PG: rooms, accounts and guests counts for the setup checklist |
| `v_bed_occupancy` | Every bed with its room and who sleeps there now |
| `v_collections_month_total` | Money received per PG per month |
| tables | `pgs`, `rooms`, `beds`, `stays`, `stay_bed_assignments`, `stay_rent_terms`, `charges`, `payments`, `payment_upi_details`, `receipts`, `pg_payment_accounts`, `pg_billing_settings`, `reminder_rules`, `notifications`, lookups |

### Writes (the only ways to change money and stays)

| Function | Who | What it does |
|---|---|---|
| `rpc_my_context()` | anyone signed in | Returns the person, the PGs they work in and their own stays. Used right after login |
| `rpc_create_pg(name, line1, city_id, ...)` | anyone signed in | Creates a PG, makes the caller its owner, adds default settings and reminder rules |
| `rpc_create_stay(pg_id, phone, name, bed_id, join_date, rent_paise, deposit_paise, billing_day, billing_starts_on, deposit_already_paid)` | owner, manager | Finds or creates the person by phone, creates the stay, rent terms, bed and deposit charge |
| `rpc_set_stay_rent(stay_id, rent_paise, effective_from)` | owner, manager | Rent change from a date; old rent stays in history |
| `rpc_add_charge(stay_id, type_code, amount_paise, due_date, ...)` | owner, manager | One-off charge (electricity, laundry, damage) |
| `rpc_void_charge(charge_id, reason)` | owner, manager | Cancels a charge; money already on it becomes credit |
| `rpc_record_payment(stay_id, amount_paise, method_code, paid_on, account_id, note, payer_app_code, utr)` | owner, manager, caretaker | Confirmed immediately (cash, or UPI seen in the bank). Splits across charges, makes a receipt |
| `rpc_report_payment(stay_id, amount_paise, method_code, paid_on, account_id, payer_app_code, payer_phone, utr, note, screenshot_file_id)` | the guest | "I have paid". Waits as `pending`. Everything except amount and method is optional |
| `rpc_confirm_payment(payment_id, account_id)` | owner, manager, caretaker | Confirms a pending payment. The owner may set or correct the account it reached |
| `rpc_reject_payment(payment_id, reason)` | owner, manager, caretaker | Rejects a pending payment with a reason |
| `rpc_reverse_payment(payment_id, reason)` | owner, manager | Undoes a confirmed payment that was entered wrongly |
| `rpc_vacate_stay(stay_id, leave_date)` | owner, manager | Marks the guest as left. Stay is kept as history, bed freed, reminders stop |
| `rpc_add_rooms(pg_id, first_room_number, room_count, beds_per_room, room_type_code, floor, prefix)` | owner, manager | Adds many rooms with beds A, B, C ... in one all-or-nothing step |
| `rpc_add_room_layout(pg_id, rooms)` | owner, manager | Adds a whole layout in one all-or-nothing step: a JSON list of rooms, each with a number, a floor and a bed count (1 to 12). Used by the floor setup page |
| `rpc_correct_guest_name(person_id, full_name)` | owner, manager | Fixes a guest's name until the guest has signed in for the first time |
| `rpc_generate_monthly_charges(month)` | scheduler only | Creates rent charges. Safe to run repeatedly. Run it daily for the current and the next month |

Errors: functions raise plain-English messages meant for the user. Show the message as is. SQLSTATE `42501` means not allowed, `23505` means duplicate (for example a UTR already used), `P0001` means a business rule was broken.

### Still to write (follow the same pattern, one migration each)

`rpc_give_notice` (guest gives notice), `rpc_send_reminder_now`, `rpc_move_bed`, `rpc_settle_deposit`, `rpc_add_member` (invite a manager), the reminder-sending Edge Function that reads `notifications` and `reminder_rules`, and `006_storage_policies.sql` (private buckets for photos, documents and screenshots; security-critical, so it is written and reviewed by the big model, not by a small one).

### Direct writes the app may do (everything else is read-only)

Own profile fields (`full_name`, `email`, `photo_file_id`), `emergency_contacts`, `person_documents`, `device_tokens`, `files`, `pg_payment_accounts`, `reminder_rules`, `rooms`, `beds`, `room_amenities`, `pg_billing_settings`, name/contact on `pgs`, marking `notifications` as read. Row-level security decides who may touch which row.

## 6. Money rules

- Store and calculate in integer paise. Never `double` for money. Format with `intl` using the `en_IN` locale: `₹1,25,000`, with decimals only when there are paise.
- Never edit or delete a payment or charge. Corrections are a reversal (`rpc_reverse_payment`) or a void (`rpc_void_charge`), followed by a new entry.
- Guest-reported payments are always `pending` until an owner, manager or caretaker confirms them.
- A UPI deep link cannot confirm that money arrived. Never show "Paid" because a UPI app was opened.
- "Which account did it reach" is optional for guests and is pre-filled when they pay through the app. The owner has the last word when confirming.

## 7. Security rules

- Row-level security is on for every table. Every new table needs RLS enabled, at least one policy, and explicit grants in its migration. Never "simplify" a policy to make a screen work; fix the screen.
- The `service_role` key never goes into the app, the repo or an AI chat. Only the anon key and project URL live in app config. Secrets go in `.env` files that are not committed.
- New functions are locked by default. Grant execute to `authenticated` one function at a time, only for functions the app really calls.
- Personal data stays minimal: ID documents are stored as a private file plus the last 4 characters. Never store a full Aadhaar number.
- Files go in private Storage buckets and are opened with short-lived signed links. Storage policies are part of a migration too.
- Before release, run the privacy tests (the scenarios in `supabase/_local_tests_FAKE_DATA/`, adapted by the big model for a scratch database, never run against the real project): owner A must not see owner B's guests, a guest must not see other guests, a signed-out user must see nothing.

## 8. Design system

The complete visual specification is the UI pack: `UI_GUIDE.md`, `UI_DESIGN_SYSTEM.md`, `UI_SCREENS_SHARED.md`, `UI_SCREENS_OWNER.md`, `UI_SCREENS_GUEST.md` and `ASSETS_GUIDE.md`. Where this section and the UI pack differ, **the UI pack wins** (the colour values below are the same). Small models load only `UI_DESIGN_SYSTEM.md` plus the one screens file for the screen they build.

The app must look like a considered product, not a template. Build `core/theme` first, then a hidden "component gallery" screen that shows every component and the type specimen. Check it on a real phone.

### Colour (text pairs below meet WCAG AA 4.5:1)

| Token | Hex | Use |
|---|---|---|
| `petrol` | `#1A4D6B` | Primary buttons, links, active tab |
| `ground` | `#F2F4F6` | App background |
| `surface` | `#FFFFFF` | Lists, sheets, inputs |
| `ink` | `#1B2631` | Main text |
| `muted` | `#5B6772` | Secondary text |
| `hairline` | `#DDE2E7` | Dividers and borders |
| `paid` | text `#187544` on `#E3F3EA` | Status chip |
| `pending` | text `#8F5A00` on `#FCF0D6` | Status chip |
| `overdue` | text `#B42318` on `#FDE8E6` | Status chip |

Light theme only in version 1. Status always shows a word (Paid, Pending, Overdue), never colour alone.

### Type, space, shape

- **Type:** IBM Plex Sans for Latin text and numbers, with Noto Sans (Devanagari, Kannada, Telugu, Tamil) as fallbacks. The gallery must prove that the ₹ sign renders and that figures line up in columns (tabular figures, if the font offers them). Scale: 12, 14, 16, 20, 28. Weights 400, 500, 600. Body text is never below 16.
- **Space:** multiples of 4 (4, 8, 12, 16, 24, 32). Tap targets at least 48.
- **Shape:** inputs and buttons radius 8, status chips radius 4, bottom sheet top corners 16. Do not use one radius for everything.
- **Depth:** lists are rows on a white surface separated by 1px hairlines, not stacks of identical cards. No drop shadows on list items. At most one raised element per screen.
- **Alignment:** left-aligned. Amounts are right-aligned in lists.
- **Dates and numbers:** `12 Nov 2026` (never `11/12/2026`), Indian digit grouping, 12-hour time.
- **Icons:** one icon family (Lucide or Phosphor), one stroke weight. No emoji as icons. No stock illustrations.
- **Motion:** only motion that answers a tap (a payment tick, a sheet opening). No entrance animations on lists.

### Layout concepts

- **Owner home is a work queue, not a dashboard of coloured tiles.** One summary line for the month (expected, collected, pending), then "Needs attention": overdue guests and payments waiting for confirmation, each with one-tap actions ("Remind", "Mark as received").
- **PG switcher** sits in the app bar title, like an account switcher.
- **Guest home** leads with what is due and when. History and receipts below.
- **The receipt is the one memorable screen:** a paper-receipt look with receipt number, date, guest, PG, amount and method, shareable as an image or PDF on WhatsApp. Everything around it stays quiet.
- Bottom navigation: at most 4 items.

### Copy

- Plain verbs, sentence case, the owner's own words (rent, advance, sharing, bed).
- The button, the confirmation and the history all use the same word: "Mark as received" then "Marked as received".
- Errors say what happened and what to do next. They do not apologise.
- Empty screens invite one action: "No guests in this PG yet. Add the first guest."
- No filler greetings, no "Let's get started", no emoji in text.

### Things that make an app look generated (avoid all)

Purple or blue gradient headers, gradient washes, glassy blur cards, identical rounded cards with the same soft shadow, ALL-CAPS eyebrow labels above headings, meta lines joined with middle dots, arrows appended to button text, emoji or clip-art icons, confetti, centre-aligning everything.

### Text and languages

All user-visible text goes through localisation files (`core/l10n/*.arb`). English first. Hindi and Kannada are added later by adding files, not by editing screens. Never concatenate translated sentences.

## 9. Working agreement for AI sessions

1. **One slice per session.** A slice is one small user-visible capability inside one feature (for example "owner adds a room with beds"). Before coding, list the files you will create or change and which contract each touches. Wait for a go-ahead when it touches more than one feature.
2. **Database first.** If the slice needs data changes: write the migration, then the SQL test, then the repository, then the screen.
3. **No logic duplication.** Do not copy a rule from SQL into Dart.
4. **Every screen has four states:** loading (skeleton, not a spinner on a blank page), empty, error (with a retry), and data.
5. **Tests that must exist:** SQL tests for visibility (who can see what) and for money (partial payment, advance, overpayment, reversal, void, duplicate UTR); Dart tests for money and date formatting and for each repository against a fake.
6. **Before saying "done":** `flutter analyze` is clean, tests pass, the screen was run on a real Android phone, and a short note was added to `docs/DECISIONS.md` if a decision was made.
7. **Small commits** with a message that says what the guest or owner can now do.
8. **Do not** add packages, rename migrations, loosen security rules, hard-code colours or text, put secrets in code, or "tidy up" files outside the slice without asking.
9. **No dummy data, ever.** No sample names, amounts, lists, images, mock repositories or demo modes anywhere in the app code (fakes live in `test/` only). Test with a separate dev Supabase project and real screens; wipe it with `dev_reset.sql`. Run `tool/check_ui_rules.sh` before every commit. Details: `UI_GUIDE.md` section 3.

## 10. Known limits and open decisions

- An owner who adds a phone number can see that person's name afterwards. Later: guest accepts an invitation before the stay becomes active.
- OTP SMS in India needs a registered sender (DLT). Choose the SMS provider and complete registration before the pilot. Decide whether to check the number before sending an OTP (saves SMS cost, but reveals whether a number is registered).
- Receipt PDFs are generated in the app in version 1. Move to an Edge Function if owners need them from a laptop.
- No proration for part months in version 1. The first rent charge is the full month on the billing day.
- Guests who joined before the app: use `billing_starts_on` and `deposit_already_paid` when adding them, so old months are not billed again.
- Storage bucket policies (`006`) and the reminder Edge Function are not written yet. Keep `AppFlags.uploadsEnabled` and `AppFlags.remindersEnabled` false until they exist.
- The app name (`AppConfig.appName`) and the logo files are placeholders. They can be replaced at any time without code changes (`UI_GUIDE.md` section 4).
- Rent reliability score and consent sharing come after the core app works. They are new tables that point at `persons` and `stays`; the existing tables do not change.
