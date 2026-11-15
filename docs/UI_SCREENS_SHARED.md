# UI screens: sign-in and shared screens

Last updated: 12 Nov 2026

Screens in this file: **A1** Sign-in, **A2** Enter code, **A3** How will you use the app, **A4** Ask your owner to add you, **S1** Receipt, **S2** Profile, **S3** Notifications.

Load `UI_DESIGN_SYSTEM.md` with this file. Component names (`AppButton`, `LedgerSheet`, ...) and token names (`AppColors.petrol`, ...) are defined there.

**Reading the wireframes.** Names, numbers and amounts inside wireframes only show where things go. **Never copy them into code.** Every figure and name on a real screen comes from the database. Text is given as ARB keys; the key and its English text are both listed.

**Spec gaps.** If a detail is missing, choose the simplest option that follows the design system, and add one line to `docs/DECISIONS.md` under "UI gaps". Never invent colours, sizes or wording.

---

## A1. Sign-in

**Route** `/sign-in`. **Who** signed-out users. **Does** `supabase.auth.signInWithOtp(phone: '+91' + 10 digits)`, then opens A2.

```
┌──────────────────────────────────────┐
│ photo + scrim (72%)  (status bar: light icons)
│                                      │
│  [logo 32]  {appName}                │  left 24, 16 below the status bar
│                                      │
│                                      │
│  Your PG, in order.                  │  display, white, left 24
│  Rent, receipts and reminders        │  body, white 85%, max width 280
│  in one place.                       │
│▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔│  sheet top edge, radius 16
│  Enter your mobile number            │  title
│                                      │
│  Mobile number                       │  label
│  ┌─────┬────────────────────────┐    │  PhoneField, 52 high
│  │ +91 │ 10-digit mobile number │    │
│  └─────┴────────────────────────┘    │
│  We'll send a 6-digit code by SMS.   │  helper
│                                      │
│  [            Send code           ]  │  primary, expand
│                                      │
│  By continuing you agree to the      │  caption, centred
│  Terms and Privacy Policy.           │
└──────────────────────────────────────┘
```

**Build**
1. No top bar. Scaffold background `petrol` (visible if the photo fails).
2. Photo layer: `AppAssets.authBackdrop`, `BoxFit.cover`, filling everything above the sheet and extending 16 beneath the sheet's top edge. On top of it a full-size `AppColors.scrim` layer at **72 percent** opacity.
3. Brand row at left 24, top (status bar height + 16): `AppAssets.logoMarkWhite` 32 x 32, 12 gap, `AppConfig.appName` in `title` style, white.
4. Headline block anchored to the bottom of the photo area, left 24, 32 above the sheet: headline in `display`, white. 8 below it the subline in `body`, white at 85 percent, maximum width 280.
5. Sheet: `surface`, `AppRadius.sheetTop`, padding left, right and top 24, bottom 24 plus the bottom inset. Content in order: title (`title`), 16 gap, `PhoneField` with label, 8 gap helper text, 24 gap `AppButton.primary` (expand), 16 gap terms line.
6. The photo area takes all remaining height with a minimum of 96. When the area is under 180 high (keyboard open), hide the subline. Under 120, also hide the headline.
7. The button is disabled until the number is valid. Pressing it shows the button loading state, calls the API, and on success opens A2 with the phone as an argument.
8. Terms line: shown only if `AppConfig.termsUrl` and `AppConfig.privacyUrl` are both non-empty. "Terms" and "Privacy Policy" are `petrol` links (open in the browser). Otherwise hide the whole line.
9. Field error timing: show `phoneInvalid` under the field when the field loses focus with 1 to 9 digits, or immediately when the first digit is 0 to 5.

**States** idle, loading (button), error. Errors: network gives a snackbar with `errorNetwork`; too many requests gives `tooManyAttempts` as the field error; anything else gives a snackbar with `errorGeneric`.

**Copy**

| Key | Text |
|---|---|
| `signInHeadline` | Your PG, in order. |
| `signInSubline` | Rent, receipts and reminders in one place. |
| `signInTitle` | Enter your mobile number |
| `phoneLabel` | Mobile number |
| `phoneHint` | 10-digit mobile number |
| `phoneHelper` | We'll send a 6-digit code by SMS. |
| `phoneInvalid` | Enter a valid 10-digit mobile number. |
| `sendCode` | Send code |
| `tooManyAttempts` | Too many attempts. Please wait a few minutes and try again. |
| `termsLine` | By continuing you agree to the {terms} and {privacy}. |
| `termsLink` | Terms |
| `privacyLink` | Privacy Policy |

