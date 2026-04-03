import 'package:flutter/material.dart';

import '../data/stock_repository.dart';
import '../models/app_models.dart';
import 'movements_screen.dart';
import 'products_screen.dart';
import 'sales_screen.dart';
import 'stock_action_screen.dart';
import 'stock_query_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key, required this.repo});

  final StockRepository repo;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  DashboardSummary? _summary;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final summary = await widget.repo.getDashboardSummary();
    if (!mounted) return;
    setState(() {
      _summary = summary;
      _loading = false;
    });
  }

  Future<void> _openPage(Widget page) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute<void>(builder: (_) => page),
    );
    if (mounted) {
      setState(() => _loading = true);
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;
    final width = MediaQuery.sizeOf(context).width;
    final horizontalPadding = width >= 1200 ? 32.0 : 20.0;
    final crossAxisCount = width >= 1300
        ? 3
        : width >= 850
            ? 2
            : 1;
    final actions = [
      _DashboardActionData(
        title: 'Urunler',
        subtitle: 'Ekle, duzenle ve sil',
        icon: Icons.inventory_2_rounded,
        accent: const Color(0xFF2563EB),
        onTap: () => _openPage(ProductsScreen(repo: widget.repo)),
      ),
      _DashboardActionData(
        title: 'Stok Girisi',
        subtitle: 'Yeni urun miktari ekle',
        icon: Icons.south_west_rounded,
        accent: const Color(0xFF059669),
        onTap: () => _openPage(
          StockActionScreen(
            repo: widget.repo,
            type: MovementType.stockIn,
          ),
        ),
      ),
      _DashboardActionData(
        title: 'Stok Cikisi',
        subtitle: 'Manuel stok dusumu yap',
        icon: Icons.north_east_rounded,
        accent: const Color(0xFFEA580C),
        onTap: () => _openPage(
          StockActionScreen(
            repo: widget.repo,
            type: MovementType.stockOut,
          ),
        ),
      ),
      _DashboardActionData(
        title: 'Stok Sorgulama',
        subtitle: 'Mevcut ve kritik stoklari gor',
        icon: Icons.manage_search_rounded,
        accent: const Color(0xFF7C3AED),
        onTap: () => _openPage(StockQueryScreen(repo: widget.repo)),
      ),
      _DashboardActionData(
        title: 'Hareket Gecmisi',
        subtitle: 'Tum giris, cikis ve satislar',
        icon: Icons.receipt_long_rounded,
        accent: const Color(0xFF0F766E),
        onTap: () => _openPage(MovementsScreen(repo: widget.repo)),
      ),
      _DashboardActionData(
        title: 'Satis Yap',
        subtitle: 'Satis kaydet ve PDF irsaliye olustur',
        icon: Icons.point_of_sale_rounded,
        accent: const Color(0xFFDC2626),
        onTap: () => _openPage(SalesScreen(repo: widget.repo)),
      ),
    ];

    return Scaffold(
      appBar: AppBar(toolbarHeight: 0),
      body: _loading && summary == null
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  24,
                  horizontalPadding,
                  28,
                ),
                children: [
                  Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF0F172A),
                          Color(0xFF1D4ED8),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x220F172A),
                          blurRadius: 30,
                          offset: Offset(0, 16),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(28),
                    child: Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      runSpacing: 18,
                      spacing: 18,
                      children: [
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 520),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text(
                                  'Stok Takip Dashboard',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 18),
                              const Text(
                                'Stok, satis ve hareketleri tek ekrandan yonet.',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  height: 1.2,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Buyuk aksiyon kartlariyla hizli islem yap, ozet rakamlari anlik takip et.',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                  fontSize: 15,
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.12),
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Canli Durum',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.72),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                '${summary?.productCount ?? 0} urun kayitli',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${(summary?.totalStock ?? 0).toStringAsFixed(2)} toplam stok',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.82),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = crossAxisCount == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - (16 * (crossAxisCount - 1))) /
                              crossAxisCount;
                      return Wrap(
                        spacing: 16,
                        runSpacing: 16,
                        children: [
                          _summaryCard(
                            title: 'Toplam Urun',
                            value: '${summary?.productCount ?? 0}',
                            icon: Icons.inventory_2_outlined,
                            accent: const Color(0xFF2563EB),
                            width: itemWidth,
                          ),
                          _summaryCard(
                            title: 'Toplam Stok',
                            value: (summary?.totalStock ?? 0).toStringAsFixed(2),
                            icon: Icons.stacked_bar_chart_rounded,
                            accent: const Color(0xFF059669),
                            width: itemWidth,
                          ),
                          _summaryCard(
                            title: 'Dusuk Stok',
                            value: '${summary?.lowStockCount ?? 0}',
                            icon: Icons.warning_amber_rounded,
                            accent: const Color(0xFFEA580C),
                            width: itemWidth,
                            warn: (summary?.lowStockCount ?? 0) > 0,
                          ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Hizli Islemler',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF111827),
                              ),
                        ),
                      ),
                      Text(
                        'Buton bazli dashboard',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: const Color(0xFF6B7280),
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  LayoutBuilder(
                    builder: (context, constraints) {
                      final itemWidth = crossAxisCount == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - (18 * (crossAxisCount - 1))) /
                              crossAxisCount;
                      return Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: [
                          for (final action in actions)
                            SizedBox(
                              width: itemWidth,
                              child: _DashboardActionCard(data: action),
                            ),
                        ],
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEFF6FF),
                              borderRadius: BorderRadius.circular(18),
                            ),
                            child: const Icon(
                              Icons.tips_and_updates_outlined,
                              color: Color(0xFF2563EB),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              'Ipucu: Kartlar genis ekranda grid yapisina gecer, masaustunde hover ve tiklama animasyonlariyla daha modern hisseder.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: const Color(0xFF4B5563),
                                  ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _summaryCard({
    required String title,
    required String value,
    required IconData icon,
    required Color accent,
    required double width,
    bool warn = false,
  }) {
    return SizedBox(
      width: width,
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: warn ? 0.18 : 0.10),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(icon, color: accent),
                  ),
                  const Spacer(),
                  if (warn)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFEDD5),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: const Text(
                        'Dikkat',
                        style: TextStyle(
                          color: Color(0xFF9A3412),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              Text(
                title,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: const Color(0xFF6B7280),
                      fontWeight: FontWeight.w600,
                    ),
              ),
              const SizedBox(height: 10),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF111827),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DashboardActionData {
  const _DashboardActionData({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
  final VoidCallback onTap;
}

class _DashboardActionCard extends StatefulWidget {
  const _DashboardActionCard({required this.data});

  final _DashboardActionData data;

  @override
  State<_DashboardActionCard> createState() => _DashboardActionCardState();
}

class _DashboardActionCardState extends State<_DashboardActionCard> {
  bool _hovering = false;
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final elevationShadow = _hovering
        ? const [
            BoxShadow(
              color: Color(0x1A2563EB),
              blurRadius: 28,
              offset: Offset(0, 14),
            ),
          ]
        : const [
            BoxShadow(
              color: Color(0x0F0F172A),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ];

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() {
        _hovering = false;
        _pressed = false;
      }),
      child: AnimatedScale(
        scale: _pressed
            ? 0.98
            : _hovering
                ? 1.015
                : 1,
        duration: const Duration(milliseconds: 140),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOutCubic,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white,
                widget.data.accent.withValues(alpha: 0.05),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: _hovering
                  ? widget.data.accent.withValues(alpha: 0.28)
                  : const Color(0xFFE5E7EB),
            ),
            boxShadow: elevationShadow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(28),
              onTap: widget.data.onTap,
              onTapDown: (_) => setState(() => _pressed = true),
              onTapCancel: () => setState(() => _pressed = false),
              onTapUp: (_) => setState(() => _pressed = false),
              child: Padding(
                padding: const EdgeInsets.all(22),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: widget.data.accent.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            widget.data.icon,
                            color: widget.data.accent,
                            size: 28,
                          ),
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _hovering
                                ? widget.data.accent.withValues(alpha: 0.12)
                                : const Color(0xFFF8FAFC),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Icon(
                            Icons.arrow_forward_rounded,
                            color: widget.data.accent,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),
                    Text(
                      widget.data.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF111827),
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.data.subtitle,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: const Color(0xFF6B7280),
                            height: 1.45,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
