// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:support_chat/features/expanse_manager/providers/expanse_provider.dart';
import 'package:support_chat/features/expanse_manager/widgets/analyst_view.dart';
import 'package:support_chat/features/expanse_manager/widgets/tab_content.dart';
import 'package:support_chat/models/expanse_model.dart';
import 'package:support_chat/utils/constants/app_colors.dart';
import 'package:support_chat/utils/constants/app_image.dart';
import 'package:support_chat/providers/auth_provider.dart';

class ExpanseManager extends ConsumerStatefulWidget {
  const ExpanseManager({super.key});

  @override
  ConsumerState<ExpanseManager> createState() => _ExpanseManagerState();
}

class _ExpanseManagerState extends ConsumerState<ExpanseManager>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _showAnalyst = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final transactionsAsync = ref.watch(transactionsProvider);
    final isDragging = ref.watch(isDraggingCategoryProvider);
    final userDataAsync = ref.watch(currentUserDataProvider);

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        backgroundColor: Colors.black,
        child: Column(
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(AppImage.appBg),
                  fit: BoxFit.cover,
                ),
              ),
              child: const Center(
                child: Text(
                  'Manager Tools',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_balance_wallet,
                color: Colors.white,
              ),
              title: const Text(
                'Expanse Tracker',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() => _showAnalyst = false);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.pie_chart, color: Colors.white),
              title: const Text(
                'Analyst',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                setState(() => _showAnalyst = true);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage(AppImage.appBg),
                fit: BoxFit.cover,
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
                child: transactionsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (err, stack) => Center(
                    child: Text(
                      'Error: $err\n(You may need to create a Firestore index)',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                  data: (transactions) {
                    double totalExpenses = 0;
                    double totalIncome = 0;
                    List<ExpanseModel> expensesList = [];
                    List<ExpanseModel> incomeList = [];

                    for (var item in transactions) {
                      if (item.type == 'expanses' || item.type == 'expense') {
                        totalExpenses += item.amount;
                        expensesList.add(item);
                      } else {
                        totalIncome += item.amount;
                        incomeList.add(item);
                      }
                    }

                    return Column(
                      spacing: 10,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            IconButton(
                              onPressed: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
                              icon: const Icon(Icons.menu, color: Colors.white),
                            ),
                            Text(
                              _showAnalyst ? 'Analysis' : 'Expanse Manager',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            userDataAsync.when(
                              data: (userData) {
                                final photo =
                                    userData?['photoURL'] ??
                                    userData?['image'] ??
                                    AppImage.user1;
                                return CircleAvatar(
                                  radius: 18,
                                  backgroundImage: photo.startsWith('http')
                                      ? NetworkImage(photo)
                                      : AssetImage(photo) as ImageProvider,
                                );
                              },
                              loading: () => const CircleAvatar(
                                radius: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              error: (_, __) =>
                                  const Icon(Icons.person, color: Colors.white),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        if (_showAnalyst)
                          const Expanded(child: AnalystView())
                        else ...[
                          Container(
                            height: 45,
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(25),
                            ),
                            child: TabBar(
                              controller: _tabController,
                              indicatorSize: TabBarIndicatorSize.tab,
                              dividerColor: Colors.transparent,
                              indicator: BoxDecoration(
                                borderRadius: BorderRadius.circular(25),
                                color: AppColors.fifthColor,
                              ),
                              labelColor: Colors.white,
                              unselectedLabelColor: AppColors.fifthColor,
                              tabs: const [
                                Tab(text: 'Expanses'),
                                Tab(text: 'Income'),
                              ],
                            ),
                          ),
                          Expanded(
                            child: TabBarView(
                              controller: _tabController,
                              children: [
                                //! Expanses
                                TabContent(
                                  type: 'Expanses',
                                  total: totalIncome - totalExpenses,
                                  list: expensesList,
                                ),
                                //! Income
                                TabContent(
                                  type: 'Income',
                                  total: totalIncome,
                                  list: incomeList,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ),
          if (isDragging)
            Positioned(
              bottom: 50,
              left: 0,
              right: 0,
              child: DragTarget<Map<String, String>>(
                onAccept: (data) async {
                  final categoryName = data['name']!;
                  final categoryType = data['type']!;

                  final List<String> defaultCats =
                      categoryType.toLowerCase() == 'income'
                      ? ['Salary']
                      : ['Travel', 'Grocery', 'Food'];

                  if (defaultCats.contains(categoryName)) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Cannot delete default categories'),
                          backgroundColor: Colors.orange,
                        ),
                      );
                    }
                    return;
                  }

                  // Show confirmation dialog
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) => AlertDialog(
                      backgroundColor: AppColors.fifthColor,
                      title: const Text(
                        'Delete Category',
                        style: TextStyle(color: Colors.white),
                      ),
                      content: Text(
                        'Are you sure you want to delete "$categoryName"?',
                        style: const TextStyle(color: Colors.white70),
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(context, false),
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
                    try {
                      final service = ref.read(expanseServiceProvider);
                      await service.deleteCategory(categoryName, categoryType);

                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Category "$categoryName" deleted'),
                            action: SnackBarAction(
                              label: 'Undo',
                              onPressed: () async {
                                await service.addCategory(
                                  categoryName,
                                  categoryType,
                                );
                              },
                            ),
                          ),
                        );
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(
                          context,
                        ).showSnackBar(SnackBar(content: Text('Error: $e')));
                      }
                    }
                  }
                },
                builder: (context, candidateData, rejectedData) {
                  return Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: candidateData.isNotEmpty
                            ? Colors.red
                            : Colors.red.withOpacity(0.5),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.3),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.delete,
                        color: Colors.white,
                        size: 40,
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}