---

## A2. Enter code

**Route** `/verify` (argument: phone). **Does** `supabase.auth.verifyOTP(phone:, token:, type: OtpType.sms)`, then decides where to go (see "After sign-in").

```
┌──────────────────────────────────────┐
│ ←                                    │  white back arrow in a 48 tap area
│ photo + scrim (72%)                  │
│                                      │
│▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔▔│
│  Enter the 6-digit code              │  title
│  Sent to +91 98765 43210             │  secondary
│  Change number                       │  text button, no left padding
│                                      │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐       │  OtpField, 56 high boxes
│  └──┘ └──┘ └──┘ └──┘ └──┘ └──┘       │
│  (error text, 20 high reserved)      │
│  [             Verify              ]  │  primary, expand
│        Resend code in 0:28           │  secondary, centred
└──────────────────────────────────────┘
```

**Build**
1. Same photo, scrim and sheet as A1, but no brand row and no headline. The photo area has a minimum height of 160. Back arrow: white, top-left, 48 x 48, below the status bar. It returns to A1 with the number kept.
2. Sheet content in order: title, 4 gap, "Sent to" line (`secondary`, the phone shown as `+91 98765 43210`), a `.text` button "Change number" (aligned to the left edge of the text), 16 gap, `OtpField`, 8 gap error line (minimum height 20, `secondary` in `overdueFg`), 16 gap `AppButton.primary` "Verify" (expand), 16 gap resend row.
3. The keypad opens automatically with the first box focused.
4. Filling the sixth digit submits. The Verify button does the same and is enabled only with 6 digits and when not already submitting. Guard against double submission.
5. Resend row: for 30 seconds show `resendIn` with a countdown in `m:ss` (`secondary`, centred). After that show a `.text` button `resendAction`. Pressing it sends a new code, shows the snackbar `codeSent` and restarts the countdown.
6. **Wrong code:** boxes turn to the error style and shake (see motion), the error line shows `otpInvalid`, the input clears and focus returns to the first box. **Expired:** `otpExpired`. **Network:** snackbar `errorNetwork`.
7. **After sign-in** (one light haptic on success): call `rpc_my_context`, then
   - the person works in at least one PG (`pgs` not empty) and (has no `stays`, or the stored last view is `owner` or empty): go to `/owner/home`
   - otherwise, if the person has any `stays`: go to `/guest/home`
   - otherwise: go to `/gate` (A3).
   The last view ("owner" or "guest") is stored locally and changed only by the view switch in the More or Profile screens.

**Copy**

| Key | Text |
|---|---|
| `verifyTitle` | Enter the 6-digit code |
| `verifySentTo` | Sent to {phone} |
| `verifyChangeNumber` | Change number |
| `verifyAction` | Verify |
| `resendIn` | Resend code in {time} |
| `resendAction` | Resend code |
| `codeSent` | Code sent. |
| `otpInvalid` | That code isn't right. Check the SMS and try again. |
| `otpExpired` | That code has expired. Request a new one. |

---

## A3. How will you use the app

**Route** `/gate`. **Who** a signed-in person who works in no PG and has no stay. No data is loaded except the phone number.

```
┌──────────────────────────────────────┐
│                                      │
│  [logo tile 40]                      │  left 24, 48 below the status bar
│                                      │
│  How will you use {appName}?         │  display
│  Signed in as +91 98765 43210        │  secondary
│                                      │
│ ┌──────────────────────────────────┐ │  LedgerSheet
│ │ [🏢] I run a PG               >  │ │  (icon is the Phosphor `building`, not an emoji)
│ │      Create your PG and add      │ │
│ │      your guests.                │ │
│ │ ──────────────────────────────── │ │
│ │ [👤] I'm a guest              >  │ │
│ │      Your PG owner adds you      │ │
│ │      using your mobile number.   │ │
│ └──────────────────────────────────┘ │
│                                      │
│            Sign out                  │  text button, centred
└──────────────────────────────────────┘
```

