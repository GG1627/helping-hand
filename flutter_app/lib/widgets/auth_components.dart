import 'package:flutter/material.dart';

import '../theme/helping_hand_theme.dart';
import 'brand_components.dart';

class AuthStyles {
  static OutlineInputBorder _border(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: color, width: width),
      );

  static final inputTheme = InputDecorationTheme(
    filled: true,
    fillColor: HelpingHandColors.surface,
    floatingLabelBehavior: FloatingLabelBehavior.always,
    labelStyle: const TextStyle(color: HelpingHandColors.textSecondary),
    floatingLabelStyle: const TextStyle(
      color: HelpingHandColors.primary,
      fontWeight: FontWeight.w600,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
    border: _border(HelpingHandColors.outline),
    enabledBorder: _border(HelpingHandColors.outline),
    focusedBorder: _border(HelpingHandColors.primary, 2),
    errorBorder: _border(HelpingHandColors.error),
    focusedErrorBorder: _border(HelpingHandColors.error, 2),
    errorMaxLines: 4,
    helperStyle: const TextStyle(
      fontSize: 14,
      height: 1.4,
      color: HelpingHandColors.textSecondary,
    ),
    errorStyle: const TextStyle(
      fontSize: 14,
      height: 1.4,
      color: HelpingHandColors.error,
    ),
  );
}

class AuthBrandHeader extends StatelessWidget {
  const AuthBrandHeader({
    super.key,
    required this.createAccount,
    required this.wide,
  });
  final bool createAccount;
  final bool wide;

  @override
  Widget build(BuildContext context) {
    final centered = !createAccount && !wide;
    return ColoredBox(
      color: createAccount
          ? HelpingHandColors.secondary
          : HelpingHandColors.background,
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: wide ? 32 : 24,
          vertical: createAccount ? 24 : 40,
        ),
        child: Column(
          crossAxisAlignment: centered
              ? CrossAxisAlignment.center
              : CrossAxisAlignment.start,
          children: [
            HelpingHandWordmark(
              compact: createAccount && !wide,
              centered: centered,
            ),
            const SizedBox(height: 16),
            const HelpingHandBrandTrail(),
            if (!createAccount) ...[
              const SizedBox(height: 16),
              Text(
                'ASL practice, one sign at a time.',
                textAlign: centered ? TextAlign.center : TextAlign.left,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class AuthNotice extends StatelessWidget {
  const AuthNotice({
    super.key,
    required this.message,
    required this.icon,
    this.success = false,
    this.error = false,
  });
  final String message;
  final IconData icon;
  final bool success;
  final bool error;

  @override
  Widget build(BuildContext context) {
    final color = error
        ? HelpingHandColors.error
        : success
        ? HelpingHandColors.success
        : HelpingHandColors.primary;
    return Semantics(
      liveRegion: true,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: error
              ? HelpingHandColors.errorSurface
              : HelpingHandColors.secondary,
          border: Border(left: BorderSide(color: color, width: 3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(icon, size: 20, color: color)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: HelpingHandColors.textPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
