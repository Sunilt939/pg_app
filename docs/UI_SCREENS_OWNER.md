# UI screens: owner

Last updated: 12 Nov 2026

Screens in this file: **O1** Add your PG, **O2** Owner home, **O3** PG switcher, **O4** Guests, **O5** Add guest, **O6** Guest detail, **O7** Record payment, **O8** Payment detail, **O9** Payments, **O10** Money received, **O11** Rooms and beds, **O12** Add rooms, **O13** More, **O14** Receiving accounts, **O15** Reminders, **O16** PG details, **O17** Guest actions (sheets).

Load `UI_DESIGN_SYSTEM.md` with this file. The receipt (S1), profile (S2) and notifications (S3) are in `UI_SCREENS_SHARED.md`.

**Reading the wireframes.** Names, numbers and amounts inside wireframes only show where things go. **Never copy them into code.** Every name and figure on a real screen comes from the database. Text is given as ARB keys with their English text.

**Spec gaps.** If a detail is missing, choose the simplest option that follows the design system and add one line to `docs/DECISIONS.md` under "UI gaps". Never invent colours, sizes or wording.

---

## Owner shell and roles

**Shell:** four tabs, `AppBottomNav`: Home (`/owner/home`), Guests (`/owner/guests`), Payments (`/owner/payments`), More (`/owner/more`). Tab pages use `PgSwitcherTitle` in the top bar. The selected PG id is stored locally (`flutter_secure_storage`) and every query in the shell filters by it. The Payments tab shows a badge with `pending_payment_count` from `v_pg_overview`.

**Roles** come from `rpc_my_context` (`pgs[].role` for the selected PG). **Hide** (never just disable) what a role cannot do:

| Action | Owner | Manager | Caretaker |
|---|---|---|---|
| View guests, payments, rooms | yes | yes | yes |
| Record, confirm and reject payments | yes | yes | yes |
| Reverse a payment | yes | yes | no |
| Add guest, change rent, add or cancel a charge, mark vacated, correct a name | yes | yes | no |
| Add rooms | yes | yes | no |
| Receiving accounts, reminders, PG details | yes | no | no |
| Add another PG | yes | yes | yes |

**Permission errors** from the database (SQLSTATE `42501`) show the snackbar `errorNotAllowed`.

**Reminders and other backend features that do not exist yet** are behind `AppFlags` (`remindersEnabled`). When a flag is off, hide the control completely.

---

## O1. Add your PG

**Route** `/owner/pg/new`. **Does** `rpc_create_pg(p_name, p_line1, p_city_id, p_pincode, p_area, p_contact_phone, p_gender_policy)`. **Reads** `cities` with `states(name)`.

```
┌──────────────────────────────────────┐
│ ←  Add your PG                       │
├──────────────────────────────────────┤
│  About your PG                       │  SectionHeader
│ ┌──────────────────────────────────┐ │  LedgerSheet, padding 16
│ │ PG name                          │ │
│ │ [                              ] │ │
│ │ Who stays here                   │ │
│ │ [ Men ] [ Women ] [ Anyone ]     │ │  OptionRow
│ └──────────────────────────────────┘ │
│  Address                             │
│ ┌──────────────────────────────────┐ │
│ │ Address        [ ... ]           │ │
│ │ Area (optional)[ ... ]           │ │
│ │ City           [ select      ⌄ ] │ │
│ │ Pincode (optional) [ ... ]       │ │
│ └──────────────────────────────────┘ │
│  Contact                             │
│ ┌──────────────────────────────────┐ │
│ │ Contact number (optional)        │ │
│ │ [+91 | ...........            ]  │ │
│ │ Guests see this number to        │ │
│ │ contact you.                     │ │
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ [          Create PG              ]  │  sticky bottom action
└──────────────────────────────────────┘
```

**Build**
1. Form page (see design system). Fields are stacked inside each `LedgerSheet` with 16 gaps.
2. "Who stays here": `OptionRow` with Men (`men`), Women (`women`), Anyone (`any`). Default Anyone.
3. City: `SelectField` opening an `OptionSheet` with search. Each row shows the city name with its state as the subtitle. Sorted by name.
4. Pincode: digits only, 6 digits, first digit 1 to 9. Optional.
5. Contact number: `PhoneField`, pre-filled with the signed-in person's own number, editable.
6. Validation (shown under the field after the first submit attempt or on blur): name required (maximum 60), address required, city required, pincode and contact number valid when filled.
7. Submit: button loading, call `rpc_create_pg`. On success: store the returned id as the selected PG, replace the stack with `/owner/home`, show the snackbar `pgCreated`.
8. The back arrow always returns to where the user came from. If the person has no PG yet, that is A3.

**Copy**

| Key | Text |
|---|---|
| `addPgTitle` | Add your PG |
| `addPgAbout` | About your PG |
| `addPgName` | PG name |
| `addPgWho` | Who stays here |
| `genderMen` | Men |
| `genderWomen` | Women |
| `genderAny` | Anyone |
| `addPgAddressSection` | Address |
| `addPgAddress` | Address |
| `addPgAddressHint` | Building, street |
| `addPgArea` | Area (optional) |
| `addPgAreaHint` | Area or locality |
| `addPgCity` | City |
| `addPgCityPick` | Choose a city |
| `addPgPincode` | Pincode (optional) |
| `addPgContactSection` | Contact |
| `addPgContact` | Contact number (optional) |
| `addPgContactHelper` | Guests see this number to contact you. |
| `addPgCreate` | Create PG |
| `pgCreated` | PG created. |
| `errPgName` | Enter the PG name. |
| `errPgAddress` | Enter the address. |
| `errPgCity` | Choose a city. |
| `errPincode` | Enter a 6-digit pincode. |

---

## O2. Owner home

**Route** `/owner/home`. **Tab** 1. **Reads** `v_pg_setup_status`, `v_pg_overview`, `v_pg_monthly_summary` (selected month), `v_guest_list` (overdue guests), `v_payment_feed` (pending payments).

```
┌──────────────────────────────────────┐
│ {PG name} ⌄                       🔔 │  AppTopBar with PgSwitcherTitle
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │  Summary sheet, padding 16
│ │ November 2026               ‹   ›│ │  label (ink, 600) + month arrows
│ │ To collect this month            │ │  secondary
│ │ ₹48,500                          │ │  display
│ │ ▓▓▓▓▓▓▓▓▓▓▓▓░░░░░░░░░░░░░░       │ │  ProgressBarThin
│ │ ₹1,12,000 of ₹1,60,500 collected │ │  secondary
│ │ ──────────────────────────────── │ │  hairline
│ │ Overdue                ₹12,000  >│ │  48 high row, value in overdueFg
│ └──────────────────────────────────┘ │
│                                      │
│  [ Record payment ]  [ Add guest ]   │  primary + secondary, 12 gap, padding 16
│                                      │
│  Needs attention                  3  │  SectionHeader + count
│ ┌──────────────────────────────────┐ │
│ │ [101] {name}              ₹2,500 │ │
│ │       Reported ₹2,500 by UPI,    │ │
│ │       3 Nov              [Pending]│ │
│ │       Reject   Confirm           │ │  inline actions
│ │ ──────────────────────────────── │ │
│ │ [102] {name}              ₹6,500 │ │
│ │       Overdue since 27 Oct       │ │
│ │                          [Overdue]│ │
│ │       Remind   Record payment    │ │
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │
│ │ Where was the money received?  > │ │
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ Home   Guests   Payments   More      │  AppBottomNav
└──────────────────────────────────────┘
```

