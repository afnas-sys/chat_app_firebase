// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/expanse_manager/providers/expanse_provider.dart';
import 'package:support_chat/features/expanse_manager/widgets/add_category_dialog.dart';
import 'package:support_chat/features/expanse_manager/widgets/add_transaction_dialog.dart';
import 'package:support_chat/features/expanse_manager/widgets/category_chip.dart';
import 'package:support_chat/models/expanse_model.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class TabContent extends ConsumerWidget {
  final String type;
  final double total;
  final List<ExpanseModel> list;

  const TabContent({
    super.key,
    required this.type,
    required this.total,
    required this.list,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(categoriesProvider(type));

    return Column(
      children: [
        Container(
          height: 150,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.05),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Center(
            child: Text(
              '₹ $total',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        categoriesAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: 20),
            child: CircularProgressIndicator(),
          ),
          error: (err, stack) => Text(
            'Category Error: $err',
            style: const TextStyle(color: Colors.red, fontSize: 10),
          ),
          data: (categories) {
            // Auto-select first chip if current selection is invalid for this tab
            if (categories.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                final currentSelection = ref.read(selectedCategoryProvider);
                if (!categories.contains(currentSelection)) {
                  ref.read(selectedCategoryProvider.notifier).state =
                      categories.first;
                }
              });
            }

            return SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ...categories.map(
                    (cat) => Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: CategoryChip(label: cat, type: type),
                    ),
                  ),
                  CategoryChip(
                    label: 'Other',
                    type: type,
                    isIcon: true,
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (context) => AddCategoryDialog(type: type),
                      );
                    },
                  ),
                ],
              ),
            );
          },
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.fifthColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AddTransactionDialog(type: type),
              );
            },
            child: Text(
              'Add $type',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.builder(
            itemCount: list.length,
            itemBuilder: (context, index) {
              final item = list[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.white.withOpacity(0.2),
                  child: Icon(
                    type == 'Income'
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: type == 'Income' ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  item.category,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                subtitle: Text(
                  item.description,
                  style: const TextStyle(color: Colors.white70),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '₹${item.amount}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      onSelected: (value) async {
                        if (value == 'edit') {
                          ref.read(selectedCategoryProvider.notifier).state =
                              item.category;
                          showDialog(
                            context: context,
                            builder: (context) => AddTransactionDialog(
                              type: type,
                              transaction: item,
                            ),
                          );
                        } else if (value == 'delete') {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: AppColors.fifthColor,
                              title: const Text(
                                'Delete',
                                style: TextStyle(color: Colors.white),
                              ),
                              content: const Text(
                                'Are you sure you want to delete this?',
                                style: TextStyle(color: Colors.white70),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(context, false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          );

                          if (confirmed == true) {
                            await ref
                                .read(expanseServiceProvider)
                                .deleteTransaction(item.id);
                          }
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(Icons.edit, size: 20),
                              SizedBox(width: 10),
                              Text('Edit'),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(Icons.delete, color: Colors.red, size: 20),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(color: Colors.red),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
