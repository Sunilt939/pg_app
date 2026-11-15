# PG Rent App: status, decisions and roadmap

Last updated: 12 Nov 2026

This file is the handoff. It says what the product is, what has been decided, what already exists, what is still to build, and in which order. Read it together with `PROJECT_RULES.md`.

**Reading order for any AI session**

1. `PROJECT_RULES.md`: the rules, contracts and design tokens. **It wins if anything here disagrees with it.**
2. This file: current state, user flows, roadmap.
3. `supabase/migrations/*.sql`: the real database. The migrations are the truth for table and column names.
4. For any screen work: the UI pack (`UI_GUIDE.md` first). It wins on anything visual.
5. The person's current request.

If a request conflicts with something above, stop and say so before writing code.

---

## 1. The product in one page

A mobile app (Android first, iOS later) that replaces a PG owner's notebook and WhatsApp reminders.

**Why it exists.** A friend runs a PG. He struggles to collect rent and advances, to remember who has paid and who has not, and to keep track of which of his several bank accounts and UPI numbers received which payment. Some guests pay cash, so the owner must be able to record it.

**Who uses it**

- **Owner (or manager, or caretaker):** creates PGs, rooms and beds, adds guests by phone number, records cash and UPI payments, confirms payments guests report, sends reminders, marks guests as vacated.
- **Guest:** logs in with phone OTP, sees what is due and when, what is paid, the advance balance, history and receipts. Pays by UPI and taps "I have paid". Can edit only their own profile details.

**The owner stays in control.** A guest can only log in as a guest if an owner added their number. Rent, advance, join date, room and payment records can only be changed by the owner's side.

**One phone number can be both** an owner and a guest. The app decides the view from the database (`rpc_my_context`), never from a button the user taps.

**Version 1 does not include:** payment gateway, rent reliability score, complaints, announcements, web dashboard, languages other than English (text must still be translatable from the start).

---

## 2. Decisions made, and why

| # | Decision | Why |
|---|---|---|
| 1 | Mobile app first, Android first, built with **Flutter** (Dart) | Guests and owners live on their phones; OTP, push, UPI links and WhatsApp sharing work best in an app. Flutter can later produce a web version from the same code |
| 2 | **Supabase** (PostgreSQL, phone auth, Storage, Edge Functions) rather than Firebase | The data is relational (people, PGs, stays, charges, payments). Reports are simple SQL, and security rules are enforced by the database itself |
| 3 | **Phone OTP for everyone**; role decided by data | One number can be owner and guest. No "owner or guest?" button at the start |
| 4 | A guest can log in only if an owner added their number. A new number can become an owner by creating a PG | Keeps fake accounts out and the data clean |
| 5 | **Person is separate from Stay.** A person is one row per phone number. A stay is one visit to one PG with its own terms. Charges and payments hang off the stay | Moving to a new PG is a new stay for the same person; old stays stay as history. The later reliability score is a query over past stays |
| 6 | **Leaving a PG archives the stay** (`vacated`). It is never deleted | The owner needs records for disputes and accounts; the guest needs proof of what they paid. Guests get no reminders after leaving |
| 7 | **Money is a ledger.** Charges (owed), payments (received), allocations (which payment paid which charge). Balances are never stored; views calculate them | Partial payments, advances, late payment and corrections all work without the numbers drifting |
| 8 | Money is stored as **integer paise** | No rounding errors |
| 9 | Confirmed payments are **never edited or deleted**. Mistakes are reversed; wrong charges are voided | Trust and an audit trail |
| 10 | **Cash:** the owner (or staff) records it and it is confirmed at once. **Guest-reported payments** wait as `pending` until the owner confirms | Prevents false claims |
| 11 | **UPI in version 1:** a UPI link or QR that pays straight into the owner's account. The guest taps "I have paid"; the owner confirms. A payment gateway comes at the end | Money never passes through our app, which avoids financial licensing issues. A UPI link cannot prove that money arrived |
| 12 | **Optional payment details** on "I have paid": which app (GPay, PhonePe, ...), UTR, phone used, screenshot. If the guest pays through our app, the receiving account is pre-filled. The owner can set or correct the account when confirming | Easy to track which account got which payment, without making guests do extra work |
| 13 | A PG can have **several receiving accounts** (UPI IDs and banks), each with a nickname | The friend has multiple numbers and bank accounts |
| 14 | **Each guest has their own billing day** (1 to 28) | Many PGs bill from the joining date, not the 1st |
| 15 | Existing guests are moved in with `billing_starts_on` and `deposit_already_paid` | The first users are guests who joined months ago; old months must not appear as overdue |
| 16 | **Reads go through views; writes go through `rpc_*` functions** | Each business rule lives in one place, and tables can be reorganised later without breaking the app |
| 17 | **Row-level security on every table; deny by default** for grants and functions | A bug in the app cannot expose other people's data |
| 18 | Time zone for "today" is **India (IST)** | Overdue and due dates must match the owner's day |
| 19 | A **daily scheduled job** creates rent charges (current and next month; safe to repeat) | A guest added mid-month is picked up the same day |
| 20 | **Rent Reliability Score comes after the core app works**, uses only objective data, needs the guest's consent, and is not called a "CIBIL score" | Fairness, privacy (DPDP Act 2023) and avoiding confusion with credit scores |
| 21 | Design is **restrained and human-made in feel**: a work-queue owner home, hairline lists instead of identical cards, one memorable receipt screen, Indian number and date formats | The app should not look like a template. The full specification is the UI pack |
| 22 | The UI is specified **screen by screen** so that small AI models can build it exactly: tokens in code, a component list, every screen with layout, data source, states and exact wording | Small models follow exact instructions well and improvise badly |
| 23 | **No dummy data in the app, ever.** Test with a separate dev project and the real screens; one guarded script wipes it | Removing sample data later is painful and risky |
| 24 | **Screens read from purpose-built views** (`v_guest_list`, `v_payment_feed`, ...) so money and status are worked out in SQL, not in Dart | Keeps rules in one place and keeps the screens simple |
| 25 | **One photo only** (sign-in), everything else drawn in code; every image is replaceable by file name. App name and logo are **placeholders** swappable in minutes | The name and logo are not decided yet |

