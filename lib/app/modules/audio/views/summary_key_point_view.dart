import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../controllers/summaryKeyPoint_controller.dart';

class SummaryKeyPointView extends StatelessWidget {
  final String keyPoints;
  final String fileName;

  const SummaryKeyPointView({super.key, required this.keyPoints, required this.fileName});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SummaryKeyPointController(keyPoints: keyPoints, fileName: fileName));

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {},
        onSecondIconPressed: () {},
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return Center(child: CircularProgressIndicator()); // Show loading indicator
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if(!controller.isEditing.value)
                      IconButton(
                        icon: Icon(
                          Icons.share_outlined,
                          color: Colors.blue,
                          size: 28,
                        ),
                        onPressed: () {
                          print(':::::::::::::keyPoints::::::::::::::::${controller.titleController.text}');
                          print(':::::::::::::main points::::::::::::::::${controller.mainPoints}');
                          print(':::::::::::::conclusions::::::::::::::::${controller.conclusions}');
                          // pdf generate
                          controller.generateAndSharePdf();
                        },
                      ),
                    IconButton(
                      icon: Icon(
                        controller.isEditing.value ? Icons.save : Icons.edit,
                        color: Colors.blue,
                        size: 28,
                      ),
                      onPressed: () {
                        if (controller.isEditing.value) {
                          controller.saveKeyPoints();
                        }
                        controller.isEditing.toggle();
                      },
                    ),
                  ],
                ),
                Obx(() => controller.isEditing.value
                    ? TextField(
                  controller: controller.dateController,
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Date",
                    border: OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: Icon(Icons.calendar_month_outlined),
                      onPressed: controller.pickDateTime,
                    ),
                  ),
                )
                    : Text(
                  "Date: ${controller.dateController.text}",
                  style: h4.copyWith(fontSize: 15),
                )),
                SizedBox(height: 10),
                Obx(() => controller.isEditing.value
                    ? TextField(
                  controller: controller.titleController,
                  style: h4.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                )
                    : Text(
                  controller.titleController.text,
                  style: h4.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                )),
                SizedBox(height: 10),
                Text(
                  'Key Points:',
                  style: h4.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 10),
                Obx(() => controller.isEditing.value
                    ? _buildEditableList(controller.mainPoints, controller.mainPointTitleControllers, controller.mainPointValueControllers)
                    : _buildReadOnlyList(controller.mainPoints)),
                SizedBox(height: 20),
                if (controller.conclusions.isNotEmpty) ...[
                  Text(
                    'Conclusions:',
                    style: h4.copyWith(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Obx(() => controller.isEditing.value
                      ? _buildEditableList(controller.conclusions, controller.conclusionTitleControllers, controller.conclusionValueControllers)
                      : _buildReadOnlyList(controller.conclusions)),
                ],
                SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEditableList(List<Map<String, String>> list, List<TextEditingController> titleControllers, List<TextEditingController> valueControllers) {
    return Column(
      children: List.generate(list.length, (index) {
        return Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleControllers[index],
                style: h4.copyWith(fontSize: 15, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  labelText: "Key Point Title",
                  border: OutlineInputBorder(),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: valueControllers[index],
                style: h4.copyWith(fontSize: 15),
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Description",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildReadOnlyList(List<Map<String, String>> list) {
    return Column(
      children: list.map((point) {
        return Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ${point.keys.first}", style: h4.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 4),
                child: Text(point.values.first, style: h4.copyWith(fontSize: 15)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}