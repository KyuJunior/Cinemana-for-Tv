import 'package:flutter/material.dart';
import '../theme/tv_theme.dart';
import 'tv_focusable.dart';

class TVKeyboard extends StatefulWidget {
  final ValueChanged<String> onKeyPress;
  final VoidCallback onBackspace;
  final VoidCallback onClear;
  final VoidCallback onSearch;
  final VoidCallback? onNavigateLeft;

  const TVKeyboard({
    super.key,
    required this.onKeyPress,
    required this.onBackspace,
    required this.onClear,
    required this.onSearch,
    this.onNavigateLeft,
  });

  @override
  State<TVKeyboard> createState() => _TVKeyboardState();
}

class _TVKeyboardState extends State<TVKeyboard> {
  bool _isArabic = false;

  static const List<List<String>> _enKeys = [
    ['A', 'B', 'C', 'D', 'E', 'F', '1', '2', '3'],
    ['G', 'H', 'I', 'J', 'K', 'L', '4', '5', '6'],
    ['M', 'N', 'O', 'P', 'Q', 'R', '7', '8', '9'],
    ['S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', '0'],
  ];

  static const List<List<String>> _arKeys = [
    ['ا', 'ب', 'ت', 'ث', 'ج', 'ح', 'خ', 'د', 'ذ'],
    ['ر', 'ز', 'س', 'ش', 'ص', 'ض', 'ط', 'ظ', 'ع'],
    ['غ', 'ف', 'ق', 'ك', 'ل', 'م', 'ن', 'ه', 'و'],
    ['ي', 'ى', 'ة', 'ء', 'ئ', 'ؤ', '1', '2', '3'],
  ];

  @override
  Widget build(BuildContext context) {
    final currentKeys = _isArabic ? _arKeys : _enKeys;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var row in currentKeys)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < row.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: _buildKey(
                      label: row[i],
                      width: 44,
                      onKeyLeft: i == 0 ? widget.onNavigateLeft : null,
                      onPressed: () => widget.onKeyPress(_isArabic ? row[i] : row[i].toLowerCase()),
                    ),
                  ),
              ],
            ),
          ),
        const SizedBox(height: 4),
        // Action row: LANG (AR/EN), SPACE, DELETE, CLEAR, SEARCH
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildKey(
              label: _isArabic ? 'EN' : 'عربي',
              width: 56,
              icon: Icons.language_rounded,
              onKeyLeft: widget.onNavigateLeft,
              onPressed: () => setState(() => _isArabic = !_isArabic),
            ),
            const SizedBox(width: 6),
            _buildKey(
              label: 'SPACE',
              width: 114,
              icon: Icons.space_bar_rounded,
              onPressed: () => widget.onKeyPress(' '),
            ),
            const SizedBox(width: 6),
            _buildKey(
              label: 'DEL',
              width: 88,
              icon: Icons.backspace_outlined,
              onPressed: widget.onBackspace,
            ),
            const SizedBox(width: 6),
            _buildKey(
              label: 'CLR',
              width: 88,
              icon: Icons.clear_all_rounded,
              onPressed: widget.onClear,
            ),
            const SizedBox(width: 6),
            _buildKey(
              label: 'SEARCH',
              width: 90,
              icon: Icons.search_rounded,
              isPrimary: true,
              onPressed: widget.onSearch,
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKey({
    required String label,
    required double width,
    IconData? icon,
    bool isPrimary = false,
    VoidCallback? onKeyLeft,
    required VoidCallback onPressed,
  }) {
    return TVFocusable(
      scaleOnFocus: 1.12,
      borderRadius: BorderRadius.circular(8),
      onKeyLeft: onKeyLeft,
      onPressed: onPressed,
      builder: (context, isFocused) {
        return Container(
          width: width,
          height: 44,
          decoration: BoxDecoration(
            color: isFocused
                ? (isPrimary ? Colors.white : TVColors.cardFocused)
                : (isPrimary ? TVColors.accent : TVColors.card),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isFocused
                  ? (isPrimary ? Colors.white : TVColors.focusBorder)
                  : Colors.transparent,
              width: 2,
            ),
          ),
          child: Center(
            child: icon != null
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        icon,
                        size: 16,
                        color: isFocused
                            ? (isPrimary ? Colors.black : Colors.white)
                            : (isPrimary ? Colors.black : TVColors.textSecondary),
                      ),
                      if (label.isNotEmpty) ...[
                        const SizedBox(width: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: isFocused
                                ? (isPrimary ? Colors.black : Colors.white)
                                : (isPrimary ? Colors.black : TVColors.textSecondary),
                          ),
                        ),
                      ],
                    ],
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isFocused ? Colors.white : TVColors.textPrimary,
                    ),
                  ),
          ),
        );
      },
    );
  }
}
