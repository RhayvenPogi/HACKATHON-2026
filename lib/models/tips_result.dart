import 'package:muni_app/models/json_utils.dart';

class Tip {
  const Tip(this.title, this.body);

  final String title;
  final String body;
}

class TipsResult {
  const TipsResult({
    required this.label,
    required this.isAi,
    required this.tips,
  });

  factory TipsResult.fromJson(Map<String, dynamic> json) {
    final raw = json['tips'];
    if (raw is! List || raw.isEmpty) {
      throw const FormatException('Invalid "tips".');
    }
    final tips = raw.map((item) {
      if (item is! Map<String, dynamic>) {
        throw const FormatException('Invalid tip.');
      }
      return Tip(requireString(item, 'title'), requireString(item, 'body'));
    }).toList();

    return TipsResult(
      label: requireString(json, 'label'),
      isAi: json['source'] == 'ai',
      tips: List<Tip>.unmodifiable(tips),
    );
  }

  final String label;
  final bool isAi;
  final List<Tip> tips;
}