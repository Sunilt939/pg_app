int naturalCompare(String a, String b) {
  final regex = RegExp(r'(\d+|\D+)');
  final matchesA = regex.allMatches(a).map((m) => m.group(0)!).toList();
  final matchesB = regex.allMatches(b).map((m) => m.group(0)!).toList();
  for (int i = 0; i < matchesA.length && i < matchesB.length; i++) {
    final partA = matchesA[i];
    final partB = matchesB[i];
    final numA = int.tryParse(partA);
    final numB = int.tryParse(partB);
    if (numA != null && numB != null) {
      final cmp = numA.compareTo(numB);
      if (cmp != 0) return cmp;
    } else {
      final cmp = partA.toLowerCase().compareTo(partB.toLowerCase());
      if (cmp != 0) return cmp;
    }
  }
  return matchesA.length.compareTo(matchesB.length);
}