**Build**
1. Body scrolls and supports pull to refresh (reload everything).
2. **Set up your PG sheet** (first, only while `rooms_count`, `accounts_count` or `guests_count` from `v_pg_setup_status` is zero): padding 16; title `setupTitle` (`heading`), 4 below `setupBody` (`secondary`), 8 gap, then three rows of minimum height 56: a 24 status circle on the left (done: filled `paidFg` circle with a white `check` 16; not done: 2 dp `outline` ring), 12 gap, title `body` (done rows use `muted`), `chevronRight` on the right. Rows open O12, O14 (new account), O5. The sheet disappears when all three are done. While `guests_count` is zero, hide the summary sheet, the two buttons and "Needs attention" (the checklist replaces them).
3. **Summary sheet** (when `guests_count` is above zero), padding 16:
   - Row 1: month name (`label`, weight 600, ink) on the left; on the right two 48 x 48 icon buttons `chevronLeft` and `chevronRight` (24, ink). The selected month starts as the current month in India time. "Next" is disabled on the current month. "Previous" goes back up to 24 months.
   - 8 below: label `secondary`: `monthToCollect` for the current month, otherwise `monthToCollectIn`.
   - Amount: `Money(pending_paise)` in `display` from `v_pg_monthly_summary`.
   - 12 below: `ProgressBarThin`; value = `collected_paise` divided by `expected_paise` (0 when expected is 0).
   - 8 below: `monthCollected` in `secondary`, amounts formatted with `formatRupees`.
   - If the month has no summary row: replace the label, amount, bar and line with `monthNoCharges` in `secondary`.
   - 16 gap, a `hairline`, then a tappable row (minimum 48): `overdueLabel` (`body`) on the left; on the right `Money(overdue_total_paise)` from `v_pg_overview` in `overdueFg` weight 600, or `overdueNone` in `muted` when zero; then `chevronRight` 20. It opens the Guests tab with the Overdue filter selected.
4. **Buttons row** (padding 16, shown with the summary): `AppButton.primary` "Record payment" and `AppButton.secondary` "Add guest" side by side, equal width, 12 gap. "Record payment" opens an `OptionSheet` titled `pickGuestTitle` with a search field `pickGuestSearch` listing open guests from `v_guest_list` (name, and `Room {room}` as the subtitle); choosing one opens O7. "Add guest" opens O5. Managers and owners only for "Add guest"; all roles for "Record payment".
5. **Needs attention:** `SectionHeader` with `needsAttention` and the number of rows below as the trailing count. One `LedgerSheet` with rows, in this order:
   1. Pending payments: all rows of `v_payment_feed` for this PG with `status = 'pending'`, oldest first.
   2. Overdue guests: `v_guest_list` rows for this PG with `overdue_paise > 0` and `stay_status <> 'vacated'`, ordered by `oldest_unpaid_due_date` ascending, at most 10 in total across both groups.
   - *Pending row:* leading `RoomTile(room_number)`; title the guest name; subtitle `rowReported` (amount, method label, date `paid_on`); trailing `Money(amount_paise)` and a `pending` chip; inline actions "Reject" and "Confirm" (see O8 sheets).
   - *Overdue row:* leading `RoomTile`; title the guest name; subtitle `rowOverdueSince` with `oldest_unpaid_due_date`; trailing `Money(overdue_paise)` and an `overdue` chip; inline actions "Record payment" (O7) and, only if `AppFlags.remindersEnabled`, "Remind".
   - Tapping the row body opens O6 for that stay.
   - If more overdue guests exist than fit, add a last row "See all overdue ({count})" with `chevronRight`, opening the Guests tab on the Overdue filter.
   - Nothing to show (and `guests_count` above zero): a sheet with padding 24, centred: `check` icon 28 in `paidFg`, 8 gap, `needsAttentionEmptyTitle` (`heading`), 4 gap, `needsAttentionEmptyBody` (`secondary`).
6. **Money received row:** a separate `LedgerSheet` (12 gap above) with one row `collectionsLink` and `chevronRight`, opening O10.
7. The bell in the top bar opens S3. It shows the unread dot.

**States** loading (skeleton for the summary sheet and four skeleton rows), error with retry, data.

**Copy**

| Key | Text |
|---|---|
| `setupTitle` | Set up your PG |
| `setupBody` | Three quick steps and you can start collecting rent. |
| `setupRooms` | Add rooms and beds |
| `setupAccount` | Add a receiving account |
| `setupGuest` | Add your first guest |
| `monthToCollect` | To collect this month |
| `monthToCollectIn` | To collect in {month} |
| `monthCollected` | {collected} of {expected} collected |
| `monthNoCharges` | No rent charged for {month} yet. |
| `overdueLabel` | Overdue |
| `overdueNone` | None |
| `actionRecordPayment` | Record payment |
| `actionAddGuest` | Add guest |
| `pickGuestTitle` | Who paid? |
| `pickGuestSearch` | Search guests |
| `needsAttention` | Needs attention |
| `needsAttentionEmptyTitle` | Nothing needs attention |
| `needsAttentionEmptyBody` | Everyone is up to date. |
| `rowOverdueSince` | Overdue since {date} |
| `rowReported` | Reported {amount} by {method}, {date} |
| `actionRemind` | Remind |
| `actionConfirm` | Confirm |
| `actionReject` | Reject |
| `seeAllOverdue` | See all overdue ({count}) |
| `collectionsLink` | Where was the money received? |

---

## O3. PG switcher

**Opens from** the `PgSwitcherTitle` on any tab page. **Reads** `rpc_my_context` (`pgs`) and `pgs` with `addresses(area, cities(name))`.

**Build**
1. `AppBottomSheet` titled `switcherTitle`.
2. One row per PG (minimum 64): title the PG name (`bodyMedium`), subtitle `{area}, {city}` (`secondary`, skip empty parts), then the person's role in that PG (`secondary`: Owner, Manager or Caretaker) and, for the selected PG, a `check` icon in `petrol`.
3. Choosing a PG stores it as selected, closes the sheet and reloads the current tab for that PG.
4. A last row with a `plus` icon in `petrol` and the text `switcherAdd` opens O1.

**Copy**

| Key | Text |
|---|---|
| `switcherTitle` | Your PGs |
| `switcherAdd` | Add another PG |
| `roleOwner` | Owner |
| `roleManager` | Manager |
| `roleCaretaker` | Caretaker |

---

## O4. Guests

**Route** `/owner/guests`. **Tab** 2. **Reads** `v_guest_list` (this PG) and `v_pg_overview` (tab counts).

