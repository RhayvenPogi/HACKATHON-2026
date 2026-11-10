import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:muni_app/core/services/api_service.dart';
import 'package:muni_app/models/tips_result.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

/// Topic keys must match the backend (tips/content.py).
const _topics = [
  ('sleep', 'Sleep'),
  ('stress', 'Stress'),
  ('worry', 'Worry'),
  ('low_mood', 'Low mood'),
  ('school_work', 'School or work'),
  ('relationships', 'Feeling lonely'),
];

class TipsCard extends StatefulWidget {
  const TipsCard({super.key});

  @override
  State<TipsCard> createState() => _TipsCardState();
}

class _TipsCardState extends State<TipsCard> {
  String? _topic;
  Future<TipsResult>? _future;

  void _choose(String key) {
    setState(() {
      _topic = key;
      _future = context.read<ApiService>().getTips(key);
    });
  }

  @override
  Widget build(BuildContext context) {
    const body = TextStyle(
      fontSize: 14,
      height: 1.5,
      fontWeight: FontWeight.w600,
      color: MuniColors.muted,
    );

    return MuniCard(
      radius: 24,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Self-care tips',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: MuniColors.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text('Pick a topic for a few general tips.', style: body),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final (key, label) in _topics)
                ChoiceChip(
                  label: Text(label),
                  selected: _topic == key,
                  onSelected: (_) => _choose(key),
                ),
            ],
          ),
          if (_future != null) ...[
            const SizedBox(height: 16),
            FutureBuilder<TipsResult>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Row(
                    children: [
                      SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Getting tips\u2026', style: body),
                    ],
                  );
                }
                if (snap.hasError || !snap.hasData) {
                  return const Text(
                    'Tips are not available right now. Please try again later.',
                    style: body,
                  );
                }
                final result = snap.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final tip in result.tips) ...[
                      Text(
                        tip.title,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: MuniColors.forest,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(tip.body, style: body),
                      const SizedBox(height: 10),
                    ],
                    Text(
                      result.isAi
                          ? 'AI-generated with Google Gemini. General tips '
                              'only, not medical advice.'
                          : 'General tips from Muni. Not medical advice.',
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                        color: MuniColors.muted,
                      ),
                    ),
                  ],
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}