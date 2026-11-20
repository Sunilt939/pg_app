# PROGRESS: one page at a time

## How this file works (read first)

- The AI may work **only on the first unchecked item**, from the top. Nothing else. No jumping ahead.
- An item is ticked **only** after: built exactly as the spec says, the AI's checks pass, you tested it on your phone, and you said "approved".
- If a page links to something that is not approved yet, that button stays **hidden** until its page is approved (no dead buttons, no fake data).
- Test with **real data only**: create your own PG, rooms and guests through the app. Use a second phone number (or a Supabase test number) as the guest.

---

## The Page test (do this for every page before you say "approved")

1. **Normal use:** go through the page with real data on your real phone. Everything works and nothing looks wrong.
2. **Empty:** look at the page when there is nothing yet (for example a new PG). It shows the correct empty message.
3. **Loading:** pull down to refresh. A grey placeholder shape appears (not a lonely spinner).
4. **Error:** switch on airplane mode and reopen or refresh. A clear message and a "Try again" button appear, and they work when you switch the internet back on.
5. **Typing:** wrong or missing input shows the exact error message under the field.
6. **Big text:** in the phone settings, set the font size to large. Nothing is cut off or overlapping.
7. **Looks:** compare with the wireframe and wording in the spec. Same order, same words, same colours.
8. **The AI's three checks** passed, and the AI showed you the results: `flutter analyze`, the tests, and `./tool/check_ui_rules.sh`.
9. **Not sure?** Send me a screenshot and the page ID before you approve.

---

## Checklist

### Part 1. Foundation

- [x] **F1. Project and settings** (AI). Create the Flutter project inside `app/`, add the allowed packages, fonts and assets entries, `AppConfig`, `AppFlags`, `AppAssets`, the Android settings, portrait lock and the text-file setup. Spec: `docs/UI_GUIDE.md` sections 4, 5, 6 (step U0). *Done when:* the app runs on your phone and shows an empty page, `flutter analyze` is clean, and the check script prints clean.
- [x] **F2. Database ready** (YOU, with me if needed). Follow `START_HERE.md` Step 3: the four SQL files run without red errors in your DEV Supabase project, `app/env/dev.json` is filled in, and phone sign-in has a test number. *Done when:* you can see the tables in Supabase. (Advanced and optional: ask me to help run the privacy checks later.)
- [x] **F3. Colours, text styles, icons, number and date formats** (AI). Spec: `docs/UI_DESIGN_SYSTEM.md` sections 2, 3, 9 (step U1). *Done when:* the unit tests for money, dates and phone formats pass (the examples are in `docs/UI_GUIDE.md`, step U1).
- [x] **F4. Component gallery and components, set 1** (AI). A hidden screen that shows each component in every state: Money, StatusChip, AppButton, SectionHeader, LedgerSheet, LedgerRow, RoomTile, KeyValueRow, EmptyState, ErrorState, SkeletonBlock, SkeletonList, ProgressBarThin, ProfileAvatar. Spec: `docs/UI_DESIGN_SYSTEM.md` sections 5 and 11 (step U2). *You test:* open the gallery on your phone and compare each component with the written design.
- [x] **F5. Components, set 2** (AI). Add to the gallery: AppTextField, PhoneField, MoneyField, SelectField, OptionSheet, DateField, OtpField, OptionRow, UnderlineTabs, SwitchRow, AppBottomSheet, ConfirmSheet, AppSnack, AppTopBar, PgSwitcherTitle, AppBottomNav, TickBadge, Stamp, ReceiptPaper. Spec: `docs/UI_DESIGN_SYSTEM.md` sections 5 and 7 (step U3).
- [x] **F6. Gallery review** (YOU and the big model). Send me screenshots of the gallery. I list every difference from the design and the AI fixes them. *Done when:* I say the gallery matches, the ₹ sign shows and the numbers line up.

### Part 2. Navigation and sign-in

- [x] **N1. App shell** (AI). All routes from the navigation map, the owner shell (4 tabs: Home, Guests, Payments, More) and the guest shell (3 tabs: Home, History, Profile), and the check at startup. Each tab shows only its title for now (no content yet). The bell icon and every link to an unbuilt page stay hidden. Spec: `docs/UI_GUIDE.md` section 7; `docs/UI_SCREENS_OWNER.md` "Owner shell and roles"; `docs/UI_SCREENS_GUEST.md` "Guest shell".
- [x] **A1. Sign-in** (AI). Spec: `docs/UI_SCREENS_SHARED.md` A1. *Test with:* a Supabase test number. Check: an invalid number shows the message, the code is sent, the keyboard never hides the button.
- [x] **A2. Enter code** (AI). Spec: `docs/UI_SCREENS_SHARED.md` A2. *Check:* a wrong code shakes and shows the message, the right code signs you in, the resend countdown works.
- [x] **A3. How will you use the app** (AI). Spec: `docs/UI_SCREENS_SHARED.md` A3. *Test with:* a brand-new number. You land here. Both rows and Sign out work.
- [x] **A4. Ask your owner to add you** (AI). Spec: `docs/UI_SCREENS_SHARED.md` A4. *Check:* your number is shown, Copy works, "Check again" says you are not added yet.

### Part 3. Owner setup