---

## 3. What exists today

### 3.1 Files delivered

Everything is organised in one project folder. `START_HERE.md` explains each file in simple words, `AI_INSTRUCTIONS.md` is the strict rulebook for the AI, and `PROGRESS.md` is the page-by-page checklist (one page at a time, each tested on a real phone before the next). The table below lists the individual files. The test files live in `supabase/_local_tests_FAKE_DATA/`: they contain fake people, are locked so they cannot run by accident, and are used only on a scratch PostgreSQL, never on a Supabase project.

| File | What it is |
|---|---|
| `PROJECT_RULES.md` | Rules for AI sessions: stack, independence rules, folder layout, database contract, money and security rules, design system, working agreement |
| `PROJECT_STATUS_AND_ROADMAP.md` | This file |
| `001_core_schema.sql` | Migration 1: all tables, constraints, indexes, guards, audit trail, views, row-level security, privileges, login-to-person linking |
| `002_core_functions.sql` | Migration 2: the write contract (`rpc_*` functions) and two private helpers |
| `tests_00_auth_stub.sql` | Test only: a stand-in for Supabase's `auth` schema and roles on plain PostgreSQL. Never run it on a real Supabase project |
| `tests_10_scenario.sql` | End-to-end scenario test (21 scenarios) |
| `003_ui_read_views.sql` | Migration 3: read-only views the screens use |
| `004_ui_write_functions.sql` | Migration 4: `rpc_add_rooms`, `rpc_correct_guest_name` |
| `tests_20_views.sql`, `tests_30_ui_functions.sql` | Tests for migrations 3 and 4. Run after the scenario test |
| `dev_reset.sql` | Dev-only wipe of all test data and logins; refuses to run without an explicit confirmation |
| `UI_GUIDE.md` | UI pack entry point: rules for small-model sessions, zero dummy data, name and logo swap, packages, navigation map, build steps U0 to U13, review checklist |
| `UI_DESIGN_SYSTEM.md` | Tokens (with code), icons, layout rules, every component, motion, backgrounds, copy and format rules |
| `UI_SCREENS_SHARED.md`, `UI_SCREENS_OWNER.md`, `UI_SCREENS_GUEST.md` | Every screen: layout, data source, behaviour, states and exact wording (about 470 text keys) |
| `ASSETS_GUIDE.md` | Images, logo, icons, fonts: what is needed, how to replace it, image prompts |
| `placeholder_assets.zip` | Placeholder logo, icons, splash mark and sign-in image, plus the IBM Plex Sans fonts with their licence |

There is **no Flutter code yet**. The app has not been started; the UI is fully specified (section 9, step 3 and the UI pack).

### 3.2 How the database was verified

Run on PostgreSQL 16 with the stand-in auth schema. The scenario test covers:

- Login creates or links a person; a guest added by an owner *before* first login is linked, not duplicated.
- Two owners: owner B sees none of owner A's PGs, guests, payments or balances, and cannot act on them.
- A guest sees only their own data, can edit only name, email and photo, and cannot change phone, stays, charges or payments, and cannot call the scheduler function.
- Payments clear the oldest charges first; partial payments; advance credit is picked up automatically when the next month's rent is created.
- A guest reports a UPI payment with optional details; the same UTR cannot be used twice (different letter case included); the owner confirms and corrects the receiving account.
- Reversing a payment reopens exactly what it had paid; confirmed payments cannot be edited.
- Dashboard and per-account collection views add up.
- Emergency contacts are visible to the owner only while the guest lives there; the guest's name, charges and payments stay visible to the PG afterwards.
- Vacating frees the bed, stops new reports, keeps history for both sides.
- The same person joins a second PG: a second stay, one person row, history intact.
- Existing guest onboarding: old months are not billed, deposit marked as received.
- The database refuses: deleting history, editing the audit log, over-allocating a payment, a bed from another PG, a receiving account from another PG.
- A signed-out (anonymous) user reads nothing.

