import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../data/services/notification_services.dart';
import '../controllers/summaryKeyPoint_controller.dart';

class SummaryKeyPointView extends StatelessWidget {
  final String fileName;
  final String filePath;

  const SummaryKeyPointView({
    super.key,
    required this.fileName,
    required this.filePath,
  });

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(SummaryKeyPointController(fileName: fileName));

    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {},
        onSecondIconPressed: () {},
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
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
                    if (!controller.isEditing.value) ...[
                      GestureDetector(
                        onTap: () async {
                          await controller.summaryRegenerate(filePath, fileName);
                        },
                        child: SvgPicture.asset('assets/images/summary/reload_icon.svg'),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => controller.isTranslate.toggle(),
                        child: SvgPicture.asset('assets/images/summary/translate_icon.svg'),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => controller.generateAndSharePdf(),
                        child: SvgPicture.asset('assets/images/summary/share_icon.svg'),
                      ),
                    ],
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        if (controller.isEditing.value) {
                          controller.saveKeyPoints();
                        }
                        controller.isTranslate.value = false;
                        controller.isEditing.toggle();
                      },
                      child: SvgPicture.asset(
                        controller.isEditing.value
                            ? 'assets/images/summary/save_icon.svg'
                            : 'assets/images/summary/edit_icon.svg',
                      ),
                    ),
                  ],
                ),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 100),
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: const Offset(0.0, -0.5),
                      end: const Offset(0.0, 0.0),
                    ).animate(animation);
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                  child: controller.isTranslate.value
                      ? Container(
                    key: const ValueKey('translateRow'),
                    child: Column(
                      children: [
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            CustomButton(
                              text: controller.currentLanguage.value.isEmpty
                                  ? 'English'
                                  : controller.currentLanguage.value,
                              onPressed: () {},
                              height: 26,
                              width: 70,
                              fontSize: 12,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: SvgPicture.asset('assets/images/summary/arrow_icon.svg'),
                            ),
                            Obx(() => Container(
                              height: 30,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppColors.appColor,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: DropdownButton<String>(
                                value: controller.selectedLanguage.value,
                                onChanged: (value) =>
                                controller.selectedLanguage.value = value!,
                                borderRadius: BorderRadius.circular(20),
                                dropdownColor: AppColors.appColor,
                                underline: const SizedBox(),
                                isExpanded: true,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                items: <String>[
                                  'English', 'Spanish', 'French', 'German', 'Italian',
                                  'Portuguese', 'Chinese', 'Hindi', 'Dutch', 'Ukrainian', 'Russian'
                                ].map((String value) {
                                  return DropdownMenuItem<String>(
                                    value: value,
                                    child: Text(
                                      value,
                                      style: h4.copyWith(fontSize: 12, color: Colors.white),
                                    ),
                                  );
                                }).toList(),
                              ),
                            )),
                            const Spacer(),
                            CustomButton(
                              text: 'Translate',
                              onPressed: () => controller.translateText(),
                              height: 26,
                              width: 70,
                              fontSize: 12,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  )
                      : const SizedBox(height: 20, key: ValueKey('empty')),
                ),
                Obx(() => controller.isEditing.value
                    ? TextField(
                  controller: controller.titleController,
                  style: h4.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                  decoration: const InputDecoration(
                    labelText: "Title",
                    border: OutlineInputBorder(),
                  ),
                )
                    : Text(
                  controller.titleController.text,
                  style: h4.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                )),
                const SizedBox(height: 10),
                Obx(() => controller.isEditing.value
                    ? TextField(
                  controller: controller.dateController,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  decoration: InputDecoration(
                    labelText: "Date",
                    border: const OutlineInputBorder(),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.calendar_month_outlined),
                      onPressed: controller.pickDateTime,
                    ),
                  ),
                )
                    : Text(
                  _formatDate(controller.dateController.text),
                  style: h4.copyWith(fontSize: 15),
                )),
                const SizedBox(height: 5),
                Row(
                  children: [
                    SvgPicture.asset('assets/images/summary/lan_icon.svg'),
                    const SizedBox(width: 10),
                    Obx(() => Text(
                        controller.currentLanguage.value.isEmpty
                            ? 'English'
                            : controller.currentLanguage.value,
                        style: h4)),
                  ],
                ),
                const SizedBox(height: 16),
                Text('Key Points:', style: h4.copyWith(fontSize: 17, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10),
                Obx(() => controller.isEditing.value
                    ? _buildEditableList(
                    controller.mainPoints,
                    controller.mainPointTitleControllers,
                    controller.mainPointValueControllers)
                    : _buildReadOnlyList(controller.mainPoints)),
                const SizedBox(height: 20),
                if (controller.conclusions.isNotEmpty) ...[
                  Text('Conclusions:', style: h4.copyWith(fontSize: 17, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Obx(() => controller.isEditing.value
                      ? _buildEditableList(
                      controller.conclusions,
                      controller.conclusionTitleControllers,
                      controller.conclusionValueControllers)
                      : _buildReadOnlyList(controller.conclusions)),
                ],
                const SizedBox(height: 30),
              ],
            ),
          ),
        );
      }),
    );
  }

  Widget _buildEditableList(
      RxList<Map<String, String>> list,
      List<TextEditingController> titleControllers,
      List<TextEditingController> valueControllers) {
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
                decoration: const InputDecoration(
                  labelText: "Key Point Title",
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: valueControllers[index],
                style: h4.copyWith(fontSize: 15),
                maxLines: 2,
                decoration: const InputDecoration(
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

  Widget _buildReadOnlyList(RxList<Map<String, String>> list) {
    return Column(
      children: list.map((point) {
        return Padding(
          padding: const EdgeInsets.only(left: 10, bottom: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("• ${point.keys.first}",
                  style: h4.copyWith(fontSize: 16, fontWeight: FontWeight.bold)),
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

  String _formatDate(String dateString) {
    DateTime dateTime = DateTime.parse(dateString);
    return "Date: ${DateFormat('d MMMM y').format(dateTime)} time: ${DateFormat('h:mm a').format(dateTime)}";
  }
}