```
┌──────────────────────────────────────┐
│ {PG name} ⌄                       +  │  plus = Add guest (owner, manager)
├──────────────────────────────────────┤
│  🔍 Search name, room or number      │  44 high search field on ground
├──────────────────────────────────────┤
│ All 24   Overdue 5   Due 2   Paid 17  Past 3   │  UnderlineTabs
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │ [101] {name}              ₹6,500 │ │
│ │       Bed A, overdue since 27 Oct│ │
│ │                          [Overdue]│ │
│ │ ──────────────────────────────── │ │
│ │ [101] {name}              ₹2,500 │ │
│ │       Bed B, payment waiting     │ │
│ │                          [Pending]│ │
│ │ ──────────────────────────────── │ │
│ │ [102] {name}                     │ │
│ │       Bed A, paid up      [Paid] │ │
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ Home   Guests   Payments   More      │
└──────────────────────────────────────┘
```

**Build**
1. **Search row:** padding 12 and 16 on a `ground` background. Field: height 44, `surface`, 1 dp `outline` border, radius 8, `search` icon 20 on the left, hint `guestSearchHint`. Filters the loaded rows by name, phone digits and room number (client side).
2. **Tabs** (`UnderlineTabs`): All (`open_count`), Overdue (`overdue_count`), Due (`due_count`), Paid (`paid_count`), Past (`past_count`) from `v_pg_overview`.
   - All: `stay_status <> 'vacated'`. Overdue: `overdue_paise > 0` and open. Due: `outstanding_paise > 0` and `overdue_paise = 0` and open. Paid: `outstanding_paise = 0` and open. Past: `stay_status = 'vacated'`.
   - Order (open tabs): `overdue_paise` descending, then `outstanding_paise` descending, then `full_name` ascending. Past: `leave_date` descending.
3. **Row** (`LedgerRow`): leading `RoomTile(room_number)`; title `full_name` (if empty, the phone); subtitle, one line, built from two parts joined with a comma:
   - bed part: `Bed {bed_label}` or `guestNoBed` when there is no bed;
   - state part from `attention_state`: `overdue` gives `guestStateOverdue` with `oldest_unpaid_due_date`; `pending` gives `guestStatePending`; `due` gives `guestStateDue` with `oldest_unpaid_due_date`; `paid` gives `guestStatePaid`, and when `credit_paise` is above zero `guestStatePaidAdvance` with that amount.
   - trailing: `overdue` shows `Money(overdue_paise)` and an `overdue` chip; `pending` shows `Money(pending_verification_paise)` and a `pending` chip; `due` shows `Money(outstanding_paise)` and a `due` chip; `paid` shows only a `paid` chip.
   - **Past rows:** subtitle `guestLeft` with `leave_date`; trailing `Money(outstanding_paise)` in `overdueFg` only if it is above zero; no chip.
   - Tapping a row opens O6.
4. Pagination: 50 rows at a time, load the next page near the end of the list.
5. The `plus` action in the top bar opens O5 (owner and manager only).

**States** loading (`SkeletonList`), error, empty. Empty with no guests at all: `EmptyState` icon `guests`, `guestsEmptyTitle`, `guestsEmptyBody`, button "Add guest" (owner, manager only). Empty tab or search: `EmptyState` with `guestsFilterEmptyTitle`, `guestsFilterEmptyBody`, no button.

**Copy**

| Key | Text |
|---|---|
| `guestSearchHint` | Search name, room or number |
| `tabAll` | All |
| `tabOverdue` | Overdue |
| `tabDue` | Due |
| `tabPaid` | Paid |
| `tabPast` | Past |
| `guestNoBed` | No bed yet |
| `guestStateOverdue` | overdue since {date} |
| `guestStatePending` | payment waiting for you |
| `guestStateDue` | due {date} |
| `guestStatePaid` | paid up |
| `guestStatePaidAdvance` | paid up, advance {amount} |
| `guestLeft` | Left {date} |
| `guestsEmptyTitle` | No guests yet |
| `guestsEmptyBody` | Add your first guest to start tracking rent. |
| `guestsFilterEmptyTitle` | No guests here |
| `guestsFilterEmptyBody` | Nothing matches this filter. |

---

## O5. Add guest

**Route** `/owner/guests/new` (optional extra: `bedId` when opened from a free bed). **Does** `rpc_create_stay(p_pg_id, p_phone, p_full_name, p_bed_id, p_join_date, p_monthly_rent_paise, p_deposit_paise, p_billing_day, p_billing_starts_on, p_deposit_already_paid)`. **Reads** `v_bed_occupancy` (free beds). **Roles** owner and manager.

```
┌──────────────────────────────────────┐
│ ←  Add guest                         │
├──────────────────────────────────────┤
│  Guest                               │
│ ┌──────────────────────────────────┐ │
│ │ Mobile number                    │ │
│ │ [+91 | ...............        ]  │ │
│ │ This number will be used to sign │ │
│ │ in as a guest.                   │ │
│ │ Full name                        │ │
│ │ [                              ] │ │
│ └──────────────────────────────────┘ │
│  Stay                                │
│ ┌──────────────────────────────────┐ │
│ │ Bed (optional)                   │ │
│ │ [ Choose a bed              ⌄ ]  │ │
│ │ Joining date                     │ │
│ │ [ 12 Nov 2026               📅 ] │ │
│ └──────────────────────────────────┘ │
│  Rent and deposit                    │
│ ┌──────────────────────────────────┐ │
│ │ Monthly rent       [ ₹ ........ ]│ │
│ │ Security deposit (optional)      │ │
│ │                    [ ₹ ........ ]│ │
│ │ Rent is due on day  [ 12      ⌄ ]│ │
│ │ Due every month on this day.     │ │
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │
│ │ Already staying here       [ o ] │ │  SwitchRow
│ │ Turn on for guests who joined    │ │
│ │ before you started using the app.│ │
│ │ ── (when on) ─────────────────── │ │
│ │ Start billing from [ 12 Nov 2026 ]│ │
│ │ Rent due before this date won't  │ │
│ │ be billed.                       │ │
│ │ Deposit already received   [ o ] │ │
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ [           Add guest             ]  │
└──────────────────────────────────────┘
```

**Build**
1. Form page. Sections with `SectionHeader`s: `addGuestSection` ("Guest"), `addGuestStaySection` ("Stay"), `addGuestMoneySection` ("Rent and deposit"). The "Already staying" `SwitchRow` sits in its own sheet below.
2. **Mobile number:** `PhoneField`. **Full name:** `AppTextField`, required.
3. **Bed:** `SelectField` opening an `OptionSheet` of beds from `v_bed_occupancy` where `stay_id` is null and the bed and room are active. Each row: `Room {room_number}, bed {bed_label}` with the room type label as subtitle. The first row is "No bed yet". If opened with `bedId`, it is preselected.
4. **Joining date:** `DateField`, default today, no date limit in the past, not later than 30 days ahead.
5. **Monthly rent:** `MoneyField`, required, above zero. **Security deposit:** `MoneyField`, optional.
6. **Rent is due on day:** `SelectField` with days 1 to 28. Default: the day of the joining date, capped at 28. It follows the joining date until the owner picks a day by hand. Helper `billingDayHelper`.
7. **Already staying here:** `SwitchRow`, off by default. When on, reveal inside the sheet: "Start billing from" (`DateField`, default today, helper `billingStartHelper`) and a `SwitchRow` "Deposit already received" (default on; helper `depositReceivedHelper`). The values map to `p_billing_starts_on` and `p_deposit_already_paid`. When off, send `null` and `false`.
8. **Submit:** the sticky button "Add guest", loading while the call runs. Money values go to the function in paise. On success: open O6 for the new stay (replace this page) and show the bottom sheet `InviteSheet`:
   - title `inviteTitle`, body `inviteBody` ("Ask {name} to sign in with {phone}."),
   - primary "Invite on WhatsApp" (shares the text `inviteMessage`; the app link is added only if `AppConfig.playStoreUrl` is not empty),
   - `.text` "Done".
