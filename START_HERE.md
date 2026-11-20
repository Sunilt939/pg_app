# START HERE

This folder is your whole project. You do **not** need to read every file. This page tells you:

1. what each file is,
2. what to do first,
3. exactly what to say to the AI.

---

## 1. The idea in one minute

- You are building a mobile app for PG owners and their guests (rent, payments, receipts, reminders).
- **Everything is already planned and written down** in the `docs/` folder. The database is already written in the `supabase/` folder.
- The AI will build the app inside the `app/` folder, **one page at a time**.
- A page is finished only when it works 100% and **you** have tested it on your phone and said "approved". Only then the next page starts. Never two pages together.

---

## 2. The folder map (what is where)

```
pg_app/
├── START_HERE.md          You read this (the page you are reading)
├── AI_INSTRUCTIONS.md     The strict rules for the AI. The AI reads this first
├── PROGRESS.md            The checklist of pages. Shows what is done and what is next
├── AGENTS.md, CLAUDE.md, GEMINI.md, .github/copilot-instructions.md
│                          Tiny helper files. Ignore them
├── .gitignore             Keeps your private keys out of Git. Ignore
│
├── docs/                  The planning documents (the AI reads the ones it needs)
├── supabase/              The database
│   ├── migrations/        5 SQL files you run once, in order
│   ├── _local_tests_FAKE_DATA/   My database checks. Contain FAKE data. Never run. Ignore
│   └── dev/               One dangerous script for wiping test data
└── app/                   The mobile app (the AI builds it here)
    ├── assets/            Placeholder logo, icons, sign-in picture, fonts
    ├── env/               Where your Supabase address and key go
    └── tool/              An automatic checker the AI must run
```

### What each file is, in simple words

**In the main folder**

| File | What it is | Who uses it |
|---|---|---|
| `START_HERE.md` | This guide | You |
| `AI_INSTRUCTIONS.md` | The strict rulebook for the AI (do one page at a time, no fake data, and so on) | The AI |
| `PROGRESS.md` | The list of all pages in order, with tick boxes and how to test each one | You and the AI |

**In `docs/`** (you can skip reading these; the AI reads what it needs)

| File | What it is |
|---|---|
| `PROJECT_RULES.md` | The basic rules of the whole project: tools used, security, money rules |
| `PROJECT_STATUS_AND_ROADMAP.md` | The big plan, every decision and why, what is finished. Mostly for you and me |
| `UI_GUIDE.md` | How the screens are built: rules for the AI, build steps, final checklist |
| `UI_DESIGN_SYSTEM.md` | How everything looks: colours, text, buttons, boxes, animation |
| `UI_SCREENS_SHARED.md` | Exact design of sign-in, code entry, receipt, profile, notifications |
| `UI_SCREENS_OWNER.md` | Exact design of every owner screen |
| `UI_SCREENS_GUEST.md` | Exact design of every guest screen |
| `ASSETS_GUIDE.md` | About pictures, logo and icons, and how to replace them later |
| `DECISIONS.md` | An empty notebook where the AI writes small decisions it had to make |

**In `supabase/migrations/`** (run once, in this order, in Step 3 below)

| File | What it does |
|---|---|
| `001_core_schema.sql` | Creates all the tables and the security rules |
| `002_core_functions.sql` | Creates the actions: add guest, record payment, and so on |
| `003_ui_read_views.sql` | Creates ready-made lists that the screens read |
| `004_ui_write_functions.sql` | Adds many rooms at once, and fixes a guest's name |
| `005_room_layout.sql` | Adds a whole layout of floors and rooms in one step (used by the floor setup page) |

**Other files**

| File | What it is |
|---|---|
| `supabase/dev/dev_reset.sql` | **Danger.** Deletes all test data and logins. Only for your DEV project. It refuses to run unless you confirm |
| `supabase/_local_tests_FAKE_DATA/` | Database checks I ran on my own computer. They contain **fake** people and numbers, so they are locked: they refuse to run unless started in a special way. You never need them. Ignore this folder |
| `app/assets/` | Placeholder logo, app icons, sign-in picture and fonts. You can replace the pictures later (keep the same file names) |
| `app/env/dev.json.example` | A template. You copy it and fill in two values (Step 3) |
| `app/tool/check_ui_rules.sh` | A checker that finds fake data and wrong colours. The AI runs it before saying "done" |

### Which files contain fake or sample data?

