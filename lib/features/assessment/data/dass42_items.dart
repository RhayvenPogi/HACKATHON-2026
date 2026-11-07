/// OFFICIAL DASS-42 CONTENT.
///
/// Replace every placeholder with the EXACT wording from your authorized
/// source. Do not paraphrase. Order matters: index 0 = item 1.
///
/// When replacing, switch to literal const lists, e.g.
/// ```dart
/// const List<String> dass42Items = [
///   'official item 1 wording',
///   ...
/// ];
/// ```
library;

const String placeholderMarker = '[PLACEHOLDER]';

const String dass42Instructions =
    '$placeholderMarker Paste the official DASS-42 instructions here.';

final List<String> dass42Items = List<String>.unmodifiable(
  List<String>.generate(
    42,
    (i) => '$placeholderMarker Item ${i + 1}: paste the official wording.',
  ),
);

class Dass42Option {
  const Dass42Option(this.value, this.label);

  final int value;
  final String label;
}

const List<Dass42Option> dass42ResponseOptions = [
  Dass42Option(0, '$placeholderMarker Official label for 0'),
  Dass42Option(1, '$placeholderMarker Official label for 1'),
  Dass42Option(2, '$placeholderMarker Official label for 2'),
  Dass42Option(3, '$placeholderMarker Official label for 3'),
];

bool get dass42HasPlaceholders =>
    dass42Instructions.contains(placeholderMarker) ||
    dass42Items.any((item) => item.contains(placeholderMarker)) ||
    dass42ResponseOptions.any((o) => o.label.contains(placeholderMarker));