9. **Errors from the database:** a duplicate open stay (SQLSTATE `23505`) shows `errGuestExists` under the mobile number field. A bed that was taken meanwhile (`23505` on the bed) shows `errBedTaken` under the bed field. Other messages are shown as the snackbar text.

**Copy**

| Key | Text |
|---|---|
| `addGuestTitle` | Add guest |
| `addGuestSection` | Guest |
| `addGuestStaySection` | Stay |
| `addGuestMoneySection` | Rent and deposit |
| `guestMobile` | Mobile number |
| `guestMobileHelper` | This number will be used to sign in as a guest. |
| `guestName` | Full name |
| `guestBed` | Bed (optional) |
| `guestBedPick` | Choose a bed |
| `guestBedNone` | No bed yet |
| `guestJoinDate` | Joining date |
| `guestRent` | Monthly rent |
| `guestDeposit` | Security deposit (optional) |
| `guestBillingDay` | Rent is due on day |
| `billingDayHelper` | Due every month on this day. |
| `alreadyStaying` | Already staying here |
| `alreadyStayingHelper` | Turn on for guests who joined before you started using the app. |
| `billingStartsFrom` | Start billing from |
| `billingStartHelper` | Rent due before this date won't be billed. |
| `depositReceived` | Deposit already received |
| `depositReceivedHelper` | The deposit will not show as due. |
| `addGuestAction` | Add guest |
| `inviteTitle` | Guest added |
| `inviteBody` | Ask {name} to sign in with {phone}. |
| `inviteAction` | Invite on WhatsApp |
| `inviteMessage` | Hi {name}, I've added you to {pg} on {appName}. Download the app and sign in with this mobile number. |
| `errGuestExists` | This guest is already staying in this PG. |
| `errBedTaken` | That bed was just taken. Choose another. |
| `errGuestName` | Enter the guest's name. |
| `errRent` | Enter the monthly rent. |

---

## O6. Guest detail

**Route** `/owner/guests/:stayId`. **Reads** `v_guest_list` (the stay), `v_charge_balances` (this stay), `v_payment_feed` (this stay), `emergency_contacts` (this person, open stays only), `person_documents` (count).

```
┌──────────────────────────────────────┐
│ ←  {guest name}                   ⋯  │  ⋯ opens the actions sheet
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │  Header sheet, padding 16
│ │ [101]  {name}           [Overdue]│ │  RoomTile 44 + title + chip
│ │        +91 98765 43210      [📞] │ │  secondary + phone icon button
│ │        Room 101, bed A, since    │ │
│ │        3 Jun 2026                │ │
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │  Balance sheet, padding 16
│ │ Outstanding                      │ │  secondary
│ │ ₹15,000                          │ │  display (overdueFg if overdue)
│ │ ──────────────────────────────── │ │
│ │ Charged     Paid       Advance   │ │  three columns, secondary labels
│ │ ₹29,500     ₹14,500    ₹0        │ │  heading values
│ └──────────────────────────────────┘ │
│  [         Record payment         ]  │  primary, expand, padding 16
│                                      │
│  Waiting for you                     │  only if pending payments exist
│ ┌ rows with Reject / Confirm ──────┐ │
│  Charges                    See all  │
│ ┌ {description}  due 27 Oct ₹6,500 [Overdue]
│  Payments                   See all  │
│ ┌ [₹] UPI, PhonePe  12 Nov  ₹2,500 [Pending]
│  Details                             │
│ ┌ Monthly rent ₹6,500 ┐              │
│ │ Rent due on  Day 12 of every month │
│ │ Joined       3 Jun 2026            │
│ │ App          Signed in             │
│ │ Emergency contact  {name} >        │
│ │ ID documents       {n} uploaded    │
│ └────────────────────────────────────┘
└──────────────────────────────────────┘
```

**Build**
1. **Top bar:** back, title the guest name (`full_name`, or the phone), action `more` (three dots) opening the actions sheet (O17). Caretakers do not get the action.
2. **Header sheet:** `RoomTile` 44 (room number), then a column: name (`title`), phone (`secondary`) with a trailing `phone` icon button 48 x 48 that opens the dialer, and `Room {room}, bed {bed}, since {join_date}` (`secondary`; for a past stay: `guestDetailStayEnded` with both dates). Top-right: the status chip from `attention_state` (`past` has no chip).
3. **Balance sheet:** label `balanceOutstanding` (`secondary`), `Money(outstanding_paise)` in `display` (in `overdueFg` when `overdue_paise` is above zero, otherwise `ink`). 16 gap, a hairline, then three equal columns each with a `secondary` label above a `heading` `Money`: `balanceCharged` (`charged_paise`), `balancePaid` (`paid_paise`), `balanceAdvance` (`credit_paise`). If `pending_verification_paise` is above zero, add a line at the bottom of the sheet: a `pendingBg` block (radius 4, padding 12) with a `clock` icon 20 and `balanceWaiting` in `pendingFg`.
4. **Record payment:** `AppButton.primary` (expand) on `ground`, padding 16, opens O7. All roles. It stays available for a past stay that still owes money.
5. **Waiting for you:** shown only when this stay has `status = 'pending'` payments. `SectionHeader` + `LedgerSheet` with the same pending rows as O2 (inline Reject and Confirm), no leading tile.
6. **Charges:** `SectionHeader` (`detailCharges`, trailing "See all" if more than 6). A `LedgerSheet` with up to 6 charges from `v_charge_balances`, newest due date first ("See all" opens a pushed list page with all charges of this stay, same row design). Row: title `description`; subtitle `chargeDue` with `due_date`; trailing `Money` (outstanding amount while unpaid, the full amount when paid) and a chip: `paid` gives a `paid` chip; `overdue` an `overdue` chip; `due` a `due` chip; `partial` a `due` chip with the text `chargePartPaid`; `void` a `due` chip with `chargeCancelled` (and `muted` amount). Tapping a row opens a small sheet with the details and, for owner and manager on unpaid charges, the destructive text action "Cancel charge" (O17).
7. **Payments:** `SectionHeader` (`detailPayments`, "See all" if more than 6). Up to 6 rows from `v_payment_feed`, newest first. Row: leading `RoomTile` showing the method icon (`cash`, `upi` or `bank`; cheque uses `cash`); title `method_label` plus `, {payer_app_label}` if present; subtitle the `paid_on` date; trailing `Money` and a chip only for `pending` (`pending`), `rejected` (`overdue` chip with the text `statusRejected`) and `reversed` (`overdue` chip with `statusReversed`). Tapping opens O8. "See all" opens a pushed list page that shows all payments of this stay with the same row design.
8. **Details sheet** (`KeyValueRow`s): Monthly rent (`monthly_rent_paise`), Rent due on (`profileDueDay` with `billing_day`), Joined (`join_date`), App (`detailAppSignedIn` or `detailAppNotYet` from `has_signed_in`; when not signed in, a trailing `.text` "Invite again" shares the invite text), Emergency contact (primary contact name and relation; tapping opens the dialer with its number; `detailNone` if there is none; only for an open stay), ID documents (`detailDocuments` with the count; `detailNone` if zero; open stays only).
9. **States:** loading skeleton blocks for the header and balance sheets, then rows; error with retry; the whole page reloads after any action.