**Build**
1. Background `ground`. No top bar. Content padding 24 on the sides.
2. Logo: `AppAssets.logoMark` 40 x 40.
3. Title in `display` (wraps to two lines). 8 below, the signed-in line in `secondary`.
4. 24 gap, then a `LedgerSheet` with two rows, each minimum 88 high. Leading: a 48 x 48 tile with `petrolTint` background and radius 6 holding the icon (`AppIcons.building` or `AppIcons.user`, size 28, `petrol`). Title `heading`. Body `secondary`, up to two lines. Trailing `chevronRight` 20 in `muted`. Divider inset 76.
5. "I run a PG" opens `/owner/pg/new`. "I'm a guest" opens `/gate/guest`.
6. 24 below the sheet: `.text` button "Sign out", centred. It signs out and returns to `/sign-in`.

**Copy**

| Key | Text |
|---|---|
| `gateTitle` | How will you use {appName}? |
| `gateSignedInAs` | Signed in as {phone} |
| `gateOwnerTitle` | I run a PG |
| `gateOwnerBody` | Create your PG and add your guests. |
| `gateGuestTitle` | I'm a guest |
| `gateGuestBody` | Your PG owner adds you using your mobile number. |

---

## A4. Ask your owner to add you

**Route** `/gate/guest`. **Does** `rpc_my_context` when "Check again" is pressed.

```
┌──────────────────────────────────────┐
│ ←                                    │  AppTopBar, no title
├──────────────────────────────────────┤
│  Ask your PG owner to add you        │  title
│  Your number isn't registered yet.   │  body
│  Please ask your PG owner to add you.│
│                                      │
│ ┌──────────────────────────────────┐ │  LedgerSheet
│ │ Your number                      │ │  secondary
│ │ +91 98765 43210            [copy]│ │  title style + copy icon button
│ └──────────────────────────────────┘ │
│                                      │
│  [          Check again          ]   │  primary, expand
│            Sign out                  │  text button
└──────────────────────────────────────┘
```

**Build**
1. Background `ground`. Content padding 16 on the sides, 24 above the title.
2. Number sheet: padding 16. Label `secondary`. Value in `title` style (the phone formatted `+91 98765 43210`). Trailing copy icon button (`AppIcons.copy`, 48 x 48). Copying shows the snackbar `numberCopied`.
3. "Check again" (primary, expand, 24 below the sheet) shows loading, then calls `rpc_my_context`. If the person now has a stay, go to `/guest/home`. If not, show the snackbar `stillNotAdded`.
4. "Sign out" `.text` button, centred, 12 below.

**Copy**

| Key | Text |
|---|---|
| `guestWaitTitle` | Ask your PG owner to add you |
| `guestWaitBody` | Your number isn't registered yet. Please ask your PG owner to add you. |
| `yourNumber` | Your number |
| `numberCopied` | Number copied. |
| `checkAgain` | Check again |
| `stillNotAdded` | Still not added. Ask your PG owner to check the number. |

---

## S1. Receipt

**Route** `/receipt/:paymentId` (extra: `isNew`, true when opened straight after recording or confirming a payment). **Who** owner, manager, caretaker and the guest. **Reads** `v_receipt_detail` where `payment_id` = the route value. A confirmed payment has a receipt. If no row comes back, show the "not available" error state.

```
┌──────────────────────────────────────┐
│ ←  Receipt                           │  AppTopBar
├──────────────────────────────────────┤
│            (only when isNew)         │
│              ( ✓ )                   │  TickBadge 64
│         Payment recorded             │  title, centred
│                                      │
│  ┌──────────────────────────────────┐│  ReceiptPaper, margin 16
│  │ [logo 28] {PG name}   No. 000123 ││  header, padding 20
│  │ {address line, area, city}       ││
│  ◖┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄◗│  dashed divider with notches
│  │ Amount received                  ││
│  │ ₹6,500            ⎡Received⎤     ││  display + Stamp (rotated)
│  │ UPI, PhonePe                     ││  body
│  │ 12 Nov 2026                      ││  secondary
│  │ ──────────────────────────────── ││
│  │ From        {guest name}         ││  KeyValueRow
│  │ Room        Room 101, bed A      ││
│  │ Reference   {UTR}                ││  only if present
│  │ Date        12 Nov 2026          ││  receipt issue date
│  │ ──────────────────────────────── ││
│  │ Paid towards                     ││  label, muted, weight 600
│  │ Rent for Nov 2026        ₹6,500  ││
│  │ Advance credit             ₹500  ││  only if unallocated > 0
│  │ ──────────────────────────────── ││
│  │ Total                    ₹7,000  ││  heading
│  │       Issued through {appName}   ││  caption, centred
│  └──────────────────────────────────┘│
│  [          Share receipt         ]  │  primary, expand, padding 16
│  [             Done               ]  │  secondary (only when isNew)
└──────────────────────────────────────┘
```

