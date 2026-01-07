import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/expanse_manager/providers/expanse_provider.dart';
import 'package:support_chat/utils/category_colors.dart';

class AnalystView extends ConsumerWidget {
  const AnalystView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final transactionsAsync = ref.watch(transactionsProvider);

    return transactionsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, stack) => Center(child: Text('Error: $err')),
      data: (transactions) {
        Map<String, double> categoryData = {};
        double totalExpense = 0;

        for (var item in transactions) {
          if (item.type == 'expanses' || item.type == 'expense') {
            categoryData[item.category] =
                (categoryData[item.category] ?? 0) + item.amount;
            totalExpense += item.amount;
          }
        }

        if (totalExpense == 0) {
          return const Center(
            child: Text(
              'No expense data to analyze',
              style: TextStyle(color: Colors.white70),
            ),
          );
        }

        final List<PieChartSectionData> sections = [];

        categoryData.forEach((category, amount) {
          final percentage = (amount / totalExpense) * 100;
          sections.add(
            PieChartSectionData(
              color: CategoryColors.getColor(category),
              value: amount,
              title: '${percentage.toStringAsFixed(1)}%',
              radius: 50,
              titleStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        });

        return Column(
          children: [
            const Text(
              'Expense Breakdown',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              height: 200,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 40,
                  sectionsSpace: 2,
                ),
              ),
            ),
            const SizedBox(height: 30),
            Expanded(
              child: ListView(
                children: categoryData.entries.map((entry) {
                  return ListTile(
                    leading: Container(
                      width: 16,
                      height: 16,
                      decoration: BoxDecoration(
                        color: CategoryColors.getColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    title: Text(
                      entry.key,
                      style: const TextStyle(color: Colors.white),
                    ),
                    trailing: Text(
                      '₹${entry.value.toStringAsFixed(2)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}
