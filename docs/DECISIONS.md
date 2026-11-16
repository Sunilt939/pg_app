# Decisions and gaps

The AI adds one line per decision it had to make. Never delete lines.

## UI gaps (details the written design did not cover)

| Date | Page | What was missing | What was chosen |
|---|---|---|---|
| 2026-11-14 | F1 | Initial blank screen content | Minimal empty Scaffold with AppColors.ground background |
| 2026-11-17 | N1 | Bottom nav labels and tab placeholder titles | Added navHome, navGuests, navPayments, navMore, navHistory, navProfile and titles to app_en.arb using exact wording from design system |

## Other decisions

| Date | Decision | Why |
|---|---|---|
| 2026-11-15 | Used standard IconData referencing phosphor_flutter font assets in AppIcons | Modern Flutter made IconData a final class, preventing subclassing |
| 2026-11-16 | ReceiptPaper divider notches drawn via CustomPainter with AppColors.ground | Reusable without needing complex clipped path shaders or image assets |
| 2026-11-16 | TickBadge check stroke animated with path metrics extraction | Allows single-pass vector check animation without third-party Lottie |
| 2026-11-16 | OtpField uses transparent overlay TextField with 6 styled containers | Full platform accessibility and paste support while keeping strict passbook design |
| 2026-11-17 | Added captionBold (12/16, weight 600) to AppText | Used for chips, bottom nav badge counters, and active labels without hardcoding weights |
| 2026-11-17 | Used GoRouter StatefulShellRoute.indexedStack for Owner and Guest shells | Preserves tab scroll states and handles independent tab branch navigation cleanly |
