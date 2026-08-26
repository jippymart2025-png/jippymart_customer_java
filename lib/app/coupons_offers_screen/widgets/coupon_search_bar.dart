import 'package:flutter/material.dart';
import '../../Communityscreen/theme/app_theme.dart';

class CouponSearchBar extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onApply;

  const CouponSearchBar({
    super.key,
    required this.controller,
    required this.onApply,
  });

  @override
  State<CouponSearchBar> createState() => _CouponSearchBarState();
}

class _CouponSearchBarState extends State<CouponSearchBar> {
  final FocusNode _focusNode = FocusNode();
  bool _focused = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(
      () => setState(() => _focused = _focusNode.hasFocus),
    );
    widget.controller.addListener(_onTextChanged);
    _hasText = widget.controller.text.isNotEmpty;
  }

  void _onTextChanged() {
    final hasText = widget.controller.text.isNotEmpty;
    if (hasText != _hasText) setState(() => _hasText = hasText);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 60,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: _focused ? AppColors.primary : AppColors.border,
            width: _focused ? 1.6 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _focused
                  ? AppColors.primary.withOpacity(0.10)
                  : Colors.black.withOpacity(0.04),
              blurRadius: _focused ? 16 : 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const SizedBox(width: 16),
            Icon(
              Icons.local_offer_outlined,
              color: _focused ? AppColors.primary : AppColors.textMuted,
              size: 24,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: widget.controller,
                focusNode: _focusNode,
                textCapitalization: TextCapitalization.characters,
                onSubmitted: (_) => widget.onApply(),
                style: const TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                ),
                decoration: const InputDecoration(
                  hintText: 'Enter coupon code',
                  hintStyle: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textMuted,
                  ),
                  border: InputBorder.none,
                  isCollapsed: true,
                ),
              ),
            ),
            if (_hasText)
              IconButton(
                icon: const Icon(
                  Icons.close_rounded,
                  size: 18,
                  color: AppColors.textMuted,
                ),
                onPressed: () => widget.controller.clear(),
                splashRadius: 18,
              ),
            const SizedBox(width: 4),
            Padding(
              padding: const EdgeInsets.all(6),
              child: SizedBox(
                height: 46,
                width: 92,
                child: ElevatedButton(
                  onPressed: widget.onApply,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Apply',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