| Files | What they put in your database | Is it fake data? |
|---|---|---|
| `001_core_schema.sql` | **Reference lists only**: roles, payment methods, charge types, room types, amenities, ID document types, relationship types, UPI apps, states and a starter list of cities. The app needs these to work | **No.** It is required data. You can add more cities later |
| `002`, `003`, `004`, `005` (the other SQL files) | Nothing. They only create actions and views | No data |
| `dev_reset.sql` | Nothing. It only deletes, and only with your confirmation | No data |
| `_local_tests_FAKE_DATA/` | FAKE people ("Arjun Kumar"), fake phone numbers and fake PGs, but **only** if someone deliberately runs them | **Yes, but locked.** They refuse to run unless started with a special setting, they cannot run in the Supabase SQL editor, and they are never part of the app |
| The app code (`app/lib`) | Nothing. The AI is forbidden from adding sample data, and a checker script looks for it before every page is approved | No data |

So your Supabase project starts with only the reference lists, and everything else in it will be the real data you enter through the app.

---

## 3. One-time setup (about 1 to 2 hours)

**Step 1. Install the tools on your computer**
- Flutter and Android Studio (with the Android SDK), and Git.
- Your AI editor (the one you already use).
- On your Android phone: turn on *Developer options* and *USB debugging*, and connect it to the computer.
- In a terminal, run `flutter doctor` and fix anything it marks in red.

**Step 2. Open this folder as your project**
Unzip it, then open the whole `pg_app` folder in your editor.

**Step 3. Create the database (Supabase)**
1. Create a free Supabase account and a new project. Name it something like `pgapp-dev` (the `dev` is important). Choose the Mumbai region. Save the database password.
2. In the project settings, find the **API** page. Copy the **Project URL** and the **anon (public) key**. (Menu names change sometimes. Never copy the `service_role` key anywhere.)
3. In `app/env/`, copy `dev.json.example` to a new file called `dev.json`. Paste the two values into it.
4. In Supabase, open **SQL Editor**, then **New query**. Open `supabase/migrations/001_core_schema.sql`, copy everything, paste it, and press **Run**. It should say success.
5. Do the same for `002`, then `003`, then `004`, then `005`. **Always in this order.** (Already ran 001 to 004 before 005 existed? Run only `005`. It only adds one action, so your data is safe.)
6. If any run shows a red error: copy the whole message and send it to me. Do not let the AI "fix" the SQL files.
7. In Supabase, go to **Authentication**, then **Providers**, then **Phone**, and switch it on. For testing, add a test phone number with a fixed code (the page usually has a "test phone numbers" setting; look in the Supabase help if you cannot find it). Real SMS needs an SMS provider; we do that later.

**Step 4. Start the AI**
Go to Section 4. That is all.

---

## 4. What to say to the AI (three messages)

**Message 1: start of every session (copy and paste)**

```
Read AI_INSTRUCTIONS.md first and follow it strictly. Open PROGRESS.md, tell me which page is next, and wait for my OK before you write any code.
```

The AI tells you the next page. Say "OK" and it builds that page.

**Message 2: when the AI says the page is finished**
Test the page on your phone using the **Page test** at the top of `PROGRESS.md`. If everything is right, say:

```
Page <ID> approved. Tick it in PROGRESS.md and commit.
```

(Replace `<ID>` with the page ID, for example `A1`.)

**Message 3: if something is wrong**

```
Page <ID> has a problem: <describe what you see>. Fix only this page. Do not start the next page.
```

Some AI tools read the helper files by themselves. If your AI seems to ignore the rules, just paste Message 1 again.

---

## 5. The golden rule

> **One page at a time. 100% finished and tested before the next page.**

A page is finished only when **all** of these are true:
1. It is built exactly like the written design (nothing extra, nothing missing).
2. The AI's automatic checks pass.
3. **You** tested it on your real phone.
4. You said "approved".

If the AI tries to jump ahead, reply: `Stop. Follow AI_INSTRUCTIONS.md. Finish page <ID> first.`

---

## 6. When to ask me (the big model) instead of the small AI

- Any red error when running the SQL files.
- Anything about logins (OTP), security, who can see what, or photo storage.
- After a page is built and you are not sure it matches the design: send me a screenshot and the page ID.
- If the AI says the design is unclear, or wants to change a document.
- Before you change the app name or logo.

---

## 7. Saving your free AI limit

- One page per chat. Start a new chat for each page.
- Do not paste the documents into the chat. The AI reads the files itself.
- Use the lighter model for building. Keep the stronger one for hard problems.
- If the AI makes the same mistake twice, stop and ask me.

---

## 8. Quick fixes

| What happens | What to say |
|---|---|
| The AI starts the next page by itself | `Stop. Follow AI_INSTRUCTIONS.md. Finish page <ID> first.` |
| The AI adds sample names, numbers or pictures | `Remove all dummy data. Follow the no dummy data rule.` |
| The AI says "done" but did not run the checks | `Run flutter analyze, the tests and the check script, and show me the results.` |
| The app will not run | `Fix only this error: <paste the error>.` If it fails twice, send me the error |
| You want to wipe your test data | Run `supabase/dev/dev_reset.sql` in the **dev** project only, following the instructions at the top of that file |