**Copy**

| Key | Text |
|---|---|
| `guestDetailStayEnded` | Room {room}, bed {bed}, {from} to {to} |
| `guestDetailStay` | Room {room}, bed {bed}, since {date} |
| `balanceOutstanding` | Outstanding |
| `balanceCharged` | Charged |
| `balancePaid` | Paid |
| `balanceAdvance` | Advance |
| `balanceWaiting` | {amount} reported by the guest, waiting for you. |
| `waitingForYou` | Waiting for you |
| `detailCharges` | Charges |
| `detailPayments` | Payments |
| `detailDetails` | Details |
| `detailApp` | App |
| `detailAppSignedIn` | Signed in |
| `detailAppNotYet` | Not signed in yet |
| `detailInviteAgain` | Invite again |
| `detailEmergency` | Emergency contact |
| `detailDocuments` | ID documents |
| `detailDocumentsCount` | {count} uploaded |
| `detailNone` | None |

---

## O7. Record payment

**Route** `/owner/guests/:stayId/pay` (full screen, close icon). **Does** `rpc_record_payment(p_stay_id, p_amount_paise, p_method_code, p_paid_on, p_account_id, p_note, p_payer_app_code, p_utr)`. **Reads** `v_guest_list` (this stay), `payment_methods`, `pg_payment_accounts` (active), `upi_apps`. **Roles** all.

```
┌──────────────────────────────────────┐
│ ✕  Record payment                    │
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │ {guest name}                     │ │  heading
│ │ Room 101, bed A                  │ │  secondary
│ └──────────────────────────────────┘ │
│ ┌──────────────────────────────────┐ │
│ │ Amount                           │ │
│ │ ₹ [ 6,500                      ] │ │  MoneyField, large
│ │ Due now ₹6,500   All unpaid ₹13,000│ │  two text buttons
│ │ Payment method                   │ │
│ │ [ Cash ] [ UPI ]                 │ │  OptionRow, 2 columns
│ │ [ Bank transfer ] [ Cheque ]     │ │
│ │ Paid on                          │ │
│ │ [ 12 Nov 2026               📅 ] │ │
│ │ Received in                      │ │  (not for cash)
│ │ [ {nickname}                 ⌄ ] │ │
│ │ Paid using (optional)            │ │  (UPI only)
│ │ [ Choose an app             ⌄ ]  │ │
│ │ UTR (optional)                   │ │  (UPI only)
│ │ [                              ] │ │
│ │ Note (optional)                  │ │
│ │ [                              ] │ │
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ [        Record payment           ]  │
└──────────────────────────────────────┘
```

**Build**
1. Guest sheet: name (`heading`), `Room {room}, bed {bed}` (`secondary`).
2. **Amount:** `MoneyField` large variant. Default value: `due_now_paise` if above zero, else `outstanding_paise` if above zero, else empty. Under it, `.text` buttons (14 gap between, wrap if needed): `payDueNow` ("Due now {amount}") shown when `due_now_paise` is above zero; `payAllUnpaid` ("All unpaid {amount}") shown when `outstanding_paise` is above `due_now_paise`. Tapping sets the amount. When the entered amount is above `outstanding_paise`, show `payAdvanceNote` in `secondary` under the buttons.
3. **Payment method:** `OptionRow` built from the active `payment_methods` rows (Cash, UPI, Bank transfer, Cheque); default Cash.
4. **Paid on:** `DateField`, default today, cannot be after today.
5. **Received in:** shown for every method except Cash, only if the PG has at least one active receiving account. `SelectField` listing accounts (nickname as title; the UPI ID or `{bank}, ending {last4}` as subtitle) plus a first row `accountNotSure` ("Not sure"). Default: the default account. If the PG has no accounts, show a `secondary` line with an `info` icon: `noAccountsHint`.
6. **UPI only:** "Paid using (optional)": `SelectField` from `upi_apps`. "UTR (optional)": `AppTextField`, letters and digits, 6 to 22 characters when filled, helper `utrHelper`.
7. **Note (optional):** multi-line field.
8. **Submit:** sticky "Record payment", disabled until the amount is above zero. Loading while the call runs. On success: replace this page with S1 (`/receipt/{id}`, `isNew: true`).
9. Errors: a duplicate UTR (`23505`) shows the database message under the UTR field. Others: snackbar.
10. Leaving with unsaved input asks nothing (the form is short); the close icon just closes.

**Copy**

| Key | Text |
|---|---|
| `recordTitle` | Record payment |
| `recordAmount` | Amount |
| `payDueNow` | Due now {amount} |
| `payAllUnpaid` | All unpaid {amount} |
| `payAdvanceNote` | Anything above what is unpaid is kept as advance. |
| `recordMethod` | Payment method |
| `recordPaidOn` | Paid on |
| `recordReceivedIn` | Received in |
| `noAccountsHint` | Add a receiving account in More to track where money arrives. |
| `recordPaidUsing` | Paid using (optional) |
| `recordPaidUsingPick` | Choose an app |
| `recordUtr` | UTR (optional) |
| `recordNote` | Note (optional) |
| `recordAction` | Record payment |
| `errAmount` | Enter the amount. |
| `errUtr` | Enter 6 to 22 letters or digits. |

---

## O8. Payment detail

**Route** `/owner/payments/:paymentId`. **Reads** `v_payment_feed` (one row). **Does** `rpc_confirm_payment(p_payment_id, p_account_id)`, `rpc_reject_payment(p_payment_id, p_reason)`, `rpc_reverse_payment(p_payment_id, p_reason)`.

**Build**
1. Top bar: back, title `paymentTitle`.
2. **Summary sheet** (padding 16): `Money(amount_paise)` in `display`, with the status chip on the right: `pending`, `paid` (text `statusConfirmed` "Confirmed"), `overdue` with `statusRejected` or `statusReversed`.
3. **Details sheet** (`KeyValueRow`s, hide rows without a value): Guest (name; tapping opens O6), Room (`Room {room}, bed {bed}`), Method (`method_label`), Paid on (`paid_on`), Received in (`account_nickname` or `detailNone`), Paid using (`payer_app_label`), UTR (`utr`; long press copies it with the snackbar `copied`), From number (`payer_phone`), Reported (`created_at`, with `reportedByGuest` when `reported_by_guest` is true), Confirmed (`confirmed_at`), Note (`note`), Reason (`status_reason`, for rejected and reversed).
4. **Screenshot:** when `screenshot_file_id` is set, a row "Screenshot" with a 96 x 96 thumbnail (radius 6, 1 dp `hairline` border). Tapping opens a full-screen viewer (black background, pinch to zoom, close icon). The image is loaded from the private bucket `payment-screenshots` with a short-lived signed link. If it fails to load, show `screenshotFailed` in `secondary`.
5. **Sticky actions by status:**
   - `pending`: secondary "Reject" and primary "Mark as received" side by side (12 gap).
   - `confirmed`: primary "View receipt" (opens S1 with `receipt_id` known). Below the details sheet, a `.text` button "Reverse payment" in `overdueFg` (owner and manager only).
   - `rejected` and `reversed`: no actions.
