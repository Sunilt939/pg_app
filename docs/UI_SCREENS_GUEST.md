# UI screens: guest

Last updated: 12 Nov 2026

Screens in this file: **G1** Guest home, **G2** Pay rent, **G3** Tell your owner you've paid (sheet), **G4** History, **G5** Past stay.

Load `UI_DESIGN_SYSTEM.md` with this file. Receipt (S1), profile (S2) and notifications (S3) are in `UI_SCREENS_SHARED.md`.

**Reading the wireframes.** Names, numbers and amounts inside wireframes only show where things go. **Never copy them into code.** Every name and figure on a real screen comes from the database. Text is given as ARB keys with their English text.

**Spec gaps.** If a detail is missing, choose the simplest option that follows the design system and add one line to `docs/DECISIONS.md` under "UI gaps". Never invent colours, sizes or wording.

---

## Guest shell

Three tabs, `AppBottomNav`: Home (`/guest/home`), History (`/guest/history`), Profile (`/profile`, screen S2). Tab pages use a plain `AppTopBar` (the PG name as the title on Home; there is no PG switcher for guests) and the bell.

**Which stay is shown.** The guest's stays come from `v_guest_list` where `person_id` is the signed-in person. The *current stay* is the open stay (`stay_status <> 'vacated'`), most recent first. If there is none, the *latest stay* is the most recent past one. All other stays are *previous stays*. A guest normally has one open stay.

**The guest can never edit** rent, advance, join date, room or payment records. The only things a guest changes are their profile (S2) and reporting a payment (G3).

---

## G1. Guest home

**Route** `/guest/home`. **Tab** 1. **Reads** `v_guest_list` (current stay), `v_charge_balances` and `v_payment_feed` (this stay, for recent activity).

```
┌──────────────────────────────────────┐
│ {PG name}                         🔔 │  AppTopBar
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │  Rent sheet, padding 16
│ │ Overdue since 27 Oct             │ │  label (overdueFg, weight 600)
│ │ ₹6,500                           │ │  display (overdueFg)
│ │ ┌──────────────────────────────┐ │ │  only when something is waiting
│ │ │ 🕑 ₹2,500 reported. Waiting  │ │ │  pendingBg block, radius 4, padding 12
│ │ │ for your owner to confirm.   │ │ │
│ │ └──────────────────────────────┘ │ │
│ │ [          Pay ₹6,500          ] │ │  primary, expand
│ │        I've already paid         │ │  text button, centred
│ └──────────────────────────────────┘ │
│  Your stay                           │
│ ┌──────────────────────────────────┐ │
│ │ Monthly rent              ₹6,500 │ │  KeyValueRow
│ │ Rent due on  Day 12 of every month│ │
│ │ Advance balance           ₹5,000 │ │  only if above zero
│ │ Room            Room 101, bed A  │ │  only if available
│ └──────────────────────────────────┘ │
│  Recent activity             See all │
│ ┌──────────────────────────────────┐ │
│ │ Rent for Nov 2026        ₹6,500  │ │  up to 5 rows
│ │ Due 12 Nov                [Due]  │ │
│ └──────────────────────────────────┘ │
│  Your PG                             │
│ ┌──────────────────────────────────┐ │
│ │ Call {PG name}              [📞] │ │
│ │ +91 98765 43210                  │ │
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ Home      History      Profile       │
└──────────────────────────────────────┘
```

**Build**
1. Body scrolls; pull to refresh reloads everything.
2. **Rent sheet** (padding 16). Choose exactly one state from the current stay's `v_guest_list` row, in this order:

   | Condition | Label | Amount (`display`) | Pay amount |
   |---|---|---|---|
   | `overdue_paise > 0` | `rentOverdueSince` with `oldest_unpaid_due_date`, `overdueFg`, weight 600 | `Money(due_now_paise)` in `overdueFg` | `due_now_paise` |
   | `due_now_paise > 0` | `rentDueNow` (`label`, weight 600) | `Money(due_now_paise)` in `ink` | `due_now_paise` |
   | `next_due_paise > 0` | `rentNextDue` with `next_due_date` (`secondary`) | `Money(next_due_paise)` in `ink` | `next_due_paise` |
   | none of the above | `check` icon 28 in `paidFg` and `rentPaidUp` (`title`); under it `rentPaidUpBody` (`secondary`) | none | none |

