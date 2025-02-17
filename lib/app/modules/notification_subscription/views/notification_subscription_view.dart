import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../audio/views/summary_key_point_view.dart';
import '../../text/views/convert_to_text_view.dart';
import '../controllers/notification_subscription_controller.dart';

class NotificationSubscriptionView extends GetView<NotificationSubscriptionController> {
  const NotificationSubscriptionView({super.key});

  @override
  Widget build(BuildContext context) {
    Get.put(NotificationSubscriptionController()); // Ensure controller is registered

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

              final groupedNotifications = controller.groupNotificationsByDate();

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: groupedNotifications.entries.map((entry) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        //Text(entry.key, style: h4.copyWith(fontSize: 18, fontWeight: FontWeight.bold)),
                        //const SizedBox(height: 10),
                        ...entry.value.map((notification) => GestureDetector(
                          onTap: (){
                            print(':::::::::::::::: check keypoint: ${notification.keyPoints}');
                            print(':::::::::::::::: check: ${notification.fileName}');
                            if(notification.type == 'Conversion'){
                              Get.to(() => ConvertToTextView(
                                filePath: notification.keyPoints ?? "No file path",
                                fileName: notification.fileName ?? "Unknown File",
                              ));
                            }else if(notification.type == 'Summary'){
                              Get.to(() => SummaryKeyPointView(
                                keyPoints: notification.keyPoints ?? "No Key Points",
                                fileName: notification.fileName ?? "Unknown File",
                              ));
                            }
                          },
                          child: NotificationCard(
                            message: '${notification.message} of ${notification.fileName}',
                            time: notification.time,
                          ),
                        )),
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
}

class NotificationCard extends StatelessWidget {
  final String message;
  final String time;

  const NotificationCard({Key? key, required this.message, required this.time})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: AppColors.appColor2,
      margin: const EdgeInsets.only(bottom: 10),
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
              style: h4.copyWith(fontSize: 16, color: Colors.white),
            ),
            const SizedBox(height: 5),
            Align(
              alignment: Alignment.bottomRight,
              child: Text(
                time,
                style: h4.copyWith(fontSize: 12, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