6. **Mark as received sheet** (`ConfirmPaymentSheet`, shared with O2 and O6): title `confirmTitle`, body `confirmBody` ("{amount} from {name}"), a "Received in" `SelectField` (as in O7; default the reported account, else the default account; only if the PG has accounts), primary "Mark as received". On success: one light haptic, open S1 with `isNew: true` and the title `receiptConfirmed`.
7. **Reject sheet** (`RejectPaymentSheet`): title `rejectTitle`, a required multi-line field with label `rejectReason`, hint `rejectReasonHint`, helper `rejectHelper`, destructive primary "Reject payment". On success: snackbar `paymentRejected` and return.
8. **Reverse sheet:** title `reverseTitle`, body `reverseBody`, required reason field `reverseReason`, destructive primary "Reverse payment". On success: snackbar `paymentReversed` and the page reloads.

**Copy**

| Key | Text |
|---|---|
| `paymentTitle` | Payment |
| `detailGuest` | Guest |
| `detailRoom` | Room |
| `detailMethod` | Method |
| `detailPaidOn` | Paid on |
| `detailReceivedIn` | Received in |
| `detailPaidUsing` | Paid using |
| `detailUtr` | UTR |
| `detailFromNumber` | From number |
| `detailReported` | Reported |
| `reportedByGuest` | by the guest |
| `detailConfirmed` | Confirmed |
| `detailNote` | Note |
| `detailReason` | Reason |
| `detailScreenshot` | Screenshot |
| `screenshotFailed` | The screenshot could not be loaded. |
| `actionViewReceipt` | View receipt |
| `actionMarkReceived` | Mark as received |
| `actionRejectPayment` | Reject payment |
| `actionReversePayment` | Reverse payment |
| `confirmTitle` | Mark as received |
| `confirmBody` | {amount} from {name} |
| `rejectTitle` | Reject this payment? |
| `rejectReason` | Reason |
| `rejectReasonHint` | Reason, shown to the guest |
| `rejectHelper` | Tell the guest what to fix, such as the amount or the reference. |
| `paymentRejected` | Payment rejected. |
| `reverseTitle` | Reverse this payment? |
| `reverseBody` | The charges it paid become unpaid again. Use this only for a payment recorded by mistake. |
| `reverseReason` | Reason |
| `paymentReversed` | Payment reversed. |

---

## O9. Payments

**Route** `/owner/payments`. **Tab** 3. **Reads** `v_payment_feed` (this PG), `v_pg_overview` (`pending_payment_count`).

**Build**
1. Top bar: `PgSwitcherTitle` and the bell.
2. `UnderlineTabs`: "Waiting" (count `pending_payment_count`) and "Recent".
3. **Waiting:** a `LedgerSheet` of pending payments, oldest first, rows exactly as in O2 (leading `RoomTile`, guest name, `rowReported`, `Money`, `pending` chip, inline Reject and Confirm). Tapping the row opens O8. Empty: `EmptyState` with the `clock` icon, `waitingEmptyTitle`, `waitingEmptyBody`.
4. **Recent:** first a `LedgerSheet` with one row `collectionsLink` (opens O10). Then the payments with `status` in confirmed, reversed and rejected, ordered by `paid_on` descending then `created_at` descending, 50 at a time, grouped by day with `SectionHeader`s: `Today`, `Yesterday`, then `12 Nov` (the same year) or `12 Nov 2025`. Row: leading `RoomTile` with the method icon; title the guest name; subtitle `{method_label}` plus `, {payer_app_label}` if present plus `, Room {room}` if present; trailing `Money`, and a chip only for `reversed` and `rejected` (`overdue` chip). Tapping opens O8.
5. Empty (no payments at all): `EmptyState` with the `payments` icon, `paymentsEmptyTitle`, `paymentsEmptyBody`.

**Copy**

| Key | Text |
|---|---|
| `tabWaiting` | Waiting |
| `tabRecent` | Recent |
| `dayToday` | Today |
| `dayYesterday` | Yesterday |
| `waitingEmptyTitle` | Nothing is waiting |
| `waitingEmptyBody` | Payments your guests report will appear here for you to confirm. |
| `paymentsEmptyTitle` | No payments yet |
| `paymentsEmptyBody` | Recorded and confirmed payments will appear here. |

---

## O10. Money received

**Route** `/owner/collections`. **Reads** `v_collections_month_total`, `v_collections_by_account`.

**Build**
1. Top bar: back, title `collectionsTitle`.
2. **Total sheet** (padding 16): the month row with arrows exactly as in O2 (`label` + arrows); label `collectionsReceivedIn` ("Received in {month}", `secondary`); `Money(total_paise)` in `display`; `collectionsPayments` ("{count} payments", `secondary`). No row for the month: `Money(0)` and `collectionsNone`.
3. **Per account sheet:** one row per row of `v_collections_by_account` for the month, largest `total_paise` first. Leading tile with the method icon (`upi`, `bank` or `cash`), title `account_nickname` or, when null, the method label (`Cash` and so on), subtitle `collectionsCount` ("{count} payments"), trailing `Money(total_paise)`. Rows are not tappable.
4. Empty month: `EmptyState` with `collectionsEmptyTitle` and `collectionsEmptyBody`.

**Copy**

| Key | Text |
|---|---|
| `collectionsTitle` | Money received |
| `collectionsReceivedIn` | Received in {month} |
| `collectionsPayments` | {count, plural, =1{1 payment} other{{count} payments}} |
| `collectionsNone` | Nothing received this month. |
| `collectionsEmptyTitle` | Nothing received |
| `collectionsEmptyBody` | Money you record or confirm for this month will be listed by account. |

---

## O11. Rooms and beds

**Route** `/owner/rooms` and `/owner/rooms/:roomId`. **Reads** `v_bed_occupancy` (this PG).

**List**
1. Top bar: back, title `roomsTitle`, action `plus` (owner and manager) opening O12.
2. First a line in `secondary` (padding 16): `roomsSummary` ("{rooms} rooms, {beds} beds, {free} free"). These are counts of rows, not money.
3. Rooms grouped by `floor` with `SectionHeader`s (`roomsFloor`, "Floor {floor}") when at least one room has a floor; rooms without a floor go under `roomsNoFloor`. Without any floors, one plain list. Ordered by room number (natural order, so 9 comes before 10).
4. Row: leading `RoomTile(room_number)`; title `room_type_label` or `roomDefaultTitle` ("Room"); subtitle `roomsBedsFree` ("{beds} beds, {free} free"); trailing: `roomsFull` in `muted` when no bed is free, otherwise `roomsFreeCount` ("{free} free") in `petrol`. Tapping opens the room page.
5. Empty: `EmptyState` with the `room` icon, `roomsEmptyTitle`, `roomsEmptyBody`, button "Add rooms".

