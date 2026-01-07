// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/expanse_manager/providers/expanse_provider.dart';
import 'package:support_chat/utils/category_colors.dart';

class CategoryChip extends ConsumerWidget {
  final String label;
  final String type;
  final bool isIcon;
  final VoidCallback? onTap;

  const CategoryChip({
    super.key,
    required this.label,
    required this.type,
    this.isIcon = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (isIcon) {
      return GestureDetector(
        onTap: onTap,
        child: _buildChip(context, ref, isSelected: false),
      );
    }

    final selectedCategory = ref.watch(selectedCategoryProvider);
    bool isSelected = selectedCategory == label;

    return LongPressDraggable<Map<String, String>>(
      delay: const Duration(milliseconds: 400),
      data: {'name': label, 'type': type},
      onDragStarted: () {
        ref.read(isDraggingCategoryProvider.notifier).state = true;
      },
      onDragEnd: (details) {
        ref.read(isDraggingCategoryProvider.notifier).state = false;
      },
      onDraggableCanceled: (velocity, offset) {
        ref.read(isDraggingCategoryProvider.notifier).state = false;
      },
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 80,
          height: 40,
          child: Opacity(
            opacity: 0.7,
            child: _buildChip(context, ref, isSelected: isSelected),
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: _buildChip(context, ref, isSelected: isSelected),
      ),
      child: GestureDetector(
        onTap:
            onTap ??
            () {
              ref.read(selectedCategoryProvider.notifier).state = label;
            },
        child: _buildChip(context, ref, isSelected: isSelected),
      ),
    );
  }

  Widget _buildChip(
    BuildContext context,
    WidgetRef ref, {
    required bool isSelected,
  }) {
    final categoryColor = CategoryColors.getColor(label);

    return Container(
      height: 40,
      width: 80,
      decoration: BoxDecoration(
        color: isSelected ? categoryColor : categoryColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: isSelected ? Colors.white24 : categoryColor.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Center(
        child: isIcon
            ? Icon(
                Icons.add,
                color: isSelected ? Colors.white : categoryColor,
                size: 20,
              )
            : Text(
                label,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
              ),
      ),
    );
  }
}