3. **Waiting block:** if `pending_verification_paise` is above zero, show a `pendingBg` block (radius 4, padding 12, 12 above the buttons) with a `clock` icon 20 in `pendingFg` and the text `rentWaiting` in `secondary` colour `pendingFg`.
4. **Buttons:** when there is an amount to pay: `AppButton.primary` `payAction` ("Pay {amount}", expand) opening G2; 8 below, a centred `.text` button `alreadyPaid` opening G3 (variant B). In the paid-up state: no buttons.
5. **Your stay sheet:** `SectionHeader` `homeYourStay`; `KeyValueRow`s: Monthly rent (`monthly_rent_paise`), Rent due on (`profileDueDay` with `billing_day`), Advance balance (`credit_paise`; only above zero), Room (`Room {room}, bed {bed}`; only if `room_number` is present).
6. **Recent activity:** `SectionHeader` (`homeRecent`, trailing `actionSeeAll` opening G4). One `LedgerSheet` with the 5 newest events of the current stay, merging charges (`v_charge_balances`, by `due_date`) and payments (`v_payment_feed`, by `paid_on`) newest first. Display-only merge and sort.
   - *Charge row:* title `description`; subtitle `chargeDue` with `due_date`; trailing `Money` (outstanding while unpaid, otherwise the full amount) and a chip as in O6 (paid, overdue, due, part paid, cancelled).
   - *Payment row:* title `activityPayment` ("Payment, {method}", method plus `, {app}` if present); subtitle the `paid_on` date; trailing `Money` and a chip only for `pending` (`pending`), `rejected` and `reversed` (`overdue` chip with the matching word). Tapping opens the receipt (S1) if `receipt_id` is present, otherwise the payment status sheet (G4).
   - Nothing yet: a sheet with padding 24, `secondary` text `homeNoActivity`.
7. **Your PG sheet:** only if `pg_contact_phone` is not empty: one row, title `callPg` ("Call {pg}", `bodyMedium`), subtitle the phone (`secondary`), trailing `phone` icon button. Tapping opens the dialer.
8. **No current stay** (the guest only has past stays): replace everything with an `EmptyState`: icon `home`, title `noStayTitle`, body `noStayBody` ("You've left {pg}. Your past payments are in History."), button "See history" (opens G4). If that past stay still has `outstanding_paise` above zero, add under the body a `secondary` line `noStayOwes` ("{pg} shows {amount} unpaid. Please contact them.") and the Call row.

**States** loading (a skeleton rent sheet: a `SkeletonBlock` label, a large amount block and a button-shaped block, then four skeleton rows), error with retry.

**Copy**

| Key | Text |
|---|---|
| `rentOverdueSince` | Overdue since {date} |
| `rentDueNow` | Due now |
| `rentNextDue` | Next rent due {date} |
| `rentPaidUp` | You're all paid up |
| `rentPaidUpBody` | Your next rent will show here before it's due. |
| `rentWaiting` | {amount} reported. Waiting for your owner to confirm. |
| `payAction` | Pay {amount} |
| `alreadyPaid` | I've already paid |
| `homeYourStay` | Your stay |
| `homeRecent` | Recent activity |
| `homeNoActivity` | Nothing here yet. |
| `activityPayment` | Payment, {method} |
| `homeYourPg` | Your PG |
| `callPg` | Call {pg} |
| `noStayTitle` | No current stay |
| `noStayBody` | You've left {pg}. Your past payments are in History. |
| `noStayOwes` | {pg} shows {amount} unpaid. Please contact them. |
| `noStayAction` | See history |