**Room page**
1. Top bar: back, title `Room {room_number}`.
2. A `LedgerSheet` of beds: leading `RoomTile(bed_label)`; title `occupant_name` (or the phone) when occupied, otherwise `bedFree` in `muted`; subtitle the occupant's phone or, for a free bed, nothing. Occupied: trailing `chevronRight`, tapping opens O6 for `stay_id`. Free (owner and manager): trailing `.text` "Add guest" opening O5 with that `bedId`.

**Copy**

| Key | Text |
|---|---|
| `roomsTitle` | Rooms and beds |
| `roomsSummary` | {rooms} rooms, {beds} beds, {free} free |
| `roomsFloor` | Floor {floor} |
| `roomsNoFloor` | No floor set |
| `roomDefaultTitle` | Room |
| `roomsBedsFree` | {beds} beds, {free} free |
| `roomsFull` | Full |
| `roomsFreeCount` | {free} free |
| `roomPageTitle` | Room {number} |
| `bedFree` | Free |
| `roomsEmptyTitle` | No rooms yet |
| `roomsEmptyBody` | Add your rooms and beds so you can give each guest a bed. |
| `roomsEmptyAction` | Add rooms |

---

## O12. Add rooms

**Route** `/owner/rooms/new`. **Does** `rpc_add_rooms(p_pg_id, p_first_room_number, p_room_count, p_beds_per_room, p_room_type_code, p_floor, p_prefix)`. **Reads** `room_types`. **Roles** owner and manager.

**Build**
1. Form page, one `LedgerSheet`, fields in this order: "First room number" (digits), "Number of rooms" (digits, 1 to 100, default 1), "Beds in each room" (`SelectField` 1 to 12, default 2), "Room type (optional)" (`SelectField` from `room_types`, first row "Not set"), "Floor (optional)" (digits), "Number prefix (optional)" (text, hint `roomPrefixHint`).
2. **Live line** under the fields, `secondary`, text `roomsPreview` (for example "This will add 10 rooms, 101 to 110, with 2 beds each (A, B)."). Shown only when the first number and count are valid.
3. Sticky button "Add rooms". On success: snackbar `roomsAdded` and back to the list. A clash (`Room X already exists`) shows the database message under the first room number field and nothing is created.

**Copy**

| Key | Text |
|---|---|
| `addRoomsTitle` | Add rooms |
| `roomFirstNumber` | First room number |
| `roomCount` | Number of rooms |
| `roomBeds` | Beds in each room |
| `roomType` | Room type (optional) |
| `roomTypeNone` | Not set |
| `roomFloor` | Floor (optional) |
| `roomPrefix` | Number prefix (optional) |
| `roomPrefixHint` | Letters before the number, if any |
| `roomsPreview` | This will add {count} rooms, {first} to {last}, with {beds} beds each ({labels}). |
| `roomsAddAction` | Add rooms |
| `roomsAdded` | {count} rooms added. |
| `errRoomNumber` | Enter the first room number. |
| `errRoomCount` | Enter a number from 1 to 100. |

---

## O13. More

**Route** `/owner/more`. **Tab** 4. Top bar: `PgSwitcherTitle` and the bell.

**Build** (rows are `LedgerRow`s with a 24 `ink` icon on the left, 16 gap, title `body`, `chevronRight`; minimum height 56):
1. `SectionHeader` `moreYourPg`, sheet with: "Rooms and beds" (`room`, O11), "Receiving accounts" (`bank`, O14; owner only), "Reminders" (`bell`, O15; owner only), "PG details" (`settings`, O16; owner only).
2. `SectionHeader` `moreAccount`, sheet with: "Profile" (`profile`, S2), "Switch to guest view" (`user`; only if the person also has a stay), "Add another PG" (`add`, O1).
3. If `AppConfig.termsUrl` or `privacyUrl` is not empty: `SectionHeader` `moreAbout` and a sheet with the matching rows (open in the browser).
4. A last sheet with one row "Sign out" in `overdueFg` (no chevron), opening the sign-out `ConfirmSheet`.

**Copy**

| Key | Text |
|---|---|
| `moreTitle` | More |
| `moreYourPg` | Your PG |
| `moreAccount` | Account |
| `moreAbout` | About |
| `moreRooms` | Rooms and beds |
| `moreAccounts` | Receiving accounts |
| `moreReminders` | Reminders |
| `morePgDetails` | PG details |
| `moreProfile` | Profile |
| `moreSwitchGuest` | Switch to guest view |
| `moreTerms` | Terms |
| `morePrivacy` | Privacy Policy |

---

## O14. Receiving accounts

**Route** `/owner/accounts`, `/owner/accounts/new`, `/owner/accounts/:id`. **Reads and writes** `pg_payment_accounts`. **Roles** owner.

**List**
1. Top bar: back, title `accountsTitle`, action `plus`.
2. Rows: leading tile with the `upi` or `bank` icon (20, `muted`); title `nickname`; subtitle: for UPI the `upi_vpa`, for bank `{bank_name}, ending {account_last4}` (omit the ending part if empty); trailing chips: `due`-kind chip `accountDefault` for the default account, `due`-kind chip `accountOff` for inactive ones. Tapping opens the form in edit mode.
3. Empty: `EmptyState` with the `bank` icon, `accountsEmptyTitle`, `accountsEmptyBody`, button "Add account".

**Form**
1. Fields: `OptionRow` "Type" (UPI, Bank), "Nickname" (required), then by type:
   - UPI: "UPI ID" (required; must look like `name@bank`: letters, digits, dots, dashes or underscores, an `@`, then letters), "Name on the UPI ID (optional)" (`holder_name`, helper `accountHolderHelper`).
   - Bank: "Bank name" (required), "Last 4 digits of the account (optional)", "Account holder name (optional)".
   - Both: "Linked mobile number (optional)" (`PhoneField`).
2. `SwitchRow` "Use as default" (default on when this is the first account). In edit mode also `SwitchRow` "Active".
3. Sticky "Save account". Making an account the default: first set `is_default = false` on the PG's other accounts, then save this one with `is_default = true` (two requests; if the second fails, no default is set, which is harmless).
4. A duplicate nickname (`23505`) shows `errAccountNickname` under the nickname field.
5. Accounts are never deleted. Switch "Active" off instead.

**Copy**

| Key | Text |
|---|---|
| `accountsTitle` | Receiving accounts |
| `accountsEmptyTitle` | No receiving accounts yet |
| `accountsEmptyBody` | Add the UPI ID or bank account where guests send rent. |
| `accountsEmptyAction` | Add account |
| `accountDefault` | Default |
| `accountOff` | Off |
| `accountBankEnding` | {bank}, ending {last4} |
| `accountType` | Type |
| `accountTypeUpi` | UPI |
| `accountTypeBank` | Bank |
| `accountNickname` | Nickname |
| `accountUpiId` | UPI ID |
| `accountHolderName` | Name on the UPI ID (optional) |
| `accountHolderHelper` | Shown to guests when they pay. |
| `accountBankName` | Bank name |
| `accountLast4` | Last 4 digits of the account (optional) |
| `accountBankHolder` | Account holder name (optional) |
| `accountLinkedPhone` | Linked mobile number (optional) |
| `accountUseDefault` | Use as default |
| `accountActive` | Active |
| `accountSave` | Save account |
| `errAccountNickname` | You already have an account with this nickname. |
| `errUpiId` | Enter a valid UPI ID, for example name@bank. |
| `errBankName` | Enter the bank name. |
| `errNickname` | Enter a nickname. |

