// ignore_for_file: use_build_context_synchronously

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/expanse_manager/providers/expanse_provider.dart';
import 'package:support_chat/utils/constants/app_colors.dart';

class AddCategoryDialog extends ConsumerStatefulWidget {
  final String type;
  const AddCategoryDialog({super.key, required this.type});

  @override
  ConsumerState<AddCategoryDialog> createState() => _AddCategoryDialogState();
}

class _AddCategoryDialogState extends ConsumerState<AddCategoryDialog> {
  final categoryController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: AppColors.fifthColor,
      title: Text(
        'Add ${widget.type} Category',
        style: const TextStyle(color: Colors.white),
      ),
      content: TextField(
        controller: categoryController,
        style: const TextStyle(color: Colors.white),
        decoration: const InputDecoration(
          hintText: 'Category Name',
          hintStyle: TextStyle(color: Colors.white70),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel', style: TextStyle(color: Colors.white)),
        ),
        ElevatedButton(
          onPressed: () async {
            if (categoryController.text.isNotEmpty) {
              try {
                await ref
                    .read(expanseServiceProvider)
                    .addCategory(categoryController.text, widget.type);
                ref.read(selectedCategoryProvider.notifier).state =
                    categoryController.text;
                if (mounted) Navigator.pop(context);
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error adding category: $e')),
                  );
                }
              }
            }
          },
          child: const Text('Add'),
        ),
      ],
    );
  }
}
