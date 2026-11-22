# Decisions and gaps

The AI adds one line per decision it had to make. Never delete lines.

## UI gaps (details the written design did not cover)

| Date | Page | What was missing | What was chosen |
|---|---|---|---|
| 2026-11-14 | F1 | Initial blank screen content | Minimal empty Scaffold with AppColors.ground background |
| 2026-11-17 | N1 | Bottom nav labels and tab placeholder titles | Added navHome, navGuests, navPayments, navMore, navHistory, navProfile and titles to app_en.arb using exact wording from design system |
| 2026-11-18 | O12 | More tab row before O11 is approved | Added "Rooms and beds" row under moreYourPg in OwnerMoreScreen routing to /owner/rooms/new until O11 rooms list is approved |
| 2026-11-20 | O12 | Set up floors and rooms wizard | Natural room sorting per floor; room setup kept in memory until final step calls rpc_add_room_layout; row in More tab opens /owner/rooms/setup |
| 2026-11-20 | O12b | Accessing Add a few rooms before O11 is approved | Added "Add rooms" row under moreYourPg in OwnerMoreScreen routing to /owner/rooms/new until O11 rooms list with plus button is approved |
| 2026-11-20 | O11 | More tab transition to O11 rooms list | Replaced temporary setup/new rows in More tab with single "Rooms and beds" row opening /owner/rooms; empty state links to O12 and top bar plus links to O12b |
| 2026-11-22 | O14 | Empty last 4 digits in bank account subtitle | Display bank name alone when account_last4 is null or empty, omitting ", ending " |
| 2026-11-22 | O14 | Deactivating default receiving account | Automatically unsets default, disables "Use as default" switch when inactive, and reassigns default to the oldest active account of the PG (or none if only one account) |
| 2026-11-22 | O5 | Navigation after adding guest before O6 is approved | Pop back to previous screen upon closing InviteSheet until O6 (Guest detail) is approved |
| 2026-11-22 | O5 | Alert on duplicate guest stay error | Show floating snackbar (AppSnack) in addition to field error on DuplicateGuestStayException |
| 2026-11-22 | O5 | Past joining date notice | Display non-error muted notice under joining date when selected date is in the past |

## Other decisions

| Date | Decision | Why |
|---|---|---|
| 2026-11-15 | Used standard IconData referencing phosphor_flutter font assets in AppIcons | Modern Flutter made IconData a final class, preventing subclassing |
| 2026-11-16 | ReceiptPaper divider notches drawn via CustomPainter with AppColors.ground | Reusable without needing complex clipped path shaders or image assets |
| 2026-11-16 | TickBadge check stroke animated with path metrics extraction | Allows single-pass vector check animation without third-party Lottie |
| 2026-11-16 | OtpField uses transparent overlay TextField with 6 styled containers | Full platform accessibility and paste support while keeping strict passbook design |
| 2026-11-17 | Added captionBold (12/16, weight 600) to AppText | Used for chips, bottom nav badge counters, and active labels without hardcoding weights |
| 2026-11-17 | Used GoRouter StatefulShellRoute.indexedStack for Owner and Guest shells | Preserves tab scroll states and handles independent tab branch navigation cleanly |