---

## O15. Reminders

**Route** `/owner/reminders`. **Reads and writes** `reminder_rules`. **Roles** owner.

**Build**
1. Top bar: back, title `remindersTitle`, action `plus`.
2. While `AppFlags.remindersEnabled` is false, an info block at the top (`pendingBg`, radius 4, `info` icon, `pendingFg` `secondary` text, margin 16): `remindersSoon`. Hide it when the flag is true.
3. One `LedgerSheet`. Row: title built from `days_from_due`: below zero `remindBefore` ("{days} days before the due date", plural), zero `remindOn` ("On the due date"), above zero `remindAfter` ("{days} days after the due date"). Subtitle: the channel (`channelPush` "Push notification", `channelSms` "SMS", `channelWhatsapp` "WhatsApp"). Trailing: a switch bound to `is_active`. Tapping the row opens the edit sheet.
4. **Add or edit sheet:** "When" `OptionRow` (Before, On, After the due date); "Days" number field (1 to 30 before, 1 to 60 after; hidden for On); "How" `OptionRow` with Push enabled and SMS and WhatsApp disabled and labelled `comingLater`. Save writes `days_from_due` (negative for before) and `channel = 'push'`. A duplicate (`23505`) shows `errReminderExists`. In edit mode a destructive `.text` button "Remove reminder" deletes the rule after a `ConfirmSheet`.
5. Empty: `EmptyState` with `bell` icon, `remindersEmptyTitle`, `remindersEmptyBody`, button "Add reminder".

**Copy**

| Key | Text |
|---|---|
| `remindersTitle` | Reminders |
| `remindersSoon` | Reminders will start sending soon. You can set the timing now. |
| `remindBefore` | {days, plural, =1{1 day before the due date} other{{days} days before the due date}} |
| `remindOn` | On the due date |
| `remindAfter` | {days, plural, =1{1 day after the due date} other{{days} days after the due date}} |
| `channelPush` | Push notification |
| `channelSms` | SMS |
| `channelWhatsapp` | WhatsApp |
| `comingLater` | Coming later |
| `remindWhen` | When |
| `remindDays` | Days |
| `remindHow` | How |
| `remindWhenBefore` | Before the due date |
| `remindWhenOn` | On the due date |
| `remindWhenAfter` | After the due date |
| `remindRemove` | Remove reminder |
| `errReminderExists` | You already have this reminder. |
| `remindersEmptyTitle` | No reminders |
| `remindersEmptyBody` | Add reminders so guests are nudged before and after the due date. |
| `remindersEmptyAction` | Add reminder |

---

## O16. PG details

**Route** `/owner/settings`. **Reads and writes** `pgs` (`name`, `contact_phone`, `gender_policy`) and `addresses` (`line1`, `area`, `city_id`, `pincode`). **Roles** owner.

**Build**
1. Top bar: back, title `pgDetailsTitle`.
2. One `LedgerSheet` of rows (`KeyValueRow` style with a trailing `chevronRight`): PG name, Who stays here, Address (all address parts on up to three lines), Contact number. Each opens a bottom sheet with the same fields as in O1 and a Save button.
3. **Do not show** billing day, grace days or late fee settings in version 1. They are stored but not used yet.

**Copy**

| Key | Text |
|---|---|
| `pgDetailsTitle` | PG details |
| `pgDetailsSaved` | Saved. |

---

## O17. Guest actions (sheets)

Opened from the `more` action in O6 (owner and manager only). The first sheet lists the actions as rows; each opens its own sheet.

| Action row | Visible when | Sheet |
|---|---|---|
| "Change rent" | open stay | **Change rent** |
| "Add a charge" | any stay | **Add a charge** |
| "Correct name" | `has_signed_in` is false and the stay is open | **Correct name** |
| "Mark as vacated" (text in `overdueFg`) | open stay | **Vacate** |

**Change rent** (`rpc_set_stay_rent`): "New monthly rent" `MoneyField` (required, above zero); "Starting from" `DateField` (default today); helper `rentChangeHelper`; primary "Change rent". A duplicate date (`23505`) shows `errRentDate`. Success: snackbar `rentChanged`, reload.

**Add a charge** (`rpc_add_charge`): "Type" `SelectField` from `charge_types` where active, leaving out `rent`; "Amount" `MoneyField` (above zero); "Due date" `DateField` (default today); "Note (optional)" text. If the note is empty, send the charge type label as the description. For every type except the security deposit send `p_period_month` as the first day of the due date's month. Primary "Add charge". Success: snackbar `chargeAdded`, reload.

**Cancel a charge** (`rpc_void_charge`, opened from a charge row in O6): `ConfirmSheet` with a required reason field and the destructive button "Cancel charge". Success: snackbar `chargeCancelledToast`.

**Correct name** (`rpc_correct_guest_name`): one `AppTextField` (required) and Save. Success: snackbar `nameCorrected`.

**Vacate** (`rpc_vacate_stay`): `ConfirmSheet`; title `vacateTitle` ("Mark {name} as vacated?"); a "Leaving date" `DateField` (default today); body: if `outstanding_paise` is above zero `vacateBodyOwes` ("{name} still owes {amount}. You can keep recording payments after they leave."), otherwise `vacateBody`; destructive primary "Mark as vacated". Success: snackbar `vacatedToast`, return to the Guests list.

**Copy**

| Key | Text |
|---|---|
| `actionChangeRent` | Change rent |
| `actionAddCharge` | Add a charge |
| `actionCorrectName` | Correct name |
| `actionVacate` | Mark as vacated |
| `rentNew` | New monthly rent |
| `rentFrom` | Starting from |
| `rentChangeHelper` | Charges that already exist keep the old rent. |
| `rentChangeAction` | Change rent |
| `rentChanged` | Rent changed. |
| `errRentDate` | A rent change already exists from that date. Pick another date. |
| `chargeType` | Type |
| `chargeAmount` | Amount |
| `chargeDueDate` | Due date |
| `chargeNote` | Note (optional) |
| `chargeAddAction` | Add charge |
| `chargeAdded` | Charge added. |
| `chargeCancelTitle` | Cancel this charge? |
| `chargeCancelReason` | Reason |
| `chargeCancelAction` | Cancel charge |
| `chargeCancelledToast` | Charge cancelled. |
| `nameCorrected` | Name saved. |
| `vacateTitle` | Mark {name} as vacated? |
| `vacateLeaving` | Leaving date |
| `vacateBody` | Their records stay in your history. They will stop getting reminders. |
| `vacateBodyOwes` | {name} still owes {amount}. You can keep recording payments after they leave. |
| `vacatedToast` | {name} marked as vacated. |
