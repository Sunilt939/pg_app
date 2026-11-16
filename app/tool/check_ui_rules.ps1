# tool/check_ui_rules.ps1
# Run from app/
$fail = 0

function Report($msg, $out) {
    Write-Host "PROBLEM: $msg" -ForegroundColor Red
    Write-Host $out
    $script:fail = 1
}

$out = git grep -nE "lorem|dummy|sample|mock|fake|demo|john|test user" -- "lib/*.dart" ":!lib/dev/*" ":!lib/core/l10n/*" 2>$null
if ($out) { Report "words that suggest dummy data" $out }

$out = git grep -nE "Color\(0x|\bColors\.[a-zA-Z]" -- "lib/*.dart" ":!lib/core/theme/*" 2>$null
if ($out) { Report "colours outside lib/core/theme" $out }

$out = git grep -nE "(Text|SelectableText)\(\s*['\`"]" -- "lib/*.dart" ":!lib/dev/*" 2>$null
if ($out) { Report "hard-coded strings in Text widgets" $out }

$out = git grep -nE "fontSize:|FontWeight\." -- "lib/*.dart" ":!lib/core/theme/*" 2>$null
if ($out) { Report "font sizes or weights outside lib/core/theme" $out }

$out = git grep -nE "\bCard\(|\bListTile\(|FloatingActionButton|ElevatedButton|FilledButton|\bNavigationBar\(|\bChip\(|AlertDialog\(" -- "lib/*.dart" ":!lib/dev/*" 2>$null
if ($out) { Report "default Material widgets that the design does not use" $out }

$out = git grep -nE "BoxShadow|LinearGradient" -- "lib/*.dart" ":!lib/core/widgets/receipt_paper.dart" ":!lib/core/widgets/skeleton.dart" 2>$null
if ($out) { Report "shadows or gradients outside the allowed components" $out }

$out = git grep -nE "₹ ?[0-9]|\+91 ?[0-9]{5}" -- "lib/*.dart" ":!lib/dev/*" ":!lib/core/format/*" 2>$null
if ($out) { Report "hard-coded money or phone numbers" $out }

$out = git grep -nE "[6-9][0-9]{4}\s*[0-9]{5}|[6-9][0-9]{9}" -- "lib/*.dart" ":!lib/dev/*" ":!lib/core/format/*" 2>$null
if ($out) { Report "real-looking mobile numbers" $out }

if ($fail -eq 0) {
    Write-Host "UI rules check: clean" -ForegroundColor Green
    exit 0
} else {
    exit 1
}

