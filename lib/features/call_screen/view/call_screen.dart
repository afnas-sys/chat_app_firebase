// // ignore_for_file: deprecated_member_use

// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:font_awesome_flutter/font_awesome_flutter.dart';
// import 'package:support_chat/features/call_screen/call_tile/call_tile.dart';
// import 'package:support_chat/providers/calls_provider.dart';
// import 'package:support_chat/utils/constants/app_colors.dart';
// import 'package:support_chat/utils/constants/app_image.dart';
// import 'package:support_chat/utils/constants/app_text.dart';
// import 'package:support_chat/utils/constants/theme.dart';
// import 'package:support_chat/utils/widgets/custom_text_form_field.dart';

// class CallScreen extends ConsumerStatefulWidget {
//   const CallScreen({super.key});

//   @override
//   ConsumerState<CallScreen> createState() => _CallScreenState();
// }

// class _CallScreenState extends ConsumerState<CallScreen> {
//   final TextEditingController _searchController = TextEditingController();

//   @override
//   void dispose() {
//     _searchController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     final filteredCalls = ref.watch(filteredCallsProvider);
//     return Scaffold(
//       floatingActionButton: FloatingActionButton(
//         backgroundColor: AppColors.fifthColor,
//         onPressed: () {},
//         child: const Icon(Icons.add, color: AppColors.primaryColor),
//       ),
//       body: Container(
//         width: double.infinity,
//         height: double.infinity,
//         decoration: const BoxDecoration(
//           image: DecorationImage(
//             image: AssetImage(AppImage.appBg),
//             fit: BoxFit.cover,
//           ),
//         ),
//         child: SafeArea(
//           child: Padding(
//             padding: const EdgeInsets.all(20.0),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header row
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       AppText.chatTitle,
//                       style: Theme.of(context).textTheme.titleLargePrimary,
//                     ),
//                     ClipRRect(
//                       borderRadius: BorderRadius.circular(22),
//                       child: SizedBox(
//                         height: 44,
//                         width: 44,
//                         child: Image.asset(AppImage.profile, fit: BoxFit.cover),
//                       ),
//                     ),
//                   ],
//                 ),

//                 const SizedBox(height: 16),

//                 // Search box
//                 // Container(
//                 //   decoration: BoxDecoration(
//                 //     color: AppColors.fourthColor,
//                 //     borderRadius: BorderRadius.circular(30),
//                 //     border: Border.all(color: AppColors.tertiaryColor),
//                 //   ),
//                 //   child: CustomTextFormField(
//                 //     controller: _searchController,
//                 //     textColor: AppColors.primaryColor,
//                 //     prefixWidget: const Icon(
//                 //       FontAwesomeIcons.search,
//                 //       color: AppColors.primaryColor,
//                 //     ),
//                 //     hintText: 'Search...',
//                 //     hintColor: AppColors.tertiaryColor,
//                 //     onChanged: (value) {
//                 //       ref.read(searchProvider.notifier).state = value;
//                 //     },
//                 //   ),
//                 // ),

//                 // const SizedBox(height: 10),

//                 // // Calls list
//                 // Expanded(
//                 //   child: filteredCalls.isEmpty
//                 //       ? Center(child: Text('No Calls found'))
//                 //       : CallTile(datas: filteredCalls),
//                 // ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
