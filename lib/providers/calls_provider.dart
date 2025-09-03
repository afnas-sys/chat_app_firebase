import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/utils/constants/app_image.dart';

final allCallProvider = Provider<List<Map<String, dynamic>>>((ref) {
  return [
    {
      "user": "Alice",
      "image": AppImage.user1,
      'icon': Icons.arrow_outward,
      "date": "30 Aug 2025, 10:15 AM",
      'status': '12m 45s',
    },
    {
      "user": "Bob",
      "image": AppImage.user2,
      'icon': Icons.subdirectory_arrow_left_rounded,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
    {
      "user": "Charlie",
      "image": AppImage.user3,
      'icon': Icons.arrow_outward,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
    {
      "user": "Diana",
      "image": AppImage.user4,
      'icon': Icons.arrow_outward,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
    {
      "user": "Eve",
      "image": AppImage.user5,
      'icon': Icons.arrow_outward,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
    {
      "user": "Frank",
      "image": AppImage.user6,
      'icon': Icons.subdirectory_arrow_left_rounded,
      "date": "30 Aug 2025, 10:15 AM",
      'status': 'Missed',
    },
  ];
});

//search quert
final searchProvider = StateProvider<String>((ref) => '');

final filteredCallsProvider = Provider<List<Map<String, dynamic>>>((ref) {
  final allCalls = ref.watch(allCallProvider);
  final query = ref.watch(searchProvider);

  if (query.isEmpty) return allCalls;

  return allCalls.where((call) {
    final name = call['user'].toString().toLowerCase();
    final status = call['status'].toString().toLowerCase();
    return name.contains(query.toLowerCase()) ||
        status.contains(query.toLowerCase());
  }).toList();
});