**Build**
1. Background `ground`, scrolling body, padding 16 on the sides.
2. **Arrival block** (only when `isNew`): 24 above, `TickBadge` centred, 16 below it the title `receiptRecorded` (or `receiptConfirmed` when opened after confirming a payment), centred, 24 below that the paper. Not `isNew`: the paper starts 16 from the top.
3. **Paper entrance** (only when `isNew`): the `ReceiptPaper` slides up 12 dp while fading in over `AppMotion.base`, after the tick finishes drawing. One light haptic when the tick completes.
4. **Header** (padding 20): row with `logoMark` 28, 8 gap, PG name (`heading`, flexible, wraps); on the right "No. {number}" in `label` (the number padded to 6 digits). Under the PG name: address in `secondary` (line 1, area, city; skip empty parts, comma separated).
5. **Divider** between header and body, with the notches (see `ReceiptPaper`).
6. **Amount block** (padding 20): label `receiptAmountLabel` (`secondary`); the amount in `display` via `Money`; right side: the `Stamp`. Under the amount: method line in `body` (`method_label`, and `, {payer_app_label}` if present), then the date in `secondary` (`paid_on`).
7. **Stamp** by status: `confirmed` gives `receiptStampReceived` in `paidFg`; `reversed` gives `receiptStampReversed` in `overdueFg`, and under the date a line `receiptReversedReason` in `secondary`. Stamp placement: right-aligned, vertically centred on the amount.
8. **Key-value rows** (inside the paper, no extra side padding): From = `guest_name`; Room = `Room {room_number}, bed {bed_label}` (hide the row if the room is not available; guests lose access to the room after they leave); Reference = `utr` (hide if empty); Date = `issued_at` date.
9. **Paid towards:** label, then one row per entry of `allocations` (description left, `Money` right). If `unallocated_paise` is above zero, add a row `receiptAdvance` with that amount. A hairline, then the Total row (`heading`) showing `amount_paise`.
10. **Footer:** `receiptFooter` in `caption`, centred, 20 padding.
11. **Actions** (below the paper, 24 gap): primary "Share receipt" with the `share` icon (expand). When `isNew`, a secondary "Done" below (12 gap) that pops back to where the user came from.
12. **Share:** wrap the `ReceiptPaper` in a `RepaintBoundary`, render at pixel ratio 3 onto a `ground` background with 16 padding, save as PNG in the temporary directory and open the system share sheet (`share_plus`) with the text `receiptShareText`.
13. Never use fake receipt content, in the gallery or anywhere else.

**States** loading (a paper-shaped skeleton: three `SkeletonBlock`s inside a `ReceiptPaper`), not available (`EmptyState`, no button), error (`ErrorState`).

**Copy**

| Key | Text |
|---|---|
| `receiptTitle` | Receipt |
| `receiptNo` | No. {number} |
| `receiptAmountLabel` | Amount received |
| `receiptFrom` | From |
| `receiptRoom` | Room |
| `receiptReference` | Reference |
| `receiptDate` | Date |
| `receiptPaidTowards` | Paid towards |
| `receiptAdvance` | Advance credit |
| `receiptTotal` | Total |
| `receiptStampReceived` | Received |
| `receiptStampReversed` | Reversed |
| `receiptReversedReason` | Reversed: {reason} |
| `receiptFooter` | Issued through {appName} |
| `receiptShare` | Share receipt |
| `receiptShareText` | Receipt {number} from {pg} |
| `receiptUnavailableTitle` | This receipt isn't available |
| `receiptUnavailableBody` | It may not be confirmed yet, or you may not have access to it. |

