import 'package:flutter/material.dart';
import 'package:muni_app/features/home/screens/user_home_screen.dart';
import 'package:muni_app/shared/widgets/muni_ui.dart';

/// Home + bottom nav. Pass your existing screens for the other three tabs.
class UserShell extends StatefulWidget {
  const UserShell({
    super.key,
    required this.checkIn,
    required this.help,
    required this.share,
    this.latestLabel,
    this.latestSub,
    this.onViewLatest,
  });

  final Widget checkIn;
  final Widget help;
  final Widget share;
  final String? latestLabel;
  final String? latestSub;
  final VoidCallback? onViewLatest;

  @override
  State<UserShell> createState() => _UserShellState();
}

class _UserShellState extends State<UserShell> {
  int _index = 0;

  void _go(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MuniColors.mint,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            UserHomeScreen(
              onStartCheckIn: () => _go(1),
              onFindHelp: () => _go(2),
              onShare: () => _go(3),
              latestLabel: widget.latestLabel,
              latestSub: widget.latestSub,
              onViewLatest: widget.onViewLatest,
            ),
            widget.checkIn,
            widget.help,
            widget.share,
          ],
        ),
      ),
      bottomNavigationBar: MuniBottomNav(index: _index, onTap: _go),
    );
  }
}