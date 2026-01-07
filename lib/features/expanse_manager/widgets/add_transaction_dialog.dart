// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/expanse_manager/providers/expanse_provider.dart';
import 'package:support_chat/models/expanse_model.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class AddTransactionDialog extends ConsumerStatefulWidget {
  final String type;
  final ExpanseModel? transaction;
  const AddTransactionDialog({super.key, required this.type, this.transaction});

  @override
  ConsumerState<AddTransactionDialog> createState() =>
      _AddTransactionDialogState();
}

class _AddTransactionDialogState extends ConsumerState<AddTransactionDialog> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.transaction != null) {
      amountController.text = widget.transaction!.amount.toString();
      descriptionController.text = widget.transaction!.description;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.transaction != null;
    return AlertDialog(
      backgroundColor: AppColors.fifthColor,
      title: Text(
        isEditing ? 'Edit ${widget.type}' : 'Add ${widget.type}',
        style: const TextStyle(color: Colors.white),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Amount',
              hintStyle: TextStyle(color: Colors.white70),
            ),
          ),
          TextField(
            controller: descriptionController,
            style: const TextStyle(color: Colors.white),
            decoration: const InputDecoration(
              hintText: 'Description',
              hintStyle: TextStyle(color: Colors.white70),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () async {
            final amount = double.tryParse(amountController.text);
            if (amount != null && amount > 0) {
              try {
                final selectedCategory = ref.read(selectedCategoryProvider);
                final service = ref.read(expanseServiceProvider);

                if (isEditing) {
                  final updatedTransaction = widget.transaction!.copyWith(
                    amount: amount,
                    category: selectedCategory,
                    description: descriptionController.text,
                  );
                  await service.updateTransaction(updatedTransaction);
                } else {
                  await service.addTransaction(
                    amount: amount,
                    category: selectedCategory,
                    description: descriptionController.text,
                    type: widget.type.toLowerCase(),
                  );
                }
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              }
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid amount')),
              );
            }
          },
          child: Text(isEditing ? 'Update' : 'Add'),
        ),
      ],
    );
  }
}
