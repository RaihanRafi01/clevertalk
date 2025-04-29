import 'package:clevertalk/app/modules/notification_subscription/views/subscription_view.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../audio/views/summary_key_point_view.dart';
import '../../text/views/convert_to_text_view.dart';
import '../controllers/notification_subscription_controller.dart';

class NotificationSubscriptionView
    extends GetView<NotificationSubscriptionController> {
  const NotificationSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(
        NotificationSubscriptionController()); // Ensure controller is registered

    return Scaffold(
      appBar: CustomAppBar(
        isSearch: true,
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          print("Second icon pressed");
        },
      ),
      body: Column(
        children: [
          Expanded(
            child: Obx(() {
              if (controller.notifications.isEmpty) {
                return const Center(
                  child: Text(
                    "No new notifications",
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final groupedNotifications =
                  controller.groupNotificationsByDate();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedNotifications.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ...entry.value.map((notification) {
                          // Use a truly unique key based on the notification object
                          final uniqueKey = UniqueKey().toString();
                          final index =
                              controller.notifications.indexOf(notification);

                          return Dismissible(
                            key: Key(uniqueKey),
                            // Use a unique key for each Dismissible
                            direction: DismissDirection.endToStart,
                            // Swipe right to left
                            confirmDismiss: (direction) async {
                              // Show delete confirmation dialog
                              return await _showDeleteConfirmationDialog(
                                  context, index);
                            },
                            onDismissed: (direction) {
                              // Remove the notification from the list after dismissal
                              controller.deleteNotification(index);
                            },
                            background: Container(
                              color: Colors.transparent,
                              alignment: Alignment.centerRight,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 20),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('Swipe to Delete'),
                                  SizedBox(width: 10),
                                  const Icon(Icons.delete, color: Colors.red),
                                ],
                              ),
                            ),
                            child: GestureDetector(
                              onTap: () {
                                controller.markAsRead(index);
                                print(
                                    ':::::::::::::::: check keypoint: ${notification.keyPoints}');
                                print(
                                    ':::::::::::::::: check fileName: ${notification.fileName}');
                                print(
                                    ':::::::::::::::: check filePath: ${notification.filePath}');
                                print(
                                    ':::::::::::::::: type: ${notification.type}');
                                if (notification.type == 'Conversion') {
                                  String cleanFileName = notification.fileName
                                          ?.replaceFirst('of ', '') ??
                                      'Unknown File';
                                  Get.to(() => ConvertToTextView(
                                        filePath: notification.filePath ??
                                            "No file path",
                                        fileName: cleanFileName,
                                      ));
                                } else if (notification.type == 'Summary') {
                                  Get.to(() => SummaryKeyPointView(
                                        fileName: notification.fileName ??
                                            "Unknown File",
                                        filePath: notification.filePath ??
                                            'Unknown FilePath',
                                      ));
                                } else if (notification.type ==
                                    'subscription_page') {
                                  Get.to(SubscriptionView());
                                }
                              },
                              child: NotificationCard(
                                message:
                                    '${notification.message} ${notification.fileName}',
                                time: notification.time,
                                isRead: notification.isRead,
                              ),
                            ),
                          );
                        }).toList(),
                        const SizedBox(height: 10),
                      ],
                    );
                  }).toList(),
                ),
              );
            }),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: CustomButton(
              text: 'Read All',
              onPressed: () => controller.markAllAsRead(),
            ),
          ),
        ],
      ),
    );
  }

  // Show delete confirmation dialog
  Future<bool?> _showDeleteConfirmationDialog(BuildContext context, int index) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Notification'),
        content:
            const Text('Are you sure you want to delete this notification?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false), // Cancel
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true); // Confirm
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// NotificationCard remains unchanged
class NotificationCard extends StatelessWidget {
  final String message;
  final String time;
  final bool isRead;

  const NotificationCard({
    Key? key,
    required this.message,
    required this.time,
    required this.isRead,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.appColor2,
      margin: const EdgeInsets.only(bottom: 10),
      // Fix this if 'custom' isn't a valid named parameter
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              message,
              style: h4.copyWith(
                fontSize: 16,
                color: isRead ? Colors.grey : Colors.white,
              ),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: h4.copyWith(
                  fontSize: 12,
                  color: isRead ? Colors.grey : Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