The test expects exactly 20 error messages (each one is something that must be refused). Any other error is a bug.

The later migrations were tested the same way: `tests_20_views.sql` (each owner sees only their PG in every view, a guest sees their own two stays and loses the room after leaving, anonymous gets nothing, totals add up) and `tests_30_ui_functions.sql` (bulk rooms are all-or-nothing and refuse the wrong people, a guest's name can be corrected only before the guest has signed in, a guest can attach a screenshot that only that PG's staff can then read, and cannot attach someone else's file). `dev_reset.sql` was tested for refusal without confirmation (data untouched), full wipe with confirmation (reference data kept), and a clean restart.

**Not verified yet (do this in roadmap step 2 and later)**

- Running the migrations and tests on a real Supabase project (the stand-in is not Supabase itself).
- Supabase phone login, the trigger on `auth.users`, Storage policies, Edge Functions, scheduling.
- Performance with realistic volumes (the row-level security helper functions run per row; test with about 200 guests and 12 months of charges).

### 3.3 Bugs the testing found (already fixed)

1. A table named `pg_settings` collided with a built-in PostgreSQL view. It is now `pg_billing_settings`. **Do not name tables with a `pg_` prefix that matches a system view.**
2. The scheduler-only function could be called by a signed-in guest. PostgreSQL gives `EXECUTE` to everyone by default, and `ALTER DEFAULT PRIVILEGES ... IN SCHEMA` cannot remove that. The migration now revokes it globally and in the schema, and every function must be granted explicitly.
3. Money sums in views returned `numeric`; they are now cast to `bigint`.
4. Allocation rules now ignore allocations sitting on voided charges, so money freed by voiding can be reused.
5. A real-world gap: existing guests would have been billed for old months. `billing_starts_on` and `deposit_already_paid` were added.
6. The first version of `dev_reset.sql` still wiped the data when its safety check failed, because plain `psql` carries on after an error. The check and the wipe are now one all-or-nothing block, and both paths were re-tested with data present.
7. Writing the screen specs showed that screens needed data the first views did not give (names and rooms joined in, the receipt contents, the pay-now amount, monthly totals, whether a guest has signed in): migration 003 adds the views, so the app never adds up money.
8. A guest's optional payment screenshot had no way to be attached: `rpc_report_payment` now takes an optional `p_screenshot_file_id`, checked to belong to the caller.
9. A check of the real IBM Plex Sans files showed the ₹ sign exists, but there is no tabular-figures feature (the digits are already equal width) and no Indian-script glyphs; the UI pack says so.

### 3.4 Not built yet

- All Flutter code.
- Edge Functions: reminder sender, daily charge job scheduling, receipt/notification helpers.
- Supabase Storage buckets and their policies.
- Functions still to write: `rpc_give_notice` (guest), `rpc_send_reminder_now` (owner one-tap reminder), `rpc_move_bed`, `rpc_settle_deposit`, `rpc_add_member` (invite a manager). (The name-correction function and the vacancy view now exist.)
- `005_storage_policies.sql`: the private buckets for profile photos, ID documents and payment screenshots, with their policies. Security-critical: the big model writes and reviews it. Until then `AppFlags.uploadsEnabled` stays false.
- Late-fee logic (the settings columns exist; nothing calculates a late fee yet).
- Receipt image/PDF generation (`receipts.file_id` is unused in version 1; generate on demand in the app from the receipt row).
- Proration for part months (version 1 bills the full month on the billing day).
- Guest dispute flag ("this entry looks wrong").
- Everything after launch (section 12).

---

## 4. Architecture recap

```
Flutter app (Dart)            features/<name>/{domain, data, presentation} + core/
        |  HTTPS + login token
        v
The contract                  app side: repositories      database side: v_* views + rpc_* functions
        |
        v
Supabase                      Auth (phone OTP) | PostgreSQL | Storage | Edge Functions (TypeScript)
        |
        v
External                      SMS provider (OTP) | Firebase Cloud Messaging (push) | UPI apps | gateway later
```

- Reads: views (`v_*`) and a few plain tables.
- Writes: `rpc_*` functions, plus a short list of direct writes (own profile, emergency contacts, documents, device tokens, rooms, beds, payment accounts, reminder rules, billing settings).
- Business rules (balances, statuses, who may do what, how a payment is split) live in SQL. Dart only formats and displays.
- Modules point upwards only: reference, people, PG, inventory, stays, billing, comms, platform. Billing never calls comms.
- Every database change is a new numbered migration. Old app versions stay installed, so add first and remove later.

---

## 5. Data model recap

Source of truth: `001_core_schema.sql`. Money columns end in `_paise`.

| Module | Tables | Purpose |
|---|---|---|
| Reference | `roles`, `payment_methods`, `charge_types`, `room_types`, `amenities`, `document_types`, `relationship_types`, `upi_apps`, `states`, `cities`, `addresses` | Lookup rows. Add a row to extend; no app release needed |
| People | `persons`, `files`, `emergency_contacts`, `person_documents` | One row per phone number (can exist before first login). Files point at private Storage. Never store a full ID number; keep type, last 4 characters and a private file |
| PG | `pgs`, `pg_members`, `pg_billing_settings`, `pg_payment_accounts`, `reminder_rules` | A PG has no owner column; people join through `pg_members` with a role (owner, manager, caretaker). Receiving accounts have nicknames. Reminder timing is rows |
| Inventory | `rooms`, `room_amenities`, `beds` | Rooms belong to a PG; beds to a room |
| Stays | `stays`, `stay_bed_assignments`, `stay_rent_terms` | One stay per person per visit; bed history; rent history (a rent change adds a row) |
| Billing | `charges`, `payments`, `payment_upi_details`, `payment_allocations`, `receipts` | The ledger. UPI details are an optional 1:1 table, so other methods can get their own tables later |
| Comms | `device_tokens`, `notifications` | Push tokens and the message queue |
| Platform | `audit_log` | Append-only copy of every change to important tables. Readable only by the server |

**Status words**

- Stay: `reserved`, `active`, `notice`, `vacated` (version 1 functions create `active` and `vacated`; `reserved` and `notice` are for later functions).
- Charge (calculated in `v_charge_balances`): `paid`, `partial`, `due`, `overdue`, `void`.
- Payment: `pending`, `confirmed`, `rejected`, `reversed`. Allowed moves: pending to confirmed or rejected; confirmed to reversed.

**Views the app reads**

- `v_stay_balances`: charged, outstanding, overdue, credit (advance), pending verification, oldest unpaid due date, per stay.
- `v_charge_balances`: per charge, paid, outstanding, status.
- `v_pg_monthly_summary`: expected, collected, pending, overdue per PG per month.
- `v_collections_by_account`: money received per account, per month, per method.

**Who can see what**

| Data | PG staff | The guest themself | Staff of other PGs | Signed out |
|---|---|---|---|---|
| Guest name, phone, photo | Yes, for anyone who has stayed there | Yes | No | No |
| Emergency contacts, ID documents | Only while the guest has an open stay | Yes | No | No |
| Stays, charges, payments, receipts | Yes, always | Yes, including vacated stays | No | No |
| Receiving accounts | Yes | Only active ones, while the stay is open | No | No |
| Audit log | Not through the app | No | No | No |

Known limit: the caretaker role can *read* everything other staff read. Only *writes* are limited by role.

**Deliberate exceptions to strict normalisation** (both guarded): `charges.due_date` is a snapshot because the billing day can change; `stays.pg_id` is also implied by the bed, so a trigger refuses a bed from another PG.

**Money rules in the database**

- Payments split across charges oldest due date first (then oldest created). What is left is advance credit.
- Credit is applied automatically when new charges are created, a payment is reversed, or a charge is voided.
- A UTR can be used for only one pending or confirmed payment.
- Nothing important can be deleted (a trigger refuses it).

---

## 6. Core flows that must work end to end

Where a flow says a person "is notified", that arrives with roadmap step 11. Until then the app shows the new state when it is opened.

**A. Owner onboarding**
1. Opens the app, enters phone number, gets OTP, signs in.
2. Chooses "I'm a PG owner". Fills in PG name, address, city (`rpc_create_pg`). Becomes the owner. Default settings and reminder rules (3 days before, on the day, 2 days after, all push) are created.
3. Adds receiving accounts (UPI ID or bank) with nicknames.
4. Adds rooms and beds (bulk add).
5. Can create more PGs; the PG switcher in the app bar changes everything on screen to that PG.

**B. Adding a new guest**
1. Owner enters phone, name, bed, joining date, monthly rent, deposit, optionally a billing day (`rpc_create_stay`).
2. The guest's deposit appears as a charge. Rent charges come from the daily job.
3. Owner tells the guest to install the app.

**C. Adding a guest who already lives there**
Same as B, plus a billing start date (usually the current month's cycle) and "deposit already paid". Old months are not billed, and the deposit shows as received.

**D. Guest's first login**
1. Guest enters phone number and OTP. A person row is created or the existing one (added by the owner) is linked.
2. `rpc_my_context` returns the guest's stays. If there are none and they do not choose to create a PG, show: "Your number isn't registered. Please ask your PG owner to add you."
3. Home shows next due date, amount paid, amount remaining, advance, and history.

**E. Monthly cycle**
1. Daily job creates the rent charge for each open stay (due on the guest's billing day). Existing advance credit is applied.
2. Reminders go out by the PG's reminder rules.
3. Charges move from `due` to `overdue` automatically after the due date.

**F. Cash payment**
Owner picks the guest, enters amount, method Cash, date (`rpc_record_payment`). It is confirmed at once, split across the oldest charges, a receipt is created, the guest is notified.

**G. UPI payment with optional details**
1. Guest taps Pay. The app opens a UPI link to the PG's default receiving account (pre-filled).
2. Guest taps "I've paid". Optional: which app, UTR, phone used, screenshot, and (only if they paid outside the app) which account.
3. Payment is `pending` (`rpc_report_payment`). The owner sees it under "Needs attention".
4. Owner confirms (optionally correcting the account) or rejects with a reason.
5. On confirmation: split across charges, receipt created, guest notified.

**H. Advance payment**
A payment larger than what is due leaves credit. The next month's rent charge consumes it automatically.

**I. Correction**
Owner reverses a wrong confirmed payment (reason required), or voids a wrong charge (reason required). Then enters the correct one.

**J. Guest leaves**
Owner marks the guest vacated (`rpc_vacate_stay`). Bed is freed, reminders stop, the guest stops being able to report payments. The guest still sees their history; the owner still sees the records but no longer the guest's emergency contacts or documents.

**K. Guest joins another PG**
The new owner adds the same phone number. The same person gets a second stay. The guest's home shows the current stay with a short summary of previous stays.

---

## 7. Screens to build

**Shared:** sign-in (phone, OTP), "not registered" message, profile (limited editing), notifications inbox, language (later), component gallery (hidden).

**Owner**

- Home: month summary line (expected, collected, pending), then "Needs attention" (overdue guests, payments waiting for confirmation) with one-tap Remind and Mark as received.
- PG switcher (app bar title); create PG; PG settings; receiving accounts; reminder rules.
- Rooms and beds; bulk add; vacancy view.
- Guests: list with Paid, Partial, Unpaid filters and search; guest detail (stay terms, charges, payments, receipts, emergency contact, documents); add guest (new and "already staying"); change rent; add a one-off charge; vacate.
- Payments: record payment (cash, UPI, bank, cheque); pending confirmations; reverse; collections by account and month.
- Receipt: the one memorable screen; shareable as image or PDF on WhatsApp.

**Guest**

- Home: next due date and amount, paid, remaining, advance, pending verification.
- Pay: UPI button, then "I've paid" with optional details.
- History: charges and payments of every stay; old stays read-only.
- Receipts.
- Profile: edit name spelling, email, photo, emergency contacts, documents. Phone, rent, advance, join date and payment records are read-only.
- Notice to vacate (after `rpc_give_notice` exists).

---

## 8. How an AI must work on this project

`PROJECT_RULES.md` section 9 is the working agreement. This section is the short version plus the checklists.

### 8.1 Stop and ask before you

- touch more than one feature in one session,
- edit a migration that has already been applied (always add a new one),
- add a package that is not in the allowed list,
- change a row-level security policy, a grant, or the inputs or result of an existing `rpc_*` function,
- put a money or status calculation in Dart,
- delete anything, or add anything that deletes history,
- handle a secret (the `service_role` key never goes in the app, the repo or a chat).

### 8.2 The slice recipe

A slice is one small thing a user can now do, inside one feature.

1. Say which contracts the slice touches (view, function, repository) and list the files you will create or change. Wait for a go-ahead if it spans features.
2. Database first, if needed: new numbered migration, then a SQL test for who may see or do what, then for the money maths.
3. Repository: abstract interface in `domain/`, Supabase implementation in `data/`, a fake for tests.
4. Providers (Riverpod), then the screen in `presentation/`.
5. The screen has four states: loading (skeleton), empty (invites one action), error (plain words and a retry), and data.
6. Text goes into the localisation files. Colours, spacing and type come from `core/theme`.
7. Tests, `flutter analyze`, a run on a real Android phone, a note in `docs/DECISIONS.md` if a decision was made, a small commit saying what the owner or guest can now do.

### 8.3 Session opener (copy this)

```
Read PROJECT_RULES.md and PROJECT_STATUS_AND_ROADMAP.md, then the migrations in supabase/migrations.
Slice for this session: <one sentence, e.g. "owner adds a room with beds">.
List the files you will create or change and which contract each uses. Wait for my OK.
Then: migration if needed, SQL test, repository, screen. Run flutter analyze and the tests.
```

### 8.4 Checklist for every new table

- Row-level security enabled, at least one policy, explicit grants (nothing is granted by default).
- If it holds important history: add the `updated_at` and audit triggers, and the no-delete trigger.
- Foreign keys indexed. Money in `_paise` as `bigint`. Times as `timestamptz`.
- No `pg_` prefix that matches a PostgreSQL system view. Table names plural `snake_case`.
- It points at existing tables (`persons`, `pgs`, `stays`); it does not change them.

### 8.5 Checklist for every new `rpc_*` function

- `security definer` with `set search_path = public`.
- Checks who the caller is before doing anything (`current_person_id()`, `is_pg_staff(...)`).
- Validates input and raises plain-English messages the app can show as they are.
- Grants `execute` explicitly to `authenticated` (or leaves it scheduler-only).
- Tested for an allowed caller, a forbidden caller, and a bad input.
- Changing the inputs of an existing function is not allowed: add a new function, or a new optional parameter with a default.

### 8.6 Backward compatibility

Old versions of the app stay on people's phones. Add columns, tables and functions first. Retire the old ones only after no released app uses them. Consider a minimum supported app version check before the first public release.

### 8.7 Definition of done for a slice

Analyze is clean; tests pass; the screen was seen on a real phone; four states exist; no hard-coded colours or text; no rule duplicated from SQL into Dart; contract docs and `docs/DECISIONS.md` updated if something changed.

---

## 9. Roadmap by phase

Effort labels are rough, for part-time work with AI help.

### Progress

| Step | Name | Status |
|---|---|---|
| 0 | Paper test with the owner | Not started |
| 1 | Accounts and tools | Not started |
| 2 | Database live | **Partly done.** Migrations `001` to `004` written and tested on plain PostgreSQL. To do: apply on real Supabase and re-run the tests |
| 3 | Design foundation | **Specified.** The full UI pack is written (tokens, components, every screen, assets, placeholders). To do: build it (UI steps U0 to U4) |
| 4 | Sign-in and role detection | Not started |
| 5 | PG setup | Not started |
| 6 | Rooms and beds | Not started |
| 7 | Guests | Not started |
| 8 | Charges and owner home | Not started |
| 9 | Payments and receipts | Not started |
| 10 | Guest app | Not started |
| 11 | Reminders and notifications | Not started |
| 12 | Hardening | Not started |
| 13 | Pilot | Not started |
| 14 | Release | Not started |
| 15 | After launch | Not started |

The UI pack maps the screen work onto these steps: U0 to U4 are step 3, U5 is step 4, U6 is step 5, U7 is step 6, U8 is step 7, U9 and U10 are steps 8 and 9, U11 is step 10, U12 is step 11, U13 is step 12 (see `UI_GUIDE.md` section 9).

Update this table when a step is finished, and add a line to the change log at the end.

### Phase A: Foundations (about a week)

**Step 0. Paper test (one hour).** Walk through a real month with the owner: new guest, cash, UPI claim, partial payment, someone leaving. Write every screen and field on paper. Collect data for 10 real guests (name, phone, room, bed, joining date, rent, deposit, what has been paid).
*Done when:* one page of screens and a sheet of real data exist. Also compare with an existing PG app (for example RentOk) so nothing obvious is missed.

**Step 1. Accounts and tools.**
- GitHub repo, Supabase project in the Mumbai region (a separate one for testing and one for real use), Firebase project for push notifications, Flutter, Android Studio, a real Android phone.
- Start the SMS sender registration (DLT) now; it takes time.
- Repo layout from `PROJECT_RULES.md` section 4. Put the two migrations in `supabase/migrations`.
*Done when:* an empty Flutter app runs on the phone and the repo has the agreed folders.

**Step 2. Database live.**
- Apply `001` and `002` with the Supabase CLI. Never edit tables by hand in the dashboard.
- Turn on phone login. Use a fixed test number and OTP if your Supabase setup offers one (check the current Supabase docs).
- Confirm the trigger that links a login to a person works with real Supabase sign-in.
- Adapt `tests_10_scenario.sql` to the Supabase test setup. The scenarios matter, not the exact script.
- Seed lookups for the cities you need. Schedule the daily charge job (Supabase scheduler or an Edge Function using the service role).
*Done when:* the privacy tests pass on the real project (owner A cannot see owner B's guests; a guest cannot see other guests; signed out sees nothing), and a manual call of the charge job twice creates charges once.

**Step 3. Design foundation.**
- Collect screenshots of the reference apps (Google Pay, PhonePe, Khatabook, OkCredit, Splitwise, MyGate, Zerodha Kite). Compare the same flows. Write five observations per app. Borrow patterns, not colours or layouts one to one.
- Sketch six screens on paper: owner home, guest list, guest detail, record payment, guest home, receipt.
- Follow the UI pack steps U0 to U4 (`UI_GUIDE.md` section 9): setup and placeholder assets, tokens and formatting, all components, and the hidden component gallery with a type specimen. The sketching and reference work above feeds the checkpoint at the end of U4.
*Done when:* the gallery looks right on a real phone, the ₹ sign renders, figures line up, and `1,25,000` and `12 Nov 2026` formats are correct.

### Phase B: Owner core (about two weeks)

**Step 4. Sign-in and role detection.**
- Phone entry, OTP, session handling, `rpc_my_context` after login.
- Paths: owner (creates a PG), guest (has stays), both (switch between views), none (show "Your number isn't registered. Please ask your PG owner to add you.").
- Decide in this step: check the number before sending an OTP (saves SMS cost but reveals whether a number is registered) or always send.
*Done when:* all four paths work with test numbers.

**Step 5. PG setup.** Create PG (`rpc_create_pg`), PG switcher in the app bar (selected PG remembered; every query uses the selected PG), PG settings, receiving accounts with nicknames and a default, reminder rules.
*Done when:* an owner can have two PGs and switching shows only that PG's data.

**Step 6. Rooms and beds.** Add rooms and beds, bulk add ("10 rooms, 2 beds each"), room types and amenities from lookups. Bulk adding uses `rpc_add_rooms`, and the bed list reads `v_bed_occupancy` (both already exist, migrations 003 and 004).
*Done when:* the real PG's rooms and beds are entered in minutes.

**Step 7. Guests.**
- Add guest (`rpc_create_stay`), with the "already staying" option (billing start date and deposit already paid).
- Guest list with Paid, Partial, Unpaid filters and search, from `v_stay_balances`.
- Guest detail: stay terms, charges, payments, emergency contact and documents.
- Change rent (`rpc_set_stay_rent`). Vacate (`rpc_vacate_stay`).
- Correcting a guest's name before that guest has signed in uses `rpc_correct_guest_name` (already exists, migration 004).
*Done when:* all 10 real guests are entered with correct balances.

### Phase C: Money (about two weeks)

**Step 8. Charges and owner home.** Daily job (current and next month). Owner home as a work queue from the views: a month summary line, then "Needs attention". One-off charges (`rpc_add_charge`) and voiding (`rpc_void_charge`).
*Done when:* overdue and due statuses match what the owner expects for the real guests.

**Step 9. Payments and receipts.**
- Record payment (`rpc_record_payment`) for cash, UPI, bank transfer, cheque. Partial and advance. Reverse (`rpc_reverse_payment`).
- Receipt screen generated on demand from the receipt row, shareable as image or PDF to WhatsApp.
- Collections by account and month (`v_collections_by_account`).
- SQL money tests (section 10).
*Done when:* the owner can record a whole day's cash in the app and the totals agree with his notebook.

### Phase D: Guest side and reminders (about two weeks)

**Step 10. Guest app.**
- Home: next due date and amount, paid, remaining, advance, pending verification.
- Pay by UPI (link to the PG's default account). "I've paid" with optional app, UTR, phone, screenshot, and account (pre-filled when paid through the app) via `rpc_report_payment`.
- Owner side: pending list with confirm (`rpc_confirm_payment`, can correct the account) and reject (`rpc_reject_payment`, reason required).
- History across stays, receipts, limited profile editing, emergency contacts, documents (private Storage buckets and their policies go in a migration).
- New migration: `rpc_give_notice` so a guest can give notice to vacate.
*Done when:* a test guest can report a payment and the owner can confirm it, and the balances update on both phones.

**Step 11. Reminders and notifications.**
- Edge Function (service role) reads `reminder_rules`, finds charges that match, and creates `notifications` (one per rule per charge; the table enforces this), then sends push through Firebase Cloud Messaging.
- It must only consider guests with an **open** stay, so a vacated guest receives nothing.
- Notifications for "payment reported" (to the owner) and "payment confirmed or rejected" (to the guest). Billing must not call comms; comms reacts to changes (a database webhook or realtime listener).
- New migration: `rpc_send_reminder_now(stay_id)` for the owner's one-tap Remind.
- Notification inbox in the app.
*Done when:* a test guest gets the three default reminders at the right times, and a vacated guest gets none.

**Step 12. Hardening.**
- Repeat the privacy tests on the real project. Review every policy and grant once more.
- Crash reporting, slow and no-network behaviour (cash entry must still work and sync later), OTP rate limits and bot protection, backups on, and a restore test.
- Performance check with about 200 guests and 12 months of charges. If row-level security helpers are slow, consider adding `pg_id` to child tables with a composite foreign key (discuss first).
*Done when:* nothing slow, nothing leaking, and a failed network never loses a recorded payment.

### Phase E: Pilot and launch

**Step 13. Pilot (2 to 4 weeks).** The real PG, real guests (moved in with `billing_starts_on` and `deposit_already_paid`). Weekly fix list. Ask a designer to review the 8 main screens for a few hours.
*Done when:* the owner has stopped using the notebook for a full month.

**Step 14. Release.** Section 11.

**Step 15. After launch.** Section 12.

---

## 10. Testing strategy

**SQL tests (run after every migration)**

- Visibility matrix: owner A, owner B, guest, guest in two PGs, caretaker, signed out. Each reads and writes only what section 5 allows.
- Money cases: exact payment, partial payment, overpayment leaving credit, advance for several months, credit consumed by the next charge, reversal reopening charges, voiding a paid charge, rejected payment, duplicate UTR (any letter case), two staff confirming the same payment at the same time, rent change mid-stay, existing guest onboarding, guest leaves with dues, guest joins on the billing day.
- Guards: no deletes of history, no edits to confirmed payments, no over-allocation, no bed or account from another PG.

**Dart tests**

- Money and date formatting (`₹1,25,000`, `12 Nov 2026`).
- Each repository against a fake.
- Providers for loading, empty, error and data states.

**Real-device checklist for every screen**

Small screen, large system font, slow network, no network, back button behaviour, rotation off, a guest with a long name, a PG with 100 guests, light theme contrast in sunlight.

---

## 11. Release checklist

Check the current Google Play and legal requirements at the time; they change.

- App signing, versioning, and a release build tested on a real phone.
- Closed testing before production. New developer accounts may need a minimum number of testers for a minimum number of days.
- Privacy policy at a public link. Data safety form. A way for people to ask for their data to be deleted.
- Consent wording for personal data under the DPDP Act 2023. Get a legal review for the wording and for how long you keep former guests' records. Never store a full Aadhaar number.
- SMS sender registered and tested with real numbers on the major networks.
- Crash reporting on. Backups on and a restore tested.
- OTP rate limits and bot protection on.
- Support contact in the app and the store listing.
- Store listing: name that does not clash with another app, screenshots of the real screens, a short description in plain words.
- Staged rollout, with the owner and a few guests first.

---

## 12. After launch

Order of work. Each item is new tables and screens that point at the existing ones; the core tables do not change.

1. **Payment gateway** (for example Razorpay or Cashfree). Auto-confirm payments from the gateway's webhook. A new table such as `payment_gateway_details` hangs off `payments` the same way `payment_upi_details` does. Do not move money through your own account without checking the rules that apply.
2. **Rent Reliability Score** (not called a CIBIL score).
   - **Objective data only:** on-time payment percentage, average delay in days, number of stays, whether dues were left unpaid. No free-text remarks from owners.
   - **Consent:** the guest chooses to share their rental profile with a new PG when joining. Sharing is recorded and can be withdrawn.
   - **Dispute:** the guest can flag an entry they believe is wrong.
   - **Show the facts first** ("paid on time 10 of 12 months, no pending dues"). A single number only makes sense after enough data across many PGs.
   - Sketch only, to design before building: a `consents` table (person, purpose, who it is shared with, granted, revoked) and a `reliability_snapshots` table (person, computed at, algorithm version, months observed, on-time percentage, average delay, stays, unresolved dues).
3. Complaints and maintenance requests, announcements.
4. Deposit settlement at leaving (deductions and refund), notice period handling, vacancy tracking.
5. Late fees (the settings columns exist; the calculation does not).
6. WhatsApp reminders (needs the WhatsApp Business API; costs money).
7. Electricity and other shared charges split per room.
8. Reports and Excel export, then a web dashboard (Flutter web from the same code).
9. Staff roles with finer permissions (the caretaker currently reads what staff read).
10. Hindi and Kannada, then other languages, by adding text files.
11. Guest "this entry looks wrong" dispute flag; guest accepts an invitation before a stay becomes active.
12. Offline queue for recording payments.

---

## 13. Open decisions and risks

| Item | Options | Decide by |
|---|---|---|
| OTP SMS provider and DLT registration | Supabase phone auth with a provider that works in India, or compare Firebase Auth. Check the number before sending an OTP or always send | Step 2 and Step 4 |
| An owner can learn the name of any phone number by adding it | Guest accepts an invitation before the stay becomes active | Before public release |
| Receipt files | Generate on demand in the app (version 1), or an Edge Function that stores a file | Step 9 |
| Row-level security speed at scale | Keep helper functions, or add `pg_id` to child tables with a composite foreign key | Step 12 |
| How far offline recording goes | Simple retry queue, or full offline-first | Step 12 |
| How the app earns money | Not discussed yet (free for the pilot; for example a per-PG subscription later) | Before launch |
| Data retention for former guests | How long, and what is anonymised | Before launch (legal review) |
| Existing apps such as RentOk | Check what they already offer before investing in extras | Step 0 |
| Backups and recovery | Backup plan and a tested restore | Step 12 |

---

## 14. Glossary

- **PG:** paying-guest accommodation. A **guest** (or tenant) lives in a bed in a room.
- **Person:** one human, identified by phone number. **Stay:** one person's visit to one PG, with its own terms.
- **Charge:** something the guest owes (rent, deposit, electricity). **Payment:** money received. **Allocation:** how much of a payment paid which charge.
- **Advance or credit:** confirmed money not yet used against any charge.
- **Deposit:** a refundable security amount, held as a charge that the guest pays.
- **UTR:** the unique reference number of a bank or UPI transaction. **UPI ID (VPA):** the address a UPI payment goes to.
- **Paise:** one hundredth of a rupee. All money is stored as whole paise.
- **Migration:** a numbered SQL file that changes the database. **View:** a saved read-only query. **`rpc_*` function:** a database function the app calls to change data.
- **Row-level security (RLS):** database rules that decide which rows a person can read or write.
- **Slice:** one small user-visible capability built in one AI session.
- **Contract:** the agreed shape (views, functions, repositories, design tokens) that parts of the system use to talk to each other.

---

## Change log

| Date | Change |
|---|---|
| 12 Nov 2026 | Schema (`001`), functions (`002`) and tests written and verified on PostgreSQL 16. `PROJECT_RULES.md` and this file created. No app code yet |
| 12 Nov 2026 | UI pack written: guide, design system, three screens files, assets guide. Migrations `003` (screen views) and `004` (rooms, name correction) added and tested; `rpc_report_payment` got an optional screenshot; `dev_reset.sql` and `placeholder_assets.zip` added |