---

## G2. Pay rent

**Route** `/guest/pay/:stayId`. **Reads** `v_guest_list` (this stay), `pg_payment_accounts` (active UPI accounts of the stay's PG). **Opens** the UPI app, then the report sheet (G3 variant A).

```
┌──────────────────────────────────────┐
│ ←  Pay rent                          │
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │
│ │ Amount                           │ │
│ │ ₹ [ 6,500                      ] │ │  MoneyField, large
│ │ Due now ₹6,500   Next rent ₹6,500│ │  quick-fill text buttons
│ └──────────────────────────────────┘ │
│  Pay to                              │
│ ┌──────────────────────────────────┐ │
│ │ {account nickname}         [copy]│ │  heading + copy icon button
│ │ {upi id}                         │ │  secondary
│ │ Pay to a different account       │ │  text button (only if several accounts)
│ └──────────────────────────────────┘ │
├──────────────────────────────────────┤
│ [       Pay with UPI app          ]  │  sticky
│          I paid another way          │  text button
└──────────────────────────────────────┘
```

**Build**
1. Top bar: back, title `payTitle`.
2. **Amount sheet:** label `payAmount`, `MoneyField` large variant, default the amount passed from G1. Quick-fill `.text` buttons: `payQuickDueNow` ("Due now {amount}", when `due_now_paise` is above zero) and `payQuickNext` ("Next rent {amount}", when `next_due_paise` is above zero). Each sets the field to that single value.
3. **Pay to sheet:** `SectionHeader` `payTo`. The chosen account: the default account (`is_default`), otherwise the first active UPI account. Shows `nickname` (`heading`) with a trailing copy icon button (copies the UPI ID, snackbar `copied`) and the `upi_vpa` (`secondary`). If more than one UPI account exists, a `.text` button `payOtherAccount` opens an `OptionSheet` to choose one.
4. **No UPI account:** replace the sheet with an `EmptyState`-style block (padding 24): `info` icon 28 in `muted`, `payNoAccountTitle`, `payNoAccountBody`. The "Pay with UPI app" button is disabled; the "I paid another way" link stays.
5. **Sticky actions:** primary `payUpiAction` ("Pay with UPI app"), disabled until the amount is above zero and an account exists. Below it a centred `.text` button `payOtherWay` opening G3 variant B with this amount.
6. **Opening the UPI app:** build `upi://pay` with `pa` = the account's `upi_vpa`, `pn` = `holder_name` or the PG name, `am` = the amount in rupees with two decimals (formatting only), `cu` = `INR`, `tn` = `Rent`. Open it with `url_launcher` using `LaunchMode.externalApplication`. If it cannot open, show the snackbar `payNoUpiApp` (the UPI ID can be copied).
7. **Coming back:** remember that a payment was started. When the app returns to the foreground (`AppLifecycleState.resumed`), open G3 variant A once for this attempt.
8. The Android manifest needs the `upi` scheme in `<queries>` (see `UI_GUIDE.md`).

**Copy**

| Key | Text |
|---|---|
| `payTitle` | Pay rent |
| `payAmount` | Amount |
| `payQuickDueNow` | Due now {amount} |
| `payQuickNext` | Next rent {amount} |
| `payTo` | Pay to |
| `payOtherAccount` | Pay to a different account |
| `payNoAccountTitle` | Your PG owner hasn't added a payment account yet |
| `payNoAccountBody` | Ask them to add one, or pay in cash or by bank transfer and tell them here. |
| `payUpiAction` | Pay with UPI app |
| `payOtherWay` | I paid another way |
| `payNoUpiApp` | No UPI app found. Copy the UPI ID and pay from any UPI app. |

---

## G3. Tell your owner you've paid (sheet)

**Opens from** G2 (variant A, after the UPI app) and from G1 or G2 ("I've already paid" and "I paid another way", variant B). **Does** `rpc_report_payment(p_stay_id, p_amount_paise, p_method_code, p_paid_on, p_account_id, p_payer_app_code, p_payer_phone, p_utr, p_note, p_screenshot_file_id)`. **Reads** `payment_methods`, `upi_apps`, `pg_payment_accounts`.

```
Variant A                               Variant B
┌────────────────────────────┐          ┌────────────────────────────┐
│ ▬                          │          │ ▬                          │
│ Did the payment go through?│          │ Tell your owner you've paid│
│ ₹6,500 to {nickname}       │          │ Amount  ₹ [ ........ ]    │
│ Add details (optional)   ⌄ │          │ How did you pay?           │
│  Paid using [select ⌄]     │          │ [Cash] [UPI] [Bank transfer]│
│  UTR or reference [ ... ]  │          │ Paid on [ 12 Nov 2026 ]    │
│  Paid from number [+91|..] │          │ (UPI: Paid to + details)   │
│  Screenshot [ Add ]        │          │ Note (optional)            │
│ [   Yes, I've paid      ]  │          │ [    Send to owner      ]  │
│        Not yet             │          └────────────────────────────┘
└────────────────────────────┘
```

**Build, variant A** (after paying by UPI)
1. `AppBottomSheet`, title `reportTitleA`. Under it, `secondary`: `reportSummaryA` ("{amount} to {account}").
2. A collapsed row `reportDetails` ("Add details (optional)") with a `chevronDown` that turns up when open (`AppMotion.base`). Collapsed by default so the fastest path is one tap. Open: "Paid using" (`SelectField` from `upi_apps`), "UTR or reference" (`AppTextField`, letters and digits, 6 to 22 when filled, helper `utrHelper`), "Paid from number" (`PhoneField`, optional), "Screenshot" (only when `AppFlags.uploadsEnabled` is true: a secondary button "Add screenshot"; once picked it shows a 64 x 64 thumbnail with a small remove icon).
3. Primary `reportYes` ("Yes, I've paid"); below it a `.text` button `reportNotYet` that just closes the sheet.
4. Values sent: method `upi`, the amount and account from G2, `p_paid_on` null (today).

**Build, variant B** (paid another way, or "I've already paid")
1. Title `reportTitleB`. Fields in order: "Amount" (`MoneyField`, default the pay amount from G1 or G2), "How did you pay?" (`OptionRow`: Cash, UPI, Bank transfer, from `payment_methods` excluding cheque; default Cash), "Paid on" (`DateField`, default today, not after today).
2. For UPI: a "Paid to" `SelectField` (the PG's active UPI accounts, default account preselected) and the same collapsible details as variant A. For Bank transfer: a "Paid to" `SelectField` of the PG's active bank accounts if any (optional, first row `accountNotSure`). For Cash: nothing more.
3. "Note (optional)". Primary `reportSend` ("Send to owner").

**Screenshot handling** (all of it only when `AppFlags.uploadsEnabled` is true). Pick with `image_picker`, resize to at most 1600 px on the longest side, JPEG quality 80. Upload to the private bucket `payment-screenshots` at `{stayId}/{uuid}.jpg`, insert a `files` row (`bucket`, `object_path`, `mime_type`, `size_bytes`, `uploaded_by` = me) and pass its id as `p_screenshot_file_id`. If the upload fails, show `reportScreenshotFailed` and let the guest continue without it. Screenshots are only for UPI.

**On success** (one light haptic): close the sheet, return to G1, show the snackbar `reportSent`, and reload. G1 now shows the waiting block.

**Errors:** a UTR already used (`23505`) shows the database message under the UTR field. A vacated stay or any other refusal shows the message as a snackbar. Network: `errorNetwork`.

**Copy**

| Key | Text |
|---|---|
| `reportTitleA` | Did the payment go through? |
| `reportSummaryA` | {amount} to {account} |
| `reportDetails` | Add details (optional) |
| `reportPaidUsing` | Paid using |
| `reportUtr` | UTR or reference |
| `reportFromNumber` | Paid from number |
| `reportScreenshot` | Screenshot |
| `reportScreenshotAdd` | Add screenshot |
| `reportYes` | Yes, I've paid |
| `reportNotYet` | Not yet |
| `reportTitleB` | Tell your owner you've paid |
| `reportHow` | How did you pay? |
| `reportPaidTo` | Paid to |
| `reportSend` | Send to owner |
| `reportSent` | Sent to your owner. You'll get a receipt once they confirm. |
| `reportScreenshotFailed` | Couldn't upload the screenshot. You can send without it. |

---

## G4. History

**Route** `/guest/history`. **Tab** 2. **Reads** `v_payment_feed` and `v_charge_balances` (the latest stay), `v_guest_list` (previous stays).

**Build**
1. Top bar title `historyTitle`, the bell.
2. `UnderlineTabs`: "Payments" and "Charges".
3. **Payments tab:** rows from `v_payment_feed` for the latest stay, newest `paid_on` first, grouped by month with `SectionHeader`s (`November 2026`). Row: leading `RoomTile` with the method icon; title `activityPayment`; subtitle `paid_on`; trailing `Money` and a chip only for `pending`, `rejected` and `reversed`. Tapping: if `receipt_id` is present, open S1; otherwise open the **payment status sheet**: an `AppBottomSheet` with the amount in `display`, the status chip, `KeyValueRow`s (Method, Paid on, Reported on), and for `pending` the line `statusSheetPending` ("Waiting for your owner to confirm."), for `rejected` the line `statusSheetRejected` ("Your owner said: {reason}") and a `.text` button `statusSheetPayAgain` opening G3 variant B.
4. **Previous stays** (at the end of the Payments tab, only if there are older stays): `SectionHeader` `historyPrevious`, then a `LedgerSheet` with one row per previous stay: title the PG name (`bodyMedium`), subtitle `historyStayDates` ("{from} to {to}"), `chevronRight`. Tapping opens G5.
5. **Charges tab:** rows from `v_charge_balances` for the latest stay, newest `due_date` first, grouped by month: title `description`, subtitle `chargeDue`, trailing `Money` and a chip (as in O6).
6. Empty payments: `EmptyState` `historyEmptyPaymentsTitle`, `historyEmptyPaymentsBody`. Empty charges: `historyEmptyChargesTitle`.
7. If the latest stay is a past stay, show a `secondary` line at the top of the page (padding 16): `historyPastNotice` ("This is your stay at {pg}, which has ended.").

**Copy**

| Key | Text |
|---|---|
| `historyTitle` | History |
| `tabPayments` | Payments |
| `tabCharges` | Charges |
| `historyPrevious` | Previous stays |
| `historyStayDates` | {from} to {to} |
| `historyPastNotice` | This is your stay at {pg}, which has ended. |
| `statusSheetPending` | Waiting for your owner to confirm. |
| `statusSheetRejected` | Your owner said: {reason} |
| `statusSheetPayAgain` | Report it again |
| `historyEmptyPaymentsTitle` | No payments yet |
| `historyEmptyPaymentsBody` | Payments you make or report will show here. |
| `historyEmptyChargesTitle` | No charges yet |

---

## G5. Past stay

**Route** `/guest/stay/:stayId`. **Reads** `v_guest_list` (this stay), `v_payment_feed` and `v_charge_balances` (this stay). Read-only.

**Build**
1. Top bar: back, title the PG name (`pg_name`).
2. A header sheet (padding 16): the PG name (`title`), the dates `historyStayDates` (`secondary`), and when `outstanding_paise` is above zero a line `noStayOwes` in `secondary`.
3. The same `UnderlineTabs`, rows and payment status sheet as G4 for this stay. No pay or report buttons anywhere on this page (reporting is not allowed for ended stays).
4. Room details may be missing (guests lose access to the room after leaving). Hide any row without data.

**Copy** uses the keys of G1 and G4.
