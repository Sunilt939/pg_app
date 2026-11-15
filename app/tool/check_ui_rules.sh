#!/usr/bin/env bash
# Run from the app folder: ./tool/check_ui_rules.sh
cd "$(dirname "$0")/.." || exit 1
fail=0
report() { echo "PROBLEM: $1"; echo "$2"; echo; fail=1; }

out=$(grep -rniE "lorem|dummy|sample|mock|fake|demo|john|test user" lib --include=*.dart | grep -v "^lib/dev/" | grep -v "app_localizations")
[ -n "$out" ] && report "words that suggest dummy data" "$out"

out=$(grep -rnE "Color\(0x|\bColors\.[a-zA-Z]" lib --include=*.dart | grep -v "^lib/core/theme/")
[ -n "$out" ] && report "colours outside lib/core/theme" "$out"

out=$(grep -rnE "(Text|SelectableText)\(\s*['\"]" lib --include=*.dart | grep -v "^lib/dev/")
[ -n "$out" ] && report "hard-coded text (use the ARB strings)" "$out"

out=$(grep -rnE "fontSize:|FontWeight\." lib --include=*.dart | grep -v "^lib/core/theme/")
[ -n "$out" ] && report "font sizes or weights outside lib/core/theme" "$out"

out=$(grep -rnE "\bCard\(|\bListTile\(|FloatingActionButton|ElevatedButton|FilledButton|\bNavigationBar\(|\bChip\(|AlertDialog\(" lib --include=*.dart | grep -v "^lib/dev/")
[ -n "$out" ] && report "default Material widgets that the design does not use" "$out"

out=$(grep -rnE "BoxShadow|LinearGradient" lib --include=*.dart | grep -v "^lib/core/widgets/receipt_paper.dart\|^lib/core/widgets/skeleton.dart")
[ -n "$out" ] && report "shadows or gradients outside the receipt and skeleton" "$out"

out=$(grep -rnE "₹ ?[0-9]|\+91 ?[0-9]{5}" lib --include=*.dart | grep -v "^lib/dev/\|^lib/core/format/")
[ -n "$out" ] && report "hard-coded money or phone numbers" "$out"

out=$(grep -rnE "assets/(images|brand)/" lib --include=*.dart | grep -v "^lib/core/assets/app_assets.dart")
[ -n "$out" ] && report "asset paths outside AppAssets" "$out"

[ $fail -eq 0 ] && echo "UI rules check: clean"
exit $fail