- [x] **O1. Add your PG** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O1. *Test:* create your real PG. Errors show under the fields. You land on the owner Home tab.
- [x] **O3. PG switcher** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O3. *Test:* create a second PG with "Add another PG" and switch between them.
- [x] **O13. More tab** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O13. Show only the rows whose pages are approved (at first: Add another PG, Sign out, and Switch to guest view if you are also a guest). Each later page adds its own row when approved.
- [x] **S2a. Profile, basic parts** (AI). Spec: `docs/UI_SCREENS_SHARED.md` S2, only the header, "Your details" and sign-out parts. No photo, no documents. Then add the Profile row to More.
- [x] **O12. Set up floors and rooms** (AI). First build the new `BedsStepper` component (design system section 5, icon `minus` in section 3) and add it to the gallery. Then the page. Spec: `docs/UI_SCREENS_OWNER.md` O12. *Needs:* `005_room_layout.sql` already run in your Supabase project. *Test:* set up your real first floor with different beds in some rooms, copy it to all floors, change one room in the review step, save. A clash message appears if a number exists. Then add the More row the spec describes.
- [ ] **O12b. Add a few rooms** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O12b (the old Add rooms form). *Test:* add 2 rooms; a clash message appears if a number exists. It is reached from the plus on O11, so test it after O11 is built.
- [ ] **O11. Rooms and beds** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O11. *Check:* the list and the room pages show your real beds.
- [ ] **O14. Receiving accounts** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O14. *Test:* add your real UPI ID and a bank account, and set a default.

### Part 4. Guests

- [ ] **O5. Add guest** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O5. *Test:* add a real guest, and one with "Already staying here" switched on. The invite message opens.
- [ ] **O4. Guests list** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O4. *Check:* search, the five tabs and their counts, and the empty states.
- [ ] **O6. Guest detail** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O6. Leave out the "Waiting for you" section for now (it comes in O6b). *Check:* balance numbers match what you expect.
- [ ] **O17a. Change rent** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O17.
- [ ] **O17b. Add a charge** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O17.
- [ ] **O17c. Cancel a charge** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O17.
- [ ] **O17d. Correct a guest's name** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O17. *Test:* works for a guest who has not signed in; refused after they have.
- [ ] **O17e. Mark as vacated** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O17. *Test with a test guest.* The bed becomes free and the guest moves to the Past tab.

### Part 5. The owner records money

- [ ] **O7 + S1. Record payment and Receipt** (AI). These two are built and tested **together as one unit** (the only pair allowed). Spec: `docs/UI_SCREENS_OWNER.md` O7 and `docs/UI_SCREENS_SHARED.md` S1. *Test:* record a real cash payment, see the tick and the receipt, share the receipt image to WhatsApp, and check that the guest's balance changed.

### Part 6. The guest app

*Test with a second phone number signed in as a guest of your PG.*

- [ ] **G1. Guest home** (AI). Spec: `docs/UI_SCREENS_GUEST.md` G1. *Check:* due, overdue and paid-up states.
- [ ] **G2. Pay rent** (AI). Spec: `docs/UI_SCREENS_GUEST.md` G2. *Test:* your UPI app opens with the right account and amount.
- [ ] **G3. "Tell your owner you've paid" sheet** (AI). Both versions. Spec: `docs/UI_SCREENS_GUEST.md` G3. The screenshot control stays hidden (uploads are off). *Test:* report a payment; the home page shows the "waiting" message.
- [ ] **G4. History** (AI). Spec: `docs/UI_SCREENS_GUEST.md` G4.
- [ ] **G5. Past stay** (AI). Spec: `docs/UI_SCREENS_GUEST.md` G5. *Test:* needs a guest whose stay has ended.
- [ ] **S2b. Profile, guest parts** (AI). Spec: `docs/UI_SCREENS_SHARED.md` S2: emergency contacts, "Your stay" and the view switch. Photo and ID document controls stay hidden.

### Part 7. The owner confirms and sees everything

- [ ] **O8. Payment detail** (AI). With the Mark as received, Reject and Reverse sheets. Spec: `docs/UI_SCREENS_OWNER.md` O8. *Test:* confirm the payment your guest reported in G3. It turns into a receipt.
- [ ] **O6b. "Waiting for you" on guest detail** (AI). Add the section that was left out of O6. Spec: `docs/UI_SCREENS_OWNER.md` O6.
- [ ] **O9. Payments tab** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O9.
- [ ] **O10. Money received** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O10.
- [ ] **O2. Owner home** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O2. *Check:* the summary, the "Needs attention" list with real overdue and pending items, and the setup checklist on a brand-new PG.

### Part 8. Extras

- [ ] **S3. Notifications** (AI). Spec: `docs/UI_SCREENS_SHARED.md` S3. After approval, show the bell icon in the top bars.
- [ ] **O15. Reminders** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O15. Keep the "reminders will start sending soon" notice, because sending is not built yet.
- [ ] **O16. PG details** (AI). Spec: `docs/UI_SCREENS_OWNER.md` O16.

### Part 9. Final check

- [ ] **Z1. Full review** (YOU and the big model). Run the full review checklist (`docs/UI_GUIDE.md` section 10) on every page, including large text, a small screen and no internet. Run the database privacy checks with my help, and plan the release.
