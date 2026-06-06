import 'dart:math' as math;

import 'package:flutter/material.dart';

class EarningsDashboardPage extends StatelessWidget {
  const EarningsDashboardPage({super.key});

  static const _summary = EarningsSummary(
    totalEarnings: 'K1,250',
    completedErrands: 45,
    weeklyCompletedErrands: 6,
    rating: '4.8',
    acceptanceRate: '92%',
    completionRate: '98%',
    averageDeliveryTime: '18 min',
    trendData: [80, 120, 95, 160, 210, 185, 240],
  );

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 233, 233, 233),
      appBar: AppBar(
          title: const Text('Earnings'),
          leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back',
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor:const Color.fromARGB(255, 233, 233, 233),
        elevation: 0,
        centerTitle: true,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: theme.textTheme.titleLarge?.copyWith(
          color: const Color(0xFF111827),
          fontWeight: FontWeight.w800,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Earnings growth visualization.
              EarningsTrendChartWidget(values: _summary.trendData),
              const SizedBox(height: 18),

              // Main all-time earnings metric.
              StatCardWidget(
                label: 'Total Earnings',
                value: _summary.totalEarnings,
                subtitle: 'All-time earnings from completed errands',
                icon: Icons.payments_outlined,
                isPrimary: true,
              ),
              const SizedBox(height: 14),

              // Activity volume metric.
              StatCardWidget(
                label: 'Completed Errands',
                value: _summary.completedErrands.toString(),
                subtitle: '+${_summary.weeklyCompletedErrands} this week',
                icon: Icons.task_alt_outlined,
              ),
              const SizedBox(height: 14),

              // Quality and progression summary.
              PerformanceSummaryCard(summary: _summary),
            ],
          ),
        ),
      ),
    );
  }
}

class EarningsSummary {
  const EarningsSummary({
    required this.totalEarnings,
    required this.completedErrands,
    required this.weeklyCompletedErrands,
    required this.rating,
    required this.acceptanceRate,
    required this.completionRate,
    required this.averageDeliveryTime,
    required this.trendData,
  });

  final String totalEarnings;
  final int completedErrands;
  final int weeklyCompletedErrands;
  final String rating;
  final String acceptanceRate;
  final String completionRate;
  final String averageDeliveryTime;
  final List<num> trendData;

  String get levelLabel {
    if (completedErrands <= 10) return 'Level 1 - New Runner';
    if (completedErrands <= 40) return 'Level 2 - Active Runner';
    return 'Level 3 - Elite Runner';
  }
}

class EarningsTrendChartWidget extends StatelessWidget {
  const EarningsTrendChartWidget({super.key, required this.values});

  final List<num> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Earnings Chart',
            style: theme.textTheme.titleMedium?.copyWith(
              color: const Color(0xFF111827),
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 132,
            child: CustomPaint(
              painter: _EarningsTrendPainter(
                values: values,
                lineColor: theme.colorScheme.primary,
                gridColor: const Color(0xFFE5E7EB),
              ),
              size: Size.infinite,
            ),
          ),
          const SizedBox(height: 12),
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ChartDayLabel(label: 'Mon'),
              _ChartDayLabel(label: 'Tue'),
              _ChartDayLabel(label: 'Wed'),
              _ChartDayLabel(label: 'Thu'),
              _ChartDayLabel(label: 'Fri'),
              _ChartDayLabel(label: 'Sat'),
              _ChartDayLabel(label: 'Sun'),
            ],
          ),
        ],
      ),
    );
  }
}

class StatCardWidget extends StatelessWidget {
  const StatCardWidget({
    super.key,
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    this.isPrimary = false,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final bool isPrimary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final background = isPrimary ? const Color(0xFF111827) : const Color.fromARGB(255, 165, 165, 165);
    final foreground = isPrimary ? Colors.white : const Color(0xFF111827);
    final muted = isPrimary ? const Color.fromARGB(255, 255, 255, 255) : const Color(0xFF111827);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isPrimary ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color:
                  isPrimary ? const Color(0x1AFFFFFF) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: foreground),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  value,
                  style: theme.textTheme.headlineMedium?.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  subtitle,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: muted,
                    fontWeight: FontWeight.w600,
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

class PerformanceSummaryCard extends StatelessWidget {
  const PerformanceSummaryCard({super.key, required this.summary});

  final EarningsSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Performance Summary',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: const Color(0xFF111827),
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  summary.levelLabel,
                  style: const TextStyle(
                    color: Color(0xFF374151),
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _PerformanceRow(label: 'Rating', value: summary.rating),
          _PerformanceRow(
            label: 'Acceptance Rate',
            value: summary.acceptanceRate,
          ),
          _PerformanceRow(
            label: 'Completion Rate',
            value: summary.completionRate,
          ),
          _PerformanceRow(
            label: 'Average Delivery Time',
            value: summary.averageDeliveryTime,
            showDivider: false,
          ),
        ],
      ),
    );
  }
}

class _PerformanceRow extends StatelessWidget {
  const _PerformanceRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

  final String label;
  final String value;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF6B7280),
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Text(
              value,
              style: const TextStyle(
                color: Color(0xFF111827),
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        if (showDivider)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(height: 1, color: Color(0xFFE5E7EB)),
          ),
      ],
    );
  }
}

class _ChartDayLabel extends StatelessWidget {
  const _ChartDayLabel({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        color: Color(0xFF6B7280),
        fontSize: 11,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}

class _EarningsTrendPainter extends CustomPainter {
  const _EarningsTrendPainter({
    required this.values,
    required this.lineColor,
    required this.gridColor,
  });

  final List<num> values;
  final Color lineColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (values.length < 2) return;

    final gridPaint =
        Paint()
          ..color = gridColor
          ..strokeWidth = 1;
    final linePaint =
        Paint()
          ..color = lineColor
          ..strokeWidth = 3
          ..strokeCap = StrokeCap.round
          ..style = PaintingStyle.stroke;
    final pointPaint =
        Paint()
          ..color = lineColor
          ..style = PaintingStyle.fill;

    for (var i = 0; i < 4; i++) {
      final y = size.height * (i / 3);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final minValue = values.reduce(math.min).toDouble();
    final maxValue = values.reduce(math.max).toDouble();
    final range = math.max(maxValue - minValue, 1);
    final stepX = size.width / (values.length - 1);
    final path = Path();

    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i].toDouble() - minValue) / range;
      final y = size.height - (normalized * size.height);
      final point = Offset(x, y);

      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    for (var i = 0; i < values.length; i++) {
      final x = i * stepX;
      final normalized = (values[i].toDouble() - minValue) / range;
      final y = size.height - (normalized * size.height);
      canvas.drawCircle(Offset(x, y), 4, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _EarningsTrendPainter oldDelegate) {
    return oldDelegate.values != values ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.gridColor != gridColor;
  }
}
