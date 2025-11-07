// import 'package:flutter/material.dart';
// import '../utils/colors.dart';
// import '../utils/constants.dart';
// import '../services/auth_service.dart';
// import '../services/firestore_service.dart';

// class NotificationBadge extends StatelessWidget {
//   final Widget child;
//   final VoidCallback? onTap;
//   final Color? badgeColor;
//   final Color? textColor;

//   const NotificationBadge({
//     super.key,
//     required this.child,
//     this.onTap,
//     this.badgeColor,
//     this.textColor,
//   });

//   @override
//   Widget build(BuildContext context) {
//     final AuthService authService = AuthService();
//     final FirestoreService firestoreService = FirestoreService();
//     final userId = authService.currentUserId;

//     if (userId == null) {
//       return child;
//     }

//     return StreamBuilder<int>(
//       stream: firestoreService.getUnreadNotificationsCount(userId),
//       builder: (context, snapshot) {
//         final unreadCount = snapshot.data ?? 0;

//         return GestureDetector(
//           onTap: onTap,
//           child: Stack(
//             children: [
//               child,
//               if (unreadCount > 0)
//                 Positioned(
//                   right: 0,
//                   top: 0,
//                   child: Container(
//                     padding: const EdgeInsets.all(2),
//                     decoration: BoxDecoration(
//                       color: badgeColor ?? AppColors.error,
//                       borderRadius:
//                           BorderRadius.circular(AppConstants.radiusRound),
//                       border: Border.all(
//                         color: Colors.white,
//                         width: 1.5,
//                       ),
//                     ),
//                     constraints: const BoxConstraints(
//                       minWidth: 16,
//                       minHeight: 16,
//                     ),
//                     child: Center(
//                       child: unreadCount > 99
//                           ? Text(
//                               '99+',
//                               style: TextStyle(
//                                 color: textColor ?? Colors.white,
//                                 fontSize: AppConstants.fontXS,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             )
//                           : Text(
//                               unreadCount.toString(),
//                               style: TextStyle(
//                                 color: textColor ?? Colors.white,
//                                 fontSize: AppConstants.fontXS,
//                                 fontWeight: FontWeight.bold,
//                               ),
//                             ),
//                     ),
//                   ),
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class NotificationIcon extends StatelessWidget {
//   final VoidCallback? onTap;
//   final Color? iconColor;
//   final double? iconSize;

//   const NotificationIcon({
//     super.key,
//     this.onTap,
//     this.iconColor,
//     this.iconSize,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return NotificationBadge(
//       onTap: onTap,
//       child: Icon(
//         Icons.notifications,
//         color: iconColor ?? AppColors.textWhite,
//         size: iconSize ?? AppConstants.iconL,
//       ),
//     );
//   }
// }

// class NotificationIconButton extends StatelessWidget {
//   final VoidCallback? onPressed;
//   final Color? iconColor;
//   final String? tooltip;

//   const NotificationIconButton({
//     super.key,
//     this.onPressed,
//     this.iconColor,
//     this.tooltip,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return NotificationBadge(
//       onTap: onPressed,
//       child: IconButton(
//         onPressed: onPressed,
//         icon: Icon(
//           Icons.notifications,
//           color: iconColor ?? AppColors.textWhite,
//         ),
//         tooltip: tooltip ?? 'Notifications',
//       ),
//     );
//   }
// }
