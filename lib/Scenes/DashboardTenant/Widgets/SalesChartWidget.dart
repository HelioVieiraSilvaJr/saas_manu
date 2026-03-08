import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../DashboardTenantRepository.dart';

/// Widget do gráfico de vendas dos últimos 7 dias.
///
/// Usa fl_chart para renderizar um LineChart responsivo.
class SalesChartWidget extends StatelessWidget {
  final List<DailySalesDTO> salesData;

  const SalesChartWidget({super.key, required this.salesData});

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    return Container(
      padding: const EdgeInsets.all(DSSpacing.base),
      decoration: BoxDecoration(
        color: colors.cardBackground,
        borderRadius: BorderRadius.circular(DSSpacing.radiusMd),
        border: Border.all(color: colors.divider),
        boxShadow: [
          BoxShadow(
            color: colors.shadowColor,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Título
          Text('Vendas dos Últimos 7 Dias', style: textStyles.headline3),
          const SizedBox(height: DSSpacing.base),

          // Gráfico
          SizedBox(
            height: 220,
            child: _hasAnyData
                ? _buildChart(colors, textStyles)
                : _buildEmptyChart(colors, textStyles),
          ),
        ],
      ),
    );
  }

  bool get _hasAnyData => salesData.any((d) => d.totalValue > 0);

  Widget _buildChart(DSColors colors, DSTextStyle textStyles) {
    final maxY = salesData
        .map((d) => d.totalValue)
        .reduce((a, b) => a > b ? a : b);
    final adjustedMaxY = maxY == 0 ? 100.0 : maxY * 1.2;

    return LineChart(
      LineChartData(
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: adjustedMaxY / 4,
          getDrawingHorizontalLine: (value) =>
              FlLine(color: colors.divider, strokeWidth: 0.8),
        ),
        titlesData: FlTitlesData(
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 55,
              interval: adjustedMaxY / 4,
              getTitlesWidget: (value, meta) {
                if (value == meta.max) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(right: DSSpacing.xs),
                  child: Text(
                    _formatAxisValue(value),
                    style: textStyles.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                    textAlign: TextAlign.right,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= salesData.length) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: DSSpacing.xs),
                  child: Text(
                    _dayLabel(salesData[index].date),
                    style: textStyles.caption.copyWith(
                      color: colors.textTertiary,
                    ),
                  ),
                );
              },
            ),
          ),
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        borderData: FlBorderData(show: false),
        minX: 0,
        maxX: 6,
        minY: 0,
        maxY: adjustedMaxY,
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colors.black.withValues(alpha: 0.8),
            tooltipRoundedRadius: DSSpacing.radiusSm,
            getTooltipItems: (spots) {
              return spots.map((spot) {
                final index = spot.x.toInt();
                final date = salesData[index].date;
                return LineTooltipItem(
                  '${DateFormat('dd/MM').format(date)}\nR\$ ${spot.y.toStringAsFixed(2)}',
                  TextStyle(
                    color: colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                );
              }).toList();
            },
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: List.generate(
              salesData.length,
              (i) => FlSpot(i.toDouble(), salesData[i].totalValue),
            ),
            isCurved: true,
            curveSmoothness: 0.3,
            color: colors.primaryColor,
            barWidth: 3,
            isStrokeCapRound: true,
            dotData: FlDotData(
              show: true,
              getDotPainter: (spot, percent, barData, index) =>
                  FlDotCirclePainter(
                    radius: 4,
                    color: colors.primaryColor,
                    strokeWidth: 2,
                    strokeColor: colors.white,
                  ),
            ),
            belowBarData: BarAreaData(
              show: true,
              color: colors.primaryColor.withValues(alpha: 0.08),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyChart(DSColors colors, DSTextStyle textStyles) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.show_chart_rounded,
            size: 48,
            color: colors.textTertiary.withValues(alpha: 0.5),
          ),
          const SizedBox(height: DSSpacing.sm),
          Text(
            'Você ainda não tem vendas registradas.',
            style: textStyles.bodyMedium.copyWith(color: colors.textTertiary),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  String _dayLabel(DateTime date) {
    const weekdays = ['Seg', 'Ter', 'Qua', 'Qui', 'Sex', 'Sáb', 'Dom'];
    return weekdays[date.weekday - 1];
  }

  String _formatAxisValue(double value) {
    if (value >= 1000) {
      return 'R\$ ${(value / 1000).toStringAsFixed(1)}k';
    }
    return 'R\$ ${value.toStringAsFixed(0)}';
  }
}
