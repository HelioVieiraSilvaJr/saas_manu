import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Gráfico de crescimento de tenants nos últimos 30 dias (linha).
class TenantGrowthChart extends StatelessWidget {
  final Map<DateTime, int> growthData;

  const TenantGrowthChart({super.key, required this.growthData});

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      padding: const EdgeInsets.all(DSSpacing.cardPaddingLg),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusLg),
        border: Border.all(color: colors.divider),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Crescimento de Tenants (30 dias)', style: textStyles.headline3),
          const SizedBox(height: DSSpacing.base),
          SizedBox(height: 200, child: _buildChart(colors, textStyles)),
        ],
      ),
    );
  }

  Widget _buildChart(DSColors colors, DSTextStyle textStyles) {
    if (growthData.isEmpty) {
      return Center(
        child: Text(
          'Sem dados no período',
          style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
        ),
      );
    }

    // Criar lista ordenada dos últimos 30 dias
    final now = DateTime.now();
    final spots = <FlSpot>[];
    final labels = <int, String>{};

    for (int i = 29; i >= 0; i--) {
      final day = DateTime(now.year, now.month, now.day - i);
      final count = growthData[day] ?? 0;
      final x = (29 - i).toDouble();
      spots.add(FlSpot(x, count.toDouble()));

      // Rótulos a cada 7 dias
      if (i % 7 == 0) {
        labels[29 - i] = DateFormat('dd/MM').format(day);
      }
    }

    final maxY = spots.map((s) => s.y).fold(0.0, (a, b) => a > b ? a : b);

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: colors.divider, strokeWidth: 1),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final label = labels[value.toInt()];
                if (label == null) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(top: DSSpacing.xs),
                  child: Text(
                    label,
                    style: textStyles.bodySmall.copyWith(
                      fontSize: 10,
                      color: colors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 30,
              interval: maxY > 0 ? (maxY / 4).ceilToDouble() : 1,
              getTitlesWidget: (value, meta) {
                return Text(
                  value.toInt().toString(),
                  style: textStyles.bodySmall.copyWith(
                    fontSize: 10,
                    color: colors.textTertiary,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 29,
        minY: 0,
        maxY: maxY > 0 ? maxY + 1 : 2,
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colors.secundaryColor,
            barWidth: 2,
            isStrokeCapRound: true,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colors.secundaryColor.withValues(alpha: 0.1),
            ),
          ),
        ],
      ),
    );
  }
}
