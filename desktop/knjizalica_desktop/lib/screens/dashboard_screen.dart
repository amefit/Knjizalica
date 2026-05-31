import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../config/app_theme.dart';
import '../models/models.dart';
import '../providers/dashboard_provider.dart';
import '../widgets/data_table.dart';
import '../widgets/kpi_card.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();

    if (provider.isLoading && provider.data == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (provider.error != null && provider.data == null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ErrorBanner(message: provider.error!),
            ElevatedButton(
              onPressed: provider.load,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    final kpis = provider.data!.kpis;
    final charts = provider.data!.charts;

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (provider.error != null) ErrorBanner(message: provider.error!),
          LayoutBuilder(
            builder: (context, constraints) {
              final crossCount = constraints.maxWidth > 1100 ? 3 : constraints.maxWidth > 700 ? 2 : 1;
              return Column(
                children: [
                  GridView.count(
                    crossAxisCount: crossCount,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.6,
                    children: [
                      KpiCard(
                        title: 'Total Books',
                        value: kpis.totalBooks,
                        icon: Icons.menu_book_outlined,
                      ),
                      KpiCard(
                        title: 'Active Loans',
                        value: kpis.activeLoans,
                        icon: Icons.list_alt_outlined,
                      ),
                      KpiCard(
                        title: 'New Members (month)',
                        value: kpis.newMembersThisMonth,
                        icon: Icons.person_add_alt_1_outlined,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: constraints.maxWidth > 700 ? 2 : 1,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    mainAxisSpacing: 16,
                    crossAxisSpacing: 16,
                    childAspectRatio: 2.8,
                    children: [
                      KpiCard(
                        title: 'New Members (year)',
                        value: kpis.newMembersThisYear,
                        icon: Icons.person_add_alt_1_outlined,
                      ),
                      KpiCard(
                        title: 'Overdue Books',
                        value: kpis.overdueLoans,
                        icon: Icons.error_outline,
                        color: AppTheme.danger,
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _ChartCard(
                      title: 'Loans (last 7 days)',
                      child: _buildLineChart(charts.loansLast7Days),
                    ),
                    const SizedBox(height: 16),
                    _ChartCard(
                      title: 'Most Popular Genres',
                      child: _buildPieChart(charts.topGenres),
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    flex: 3,
                    child: _ChartCard(
                      title: 'Loans (last 7 days)',
                      child: _buildLineChart(charts.loansLast7Days),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    flex: 2,
                    child: _ChartCard(
                      title: 'Most Popular Genres',
                      child: _buildPieChart(charts.topGenres),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 900) {
                return Column(
                  children: [
                    _ChartCard(
                      title: 'Top Borrowed Books',
                      child: _buildHorizontalBarChart(charts.topBorrowedBooks),
                    ),
                    const SizedBox(height: 16),
                    const _RecentReservationsTable(),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: _ChartCard(
                      title: 'Top Borrowed Books',
                      child: _buildHorizontalBarChart(charts.topBorrowedBooks),
                    ),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: _RecentReservationsTable(),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLineChart(List<ChartDataPoint> points) {
    if (points.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: AppTheme.textSecondary)));
    }
    final maxY = points.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 220,
      child: LineChart(
        LineChartData(
          minY: 0,
          maxY: maxY == 0 ? 5 : maxY * 1.2,
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) => const FlLine(color: AppTheme.border, strokeWidth: 1),
          ),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 28)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      points[index].label,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          lineBarsData: [
            LineChartBarData(
              spots: List.generate(
                points.length,
                (i) => FlSpot(i.toDouble(), points[i].value.toDouble()),
              ),
              isCurved: true,
              color: AppTheme.primary,
              barWidth: 3,
              belowBarData: BarAreaData(
                show: true,
                color: AppTheme.primary.withValues(alpha: 0.08),
              ),
              dotData: const FlDotData(show: true),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<ChartDataPoint> points) {
    if (points.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: AppTheme.textSecondary)));
    }
    final maxY = points.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return SizedBox(
      height: 220,
      child: BarChart(
        BarChartData(
          maxY: maxY == 0 ? 5 : maxY * 1.2,
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          titlesData: FlTitlesData(
            leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: true, reservedSize: 32)),
            topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 28,
                getTitlesWidget: (value, meta) {
                  final index = value.toInt();
                  if (index < 0 || index >= points.length) return const SizedBox.shrink();
                  final label = points[index].label;
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      label.length > 7 ? label.substring(5) : label,
                      style: const TextStyle(fontSize: 10, color: AppTheme.textSecondary),
                    ),
                  );
                },
              ),
            ),
          ),
          barGroups: List.generate(points.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: points[i].value.toDouble(),
                  color: AppTheme.primary,
                  width: 16,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }

  Widget _buildPieChart(List<ChartDataPoint> points) {
    if (points.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: AppTheme.textSecondary)));
    }
    final colors = [
      const Color(0xFF111111),
      const Color(0xFF4B5563),
      const Color(0xFF9CA3AF),
      const Color(0xFFD1D5DB),
      const Color(0xFFE5E7EB),
      const Color(0xFFF3F4F6),
    ];
    return SizedBox(
      height: 220,
      child: Row(
        children: [
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 40,
                sections: List.generate(points.length, (i) {
                  return PieChartSectionData(
                    value: points[i].value.toDouble(),
                    title: '${points[i].value}',
                    color: colors[i % colors.length],
                    radius: 50,
                    titleStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  );
                }),
              ),
            ),
          ),
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: List.generate(points.length, (i) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      points[i].label,
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildHorizontalBarChart(List<ChartDataPoint> points) {
    if (points.isEmpty) {
      return const Center(child: Text('No data', style: TextStyle(color: AppTheme.textSecondary)));
    }
    final maxVal = points.map((e) => e.value).fold<int>(0, (a, b) => a > b ? a : b).toDouble();
    return Column(
      children: List.generate(points.length, (i) {
        final value = points[i].value;
        final label = points[i].label;
        final fraction = maxVal == 0 ? 0.0 : value / maxVal;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      label,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  Text('$value', style: const TextStyle(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 6),
              LinearProgressIndicator(
                value: fraction,
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
                backgroundColor: AppTheme.border,
                color: AppTheme.accent,
              ),
            ],
          ),
        );
      }),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            child,
          ],
        ),
      ),
    );
  }
}

class _RecentReservationsTable extends StatelessWidget {
  const _RecentReservationsTable();

  static const _dateFormat = 'MMM d, yyyy';

  Future<void> _confirm(BuildContext context, DashboardProvider provider, int id) async {
    try {
      await provider.confirmReservation(id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reservation confirmed.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e is ApiException ? e.message : 'Confirm failed.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DashboardProvider>(
      builder: (context, provider, _) {
        final reservations = provider.recentReservations;
        final confirming = provider.confirmingReservationIds;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Text(
                      'Recent Reservations',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                    const Spacer(),
                    Text(
                      '${reservations.length} pending',
                      style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (reservations.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text(
                        'No pending reservations',
                        style: TextStyle(color: AppTheme.textSecondary),
                      ),
                    ),
                  )
                else
                  ...reservations.map((r) {
                    final isConfirming = confirming.contains(r.id);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            flex: 5,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  r.bookTitle,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontWeight: FontWeight.w500),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  r.memberName,
                                  style: const TextStyle(
                                    color: AppTheme.textSecondary,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text(
                              '${DateFormat(_dateFormat).format(r.fromDate.toLocal())} – '
                              '${DateFormat(_dateFormat).format(r.toDate.toLocal())}',
                              textAlign: TextAlign.end,
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 72,
                            child: Align(
                              alignment: Alignment.centerRight,
                              child: isConfirming
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(strokeWidth: 2),
                                    )
                                  : TextButton(
                                      onPressed: () => _confirm(context, provider, r.id),
                                      style: TextButton.styleFrom(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 6,
                                        ),
                                        minimumSize: Size.zero,
                                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      ),
                                      child: const Text('Confirm'),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