---

## S2. Profile

**Route** `/profile` (owner: pushed from More; guest: third tab). **Reads** the signed-in person (`persons` where `id` = me, from `rpc_my_context`), `emergency_contacts`, `person_documents`, and for guests `v_guest_list` where `person_id` = me and the stay is open.

```
┌──────────────────────────────────────┐
│ ←  Profile                           │  (no back arrow when it is a tab)
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │  LedgerSheet, padding 16
│ │ (avatar 72)  {name}              │ │  title
│ │              +91 98765 43210 🔒  │ │  secondary + lock icon 16
│ └──────────────────────────────────┘ │
│  Your details                        │  SectionHeader
│ ┌──────────────────────────────────┐ │
│ │ Name                {name}     > │ │  LedgerRow, tap to edit
│ │ Email           {email or Add} > │ │
│ │ Mobile number   {phone}       🔒 │ │  not tappable
│ └──────────────────────────────────┘ │
│  Emergency contacts                  │  (only if the person has a stay)
│ ┌──────────────────────────────────┐ │
│ │ {name}   {relation}, {phone}   > │ │
│ │ + Add a contact                  │ │
│ └──────────────────────────────────┘ │
│  ID documents                        │  (only if the person has a stay)
│ ┌──────────────────────────────────┐ │
│ │ {type}   ends {last4}          > │ │
│ │ + Add a document                 │ │
│ └──────────────────────────────────┘ │
│  Your stay                           │  (guests with an open stay)
│ ┌──────────────────────────────────┐ │  KeyValueRows, each with a lock icon
│ │ Room            Room 101, bed A  │ │
│ │ Monthly rent    ₹6,500           │ │
│ │ Rent due on     Day 12 of month  │ │
│ │ Joined          3 Jun 2026       │ │
│ └──────────────────────────────────┘ │
│  Set by your PG owner.               │  secondary, padding 16
│                                      │
│  [ Switch to owner view ]            │  secondary button (only if the person works in a PG)
│            Sign out                  │  text button, destructive colour text
└──────────────────────────────────────┘
```

**Build**
1. Background `ground`. Sheets stacked with 12 gaps and `SectionHeader`s as shown.
2. **Header sheet:** `ProfileAvatar` 72 at the left, 16 gap, name (`title`, up to two lines) and the phone (`secondary`) with a `lock` icon 16 after it. If the name is empty, show `profileNoName` in `secondary`.
3. **Photo** (only when `AppFlags.uploadsEnabled` is true; otherwise the avatar is not tappable and nothing about photos is shown): tapping the avatar opens a bottom sheet with three rows: "Take a photo", "Choose from gallery", "Remove photo" (only if a photo exists). Use `image_picker`. Resize to at most 1080 px on the longest side, JPEG quality 80. Upload to the private bucket `profile-photos` at `{personId}/{uuid}.jpg`, insert a `files` row (`uploaded_by` = me) and update `persons.photo_file_id`. Show the new photo immediately.
4. **Name** and **Email** rows open a bottom sheet with one `AppTextField` and Save. Name is required. Email is optional and checked for a plausible format. Save updates `persons` (only `full_name`, `email` and `photo_file_id` may be changed).
5. **Mobile number** is shown with a `lock` icon and cannot be edited. A tap shows the snackbar `phoneLocked`.
6. **Emergency contacts:** each row shows name (`bodyMedium`) and `{relation}, {phone}` (`secondary`). A tap opens the contact sheet. The last row is "Add a contact" with a `plus` icon in `petrol`. Contact sheet fields: Name (required), Relationship (`SelectField` from `relationship_types`), Mobile number (`PhoneField`, required), and a `SwitchRow` "Primary contact". In edit mode show a destructive `.text` button "Remove contact". Writes go to `emergency_contacts`.
7. **ID documents:** each row shows the type label and `ends {last4}`. The "Add a document" sheet has: Document type (`SelectField` from `document_types`), "Last 4 characters of the number" (`AppTextField`, 1 to 4 letters or digits, helper `documentLast4Helper`), and an optional photo (only when `AppFlags.uploadsEnabled` is true; picked with `image_picker`, uploaded to the private bucket `documents`). **Never ask for or store a full ID number.**
8. **Your stay** appears only for a guest with an open stay: `KeyValueRow`s with a `lock` icon each: Room (from `room_number` and `bed_label`; hide if missing), Monthly rent (`monthly_rent_paise`), Rent due on (`profileDueDay`), Joined (`join_date`). Under the sheet, `readOnlyHelper` in `secondary` with 16 padding.
9. **Switch view:** if the person works in at least one PG and has at least one stay, show a secondary button "Switch to owner view" (when in guest mode) or "Switch to guest view" (in owner mode). It stores the last view and navigates to the other shell.
10. **Sign out:** `.text` button with `overdueFg` text, centred. Opens a `ConfirmSheet` ("Sign out of {appName}?") with the primary action "Sign out".
11. Owners and managers see only the header and "Your details" sections plus the sign-out controls; the emergency contacts, ID documents and "Your stay" sections appear only for people who have a stay.

