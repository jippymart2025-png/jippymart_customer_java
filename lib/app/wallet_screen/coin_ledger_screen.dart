import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import 'package:jippymart_customer/constant/constant.dart';
import 'package:jippymart_customer/models/coin_ledger_model.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';
import 'package:jippymart_customer/app/wallet_screen/provider/wallet_provider.dart';

// ── Top-level helpers (no `this` needed) ─────────────────────────
bool _isSameDay(DateTime? a, DateTime? b) {
  if (a == null || b == null) return false;
  return a.year == b.year && a.month == b.month && a.day == b.day;
}

// Pre-computed const shadows — never rebuilt
const _cardShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 24, offset: Offset(0, 8)),
];
const _tileShadow = [
  BoxShadow(color: Color(0x0A000000), blurRadius: 10, offset: Offset(0, 2)),
];
const _appBarIconShadow = [
  BoxShadow(color: Color(0x0F000000), blurRadius: 8, offset: Offset(0, 2)),
];

// ─────────────────────────────────────────────────────────────────
class CoinLedgerScreen extends StatefulWidget {
  const CoinLedgerScreen({super.key});

  @override
  State<CoinLedgerScreen> createState() => _CoinLedgerScreenState();
}

class _CoinLedgerScreenState extends State<CoinLedgerScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) context.read<WalletProvider>().refreshCoinLedger();
    });
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FB),
      appBar: _buildAppBar(),
      body: Consumer<WalletProvider>(
        builder: (context, wp, _) {
          if (wp.loadingLedger && wp.coinLedger.isEmpty) {
            return _buildLoadingState();
          }
          final list = wp.coinLedger;
          if (list.isEmpty) return _buildEmptyState();

          return FadeTransition(
            opacity: _fadeAnim,
            child: RefreshIndicator(
              color: AppThemeData.primary300,
              onRefresh: wp.refreshCoinLedger,
              child: CustomScrollView(
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      // Stats now come from provider getters — no fold() here
                      child: _SummaryCard(
                        totalEarned: wp.totalCoinsEarned,
                        totalSpent: wp.totalCoinsSpent.abs(),
                        totalTx: list.length,
                      ),
                    ),
                  ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Text(
                        'Transaction History'.tr,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF1A1A2E),
                          letterSpacing: -0.2,
                        ),
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    sliver: SliverList(
                      delegate: SliverChildBuilderDelegate((context, i) {
                        final showDateHeader =
                            i == 0 ||
                            !_isSameDay(
                              list[i].createdAt,
                              list[i - 1].createdAt,
                            );
                        // RepaintBoundary isolates each tile's repaint
                        return RepaintBoundary(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (showDateHeader)
                                _DateHeader(date: list[i].createdAt),
                              _LedgerTile(entry: list[i]),
                            ],
                          ),
                        );
                      }, childCount: list.length),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: const Color(0xFFF8F9FB),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      leading: IconButton(
        icon: Container(
          width: 38,
          height: 38,
          decoration: const BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: _appBarIconShadow,
          ),
          child: const Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 16,
            color: Color(0xFF1A1A2E),
          ),
        ),
        onPressed: () => Get.back(),
      ),
      title: Text(
        'Coin History'.tr,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: Color(0xFF1A1A2E),
          letterSpacing: -0.3,
        ),
      ),
      centerTitle: true,
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: Container(
            width: 38,
            height: 38,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: _appBarIconShadow,
            ),
            child: const Icon(
              Icons.toll_rounded,
              size: 18,
              color: Color(0xFFFFB800),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(
            color: AppThemeData.primary300,
            strokeWidth: 2.5,
          ),
          const SizedBox(height: 14),
          Text(
            'Loading history...'.tr,
            style: const TextStyle(fontSize: 13, color: Color(0xFF9CA3AF)),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: const BoxDecoration(
              color: Color(0xFFFFFBEB),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.toll_outlined,
              size: 36,
              color: Color(0xFFFFB800),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'No coin history yet',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1A1A2E),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Earn coins by placing orders,\nreferring friends & daily check-ins.'
                .tr,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: Color(0xFF9CA3AF),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────
class _SummaryCard extends StatelessWidget {
  final int totalEarned;
  final int totalSpent;
  final int totalTx;

  const _SummaryCard({
    required this.totalEarned,
    required this.totalSpent,
    required this.totalTx,
  });

  // Const decoration — built once
  static const _gradient = LinearGradient(
    colors: [Color(0xFF1A1A2E), Color(0xFF16213E), Color(0xFF0F3460)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: _gradient,
        boxShadow: cardShadow,
      ),
      child: Stack(
        children: [
          // Decorative circles — const, never rebuilt
          Positioned(
            top: -24,
            right: -24,
            child: Container(
              width: 110,
              height: 110,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.04),
              ),
            ),
          ),
          Positioned(
            bottom: -16,
            left: 40,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.03),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withOpacity(0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.toll_rounded,
                        size: 13,
                        color: Color(0xFFFFB800),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Coin Summary'.tr,
                        style: const TextStyle(
                          fontSize: 11,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _SummaryStatItem(
                        label: 'Earned'.tr,
                        value: '+$totalEarned',
                        color: const Color(0xFF4ADE80),
                        icon: Icons.arrow_downward_rounded,
                      ),
                      VerticalDivider(
                        color: Colors.white.withOpacity(0.12),
                        thickness: 1,
                        indent: 4,
                        endIndent: 4,
                      ),
                      _SummaryStatItem(
                        label: 'Spent'.tr,
                        value: '-$totalSpent',
                        color: const Color(0xFFFF6B6B),
                        icon: Icons.arrow_upward_rounded,
                      ),
                      VerticalDivider(
                        color: Colors.white.withOpacity(0.12),
                        thickness: 1,
                        indent: 4,
                        endIndent: 4,
                      ),
                      _SummaryStatItem(
                        label: 'Transactions'.tr,
                        value: '$totalTx',
                        color: const Color(0xFF93C5FD),
                        icon: Icons.receipt_long_rounded,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// Exposed so _SummaryCard can reference the top-level const
const cardShadow = _cardShadow;

class _SummaryStatItem extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const _SummaryStatItem({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: color,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.white54,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Date Header ───────────────────────────────────────────────────
class _DateHeader extends StatelessWidget {
  final DateTime? date;

  const _DateHeader({required this.date});

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));

    final String label;
    if (date!.year == now.year &&
        date!.month == now.month &&
        date!.day == now.day) {
      label = 'Today'.tr;
    } else if (date!.year == yesterday.year &&
        date!.month == yesterday.month &&
        date!.day == yesterday.day) {
      label = 'Yesterday'.tr;
    } else {
      label = DateFormat('MMMM d, yyyy').format(date!);
    }

    return Padding(
      padding: const EdgeInsets.only(top: 16, bottom: 8),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFF6B7280),
              letterSpacing: 0.3,
            ),
          ),
          const SizedBox(width: 8),
          const Expanded(
            child: DecoratedBox(
              decoration: BoxDecoration(
                // const — no allocation per build
                border: Border(
                  bottom: BorderSide(color: Color(0xFFE5E7EB), width: 1),
                ),
              ),
              child: SizedBox(height: 1),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Ledger Tile ───────────────────────────────────────────────────
class _LedgerTile extends StatelessWidget {
  const _LedgerTile({required this.entry});

  final CoinLedgerModel entry;

  // Static const map — allocated once for the entire app lifetime
  static const Map<String, _TileConfig> _configs = {
    'REFERRAL': _TileConfig(
      label: 'Referral Reward',
      icon: Icons.group_add_rounded,
      color: Color(0xFF7C3AED),
      bgColor: Color(0xFFF5F3FF),
    ),
    'ORDER_CREDIT': _TileConfig(
      label: 'Order Credit',
      icon: Icons.shopping_bag_rounded,
      color: Color(0xFF2563EB),
      bgColor: Color(0xFFEFF6FF),
    ),
    'CHECKIN': _TileConfig(
      label: 'Daily Check-in',
      icon: Icons.wb_sunny_rounded,
      color: Color(0xFFD97706),
      bgColor: Color(0xFFFFFBEB),
    ),
    'STREAK_BONUS': _TileConfig(
      label: 'Streak Bonus',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFEA4C1E),
      bgColor: Color(0xFFFFF4F0),
    ),
    'REDEEM_DEBIT': _TileConfig(
      label: 'Redeemed',
      icon: Icons.redeem_rounded,
      color: Color(0xFFDC2626),
      bgColor: Color(0xFFFFF1F2),
    ),
    'ADJUSTMENT': _TileConfig(
      label: 'Adjustment',
      icon: Icons.tune_rounded,
      color: Color(0xFF6B7280),
      bgColor: Color(0xFFF9FAFB),
    ),
  };

  String formatToIST(String? dateStr) {
    if (dateStr == null || dateStr.isEmpty) return '';

    final utcDate = DateTime.parse(dateStr + 'Z');
    final istDate = utcDate.toLocal();

    return DateFormat('HH:mm').format(istDate);
  }

  static const _defaultConfig = _TileConfig(
    label: 'Transaction',
    icon: Icons.toll_rounded,
    color: Color(0xFF6B7280),
    bgColor: Color(0xFFF9FAFB),
  );

  static const _creditBadgeDecoration = BoxDecoration(
    color: Color(0xFFF0FDF4),
    borderRadius: BorderRadius.all(Radius.circular(6)),
  );
  static const _debitBadgeDecoration = BoxDecoration(
    color: Color(0xFFFFF1F2),
    borderRadius: BorderRadius.all(Radius.circular(6)),
  );

  @override
  Widget build(BuildContext context) {
    final isCredit = (entry.coins ?? 0) >= 0;
    final config = _configs[(entry.type ?? '').toUpperCase()] ?? _defaultConfig;
    final date = entry.createdAt?.toLocal();

    final timeStr = date != null ? DateFormat('hh:mm a').format(date) : '';

    final coinColor = isCredit
        ? const Color(0xFF16A34A)
        : const Color(0xFFDC2626);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: _tileShadow,
      ),
      child: Row(
        children: [
          // Icon circle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: config.bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(config.icon, color: config.color, size: 20),
          ),
          const SizedBox(width: 12),

          // Label + time
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  // .tr on a const string — fine, GetX caches lookups
                  config.label.tr,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A2E),
                  ),
                ),
                if (timeStr.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    timeStr,
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Coin amount + badge
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.toll_rounded, size: 14, color: coinColor),
                  const SizedBox(width: 3),
                  Text(
                    '${isCredit ? "+" : ""}${entry.coins ?? 0}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: coinColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: isCredit
                    ? _creditBadgeDecoration
                    : _debitBadgeDecoration,
                child: Text(
                  isCredit ? 'Earned'.tr : 'Spent'.tr,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: coinColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Typed config — replaces Map<String, dynamic> ─────────────────
class _TileConfig {
  final String label;
  final IconData icon;
  final Color color;
  final Color bgColor;

  const _TileConfig({
    required this.label,
    required this.icon,
    required this.color,
    required this.bgColor,
  });
}
