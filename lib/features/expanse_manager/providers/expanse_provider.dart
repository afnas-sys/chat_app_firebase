import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/models/expanse_model.dart';
import 'package:support_chat/services/expanse_service.dart';

final expanseServiceProvider = Provider((ref) => ExpanseService());

final transactionsProvider = StreamProvider<List<ExpanseModel>>((ref) {
  final service = ref.watch(expanseServiceProvider);
  return service.getTransactions();
});

final categoriesProvider = StreamProvider.family<List<String>, String>((
  ref,
  type,
) {
  final service = ref.watch(expanseServiceProvider);
  return service.getCategories(type);
});

final selectedCategoryProvider = StateProvider<String>((ref) => 'Food');

final isDraggingCategoryProvider = StateProvider<bool>((ref) => false);