**States** loading skeleton rows, error with retry. Saving shows the button loading state in the sheet.

**Copy**

| Key | Text |
|---|---|
| `profileTitle` | Profile |
| `profileNoName` | Add your name |
| `profileDetails` | Your details |
| `profileName` | Name |
| `profileEmail` | Email |
| `profileEmailAdd` | Add |
| `profileMobile` | Mobile number |
| `phoneLocked` | Your mobile number can't be changed here. |
| `photoTake` | Take a photo |
| `photoChoose` | Choose from gallery |
| `photoRemove` | Remove photo |
| `emergencyContacts` | Emergency contacts |
| `emergencyAdd` | Add a contact |
| `emergencyName` | Name |
| `emergencyRelationship` | Relationship |
| `emergencyMobile` | Mobile number |
| `emergencyPrimary` | Primary contact |
| `emergencyRemove` | Remove contact |
| `documents` | ID documents |
| `documentAdd` | Add a document |
| `documentType` | Document type |
| `documentLast4` | Last 4 characters of the number |
| `documentLast4Helper` | We only store the last 4 characters. |
| `documentEnds` | ends {last4} |
| `documentPhoto` | Photo of the document (optional) |
| `profileStay` | Your stay |
| `profileRoom` | Room |
| `profileRent` | Monthly rent |
| `profileDueLabel` | Rent due on |
| `profileJoined` | Joined |
| `switchToOwner` | Switch to owner view |
| `switchToGuest` | Switch to guest view |
| `signOutTitle` | Sign out of {appName}? |
| `emailInvalid` | Enter a valid email address. |
| `nameRequired` | Enter your name. |

---

## S3. Notifications

**Route** `/notifications`. **Reads** `notifications` where `person_id` = me, newest first, 50 at a time (load more at the end of the list). **Writes** `status` and `read_at` when a row is opened.

```
┌──────────────────────────────────────┐
│ ←  Notifications                     │
├──────────────────────────────────────┤
│ ┌──────────────────────────────────┐ │  LedgerSheet
│ │ ● {title}                 2 h ago│ │  unread: petrol dot 8 + title weight 600
│ │   {body, up to 2 lines}          │ │  secondary
│ │ ──────────────────────────────── │ │
│ │   {title}                 Yesterday
│ │   {body}                         │ │
│ └──────────────────────────────────┘ │
└──────────────────────────────────────┘
```

**Build**
1. Rows: no leading tile. Left of the title an 8 x 8 `petrol` dot for unread (read rows keep the 8 space empty so text aligns). Title `bodyMedium` (weight 600 when unread), body `secondary` (two lines), time on the right in `caption` using the relative format.
2. Tapping a row marks it read, then opens its target. A notification carries only a `stay_id`: `rent_reminder` opens the guest home (G1); `payment_reported` opens the guest detail (O6) for that stay, where the waiting payment is listed; `payment_confirmed` and `payment_rejected` open the guest's History (G4); other kinds simply stay in the inbox.
3. The bell icon in top bars shows an 8 x 8 `petrol` dot at its top-right corner when any unread notification exists.
4. Empty: `EmptyState` with the `bell` icon.

**Copy**

| Key | Text |
|---|---|
| `notificationsTitle` | Notifications |
| `notificationsEmptyTitle` | No notifications yet |
| `notificationsEmptyBody` | Reminders and payment updates show up here. |
