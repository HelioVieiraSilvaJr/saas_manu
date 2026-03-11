import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../../Commons/Widgets/DesignSystem/DSColors.dart';
import '../../../Commons/Widgets/DesignSystem/DSSpacing.dart';
import '../../../Commons/Widgets/DesignSystem/DSTextStyle.dart';

/// Gráfico de distribuição de tenants por plano (Pizza).
class PlanDistributionChart extends StatelessWidget {
  final int trialCount;
  final int basicCount;
  final int fullCount;

  const PlanDistributionChart({
    super.key,
    required this.trialCount,
    required this.basicCount,
    required this.fullCount,
  });

  int get _total => trialCount + basicCount + fullCount;

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
                          value: basicCount.toDouble(),
                          title: '${_percentage(basicCount)}%',
                          color: colors.blue,
                          radius: 50,
                          titleStyle: textStyles.labelSmall.copyWith(
                            color: colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        PieChartSectionData(
                          value: fullCount.toDouble(),
                          title: '${_percentage(fullCount)}%',
                          color: colors.green,
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
                    _legendItem('Basic', basicCount, colors.blue, textStyles),
                    const SizedBox(height: DSSpacing.sm),
                    _legendItem('Full', fullCount, colors.green, textStyles),
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
