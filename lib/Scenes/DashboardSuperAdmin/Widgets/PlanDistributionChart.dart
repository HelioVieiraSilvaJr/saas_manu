import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Gráfico de distribuição de tenants por plano (Pizza).
class PlanDistributionChart extends StatelessWidget {
  final int trialCount;
  final int monthlyStandardCount;
  final int monthlyProCount;
  final int quarterlyStandardCount;
  final int quarterlyProCount;

  const PlanDistributionChart({
    super.key,
    required this.trialCount,
    required this.monthlyStandardCount,
    required this.monthlyProCount,
    required this.quarterlyStandardCount,
    required this.quarterlyProCount,
  });

  int get _total =>
      trialCount +
      monthlyStandardCount +
      monthlyProCount +
      quarterlyStandardCount +
      quarterlyProCount;

  @override
  Widget build(BuildContext context) {
    final colors = DSColors();
    final textStyles = DSTextStyle();

    if (_total == 0) {
      return Center(
        child: Text(
          'Sem dados',
          style: textStyles.bodyMedium.copyWith(color: colors.textSecondary),
        ),
      );
    }

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
          Text('Distribuição por Plano', style: textStyles.headline3),
          const SizedBox(height: DSSpacing.base),
          SizedBox(
            height: 200,
            child: Row(
              children: [
                Expanded(
                  child: PieChart(
                    PieChartData(
                      sectionsSpace: 2,
                      centerSpaceRadius: 40,
                      sections: [
                        PieChartSectionData(
                          value: trialCount.toDouble(),
                          title: '${_percentage(trialCount)}%',
                          color: colors.orange,
                          radius: 50,
                          titleStyle: textStyles.labelSmall.copyWith(
                            color: colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: monthlyStandardCount.toDouble(),
                          title: '${_percentage(monthlyStandardCount)}%',
                          color: colors.blue,
                          radius: 50,
                          titleStyle: textStyles.labelSmall.copyWith(
                            color: colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: monthlyProCount.toDouble(),
                          title: '${_percentage(monthlyProCount)}%',
                          color: colors.primaryColor,
                          radius: 50,
                          titleStyle: textStyles.labelSmall.copyWith(
                            color: colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: quarterlyStandardCount.toDouble(),
                          title: '${_percentage(quarterlyStandardCount)}%',
                          color: colors.green,
                          radius: 50,
                          titleStyle: textStyles.labelSmall.copyWith(
                            color: colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: quarterlyProCount.toDouble(),
                          title: '${_percentage(quarterlyProCount)}%',
                          color: colors.secundaryDark,
                          radius: 50,
                          titleStyle: textStyles.labelSmall.copyWith(
                            color: colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: DSSpacing.base),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _legendItem('Trial', trialCount, colors.orange, textStyles),
                    const SizedBox(height: DSSpacing.sm),
                    _legendItem(
                      'Mensal',
                      monthlyStandardCount,
                      colors.blue,
                      textStyles,
                    ),
                    const SizedBox(height: DSSpacing.sm),
                    _legendItem(
                      'Mensal Pro',
                      monthlyProCount,
                      colors.primaryColor,
                      textStyles,
                    ),
                    const SizedBox(height: DSSpacing.sm),
                    _legendItem(
                      'Trimestral',
                      quarterlyStandardCount,
                      colors.green,
                      textStyles,
                    ),
                    const SizedBox(height: DSSpacing.sm),
                    _legendItem(
                      'Trimestral Pro',
                      quarterlyProCount,
                      colors.secundaryDark,
                      textStyles,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  int _percentage(int count) {
    if (_total == 0) return 0;
    return ((count / _total) * 100).round();
  }

  Widget _legendItem(
    String label,
    int count,
    Color color,
    DSTextStyle textStyles,
  ) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: DSSpacing.xs),
        Text('$label ($count)', style: textStyles.bodySmall),
      ],
    );
  }
}
