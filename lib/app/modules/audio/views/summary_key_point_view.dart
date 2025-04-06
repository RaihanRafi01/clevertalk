import 'package:clevertalk/common/widgets/auth/custom_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../data/services/notification_services.dart';
import '../bindings/language_model.dart';
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
                        child: SvgPicture.asset('assets/images/summary/reload_icon.svg',color: AppColors.gray1,),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => controller.isTranslate.toggle(),
                        child: SvgPicture.asset('assets/images/summary/translate_icon.svg',color: AppColors.gray1),
                      ),
                      const SizedBox(width: 16),
                      GestureDetector(
                        onTap: () => controller.generateAndSharePdf(),
                        child: SvgPicture.asset('assets/images/summary/share_icon.svg',color: AppColors.gray1),
                      ),
                    ],
                    const SizedBox(width: 16),
                    GestureDetector(
                      onTap: () {
                        if (controller.isEditing.value) {
                          controller.saveKeyPoints(true);
                        }
                        controller.isTranslate.value = false;
                        controller.isEditing.toggle();
                      },
                      child: SvgPicture.asset(
                        controller.isEditing.value
                            ? 'assets/images/summary/save_icon.svg'
                            : 'assets/images/summary/edit_icon.svg',color: AppColors.gray1
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
                              height: 40,
                              width: 80,
                              fontSize: 12,
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: SvgPicture.asset('assets/images/summary/arrow_icon.svg'),
                            ),
                            // Replace your existing DropdownButton with this
                            Obx(() => Container(
                              height: 40,
                              width: 120,
                              decoration: BoxDecoration(
                                color: AppColors.appColor,
                                borderRadius: BorderRadius.circular(20),
                              ), // <-- Added closing parenthesis for BoxDecoration
                              child: InkWell(
                                onTap: () => _showSearchBottomSheet(context, controller),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          controller.selectedLanguage.value,
                                          style: h4.copyWith(fontSize: 12, color: Colors.white),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const Icon(Icons.arrow_drop_down, color: Colors.white, size: 20),
                                    ],
                                  ),
                                ),
                              ),
                            )),
                            const Spacer(),
                            CustomButton(
                              text: 'Translate',
                              onPressed: () => controller.translateText(filePath, fileName),
                              height: 40,
                              width: 80,
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
                Obx(() => Text(
                    controller.keyPointsLabel.value,
                    style: h4.copyWith(fontSize: 15, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                Obx(() => controller.isEditing.value
                    ? _buildEditableList(
                    controller.mainPoints,
                    controller.mainPointTitleControllers,
                    controller.mainPointValueControllers)
                    : _buildReadOnlyList(controller.mainPoints)),
                const SizedBox(height: 20),
                if (controller.conclusions.isNotEmpty) ...[
                  Obx(() => Text(
                      controller.conclusionsLabel.value,
                      style: h4.copyWith(fontSize: 15, fontWeight: FontWeight.bold))),
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
                  style: h4.copyWith(fontSize: 14, fontWeight: FontWeight.bold)),
              Padding(
                padding: const EdgeInsets.only(left: 20, top: 4),
                child: Text(point.values.first, style: h4.copyWith(fontSize: 13)),
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

  void _showSearchBottomSheet(BuildContext context, SummaryKeyPointController controller) {
    TextEditingController searchController = TextEditingController();
    List<Language> filteredLanguages = List.from(languages);
    bool isCleared = false; // Flag to track if the clear button has been clicked

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent, // Transparent background for a custom container
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setState) {
            return AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              padding: const EdgeInsets.all(16),
              height: MediaQuery.of(context).size.height * 0.7,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 5,
                  ),
                ],
              ),
              child: Column(
                children: [
                  // Header with a title and close button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Select Language',
                        style: h4.copyWith(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textHeader, // Use your app's color scheme
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.grey),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Search field with enhanced design
                  TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search language...',
                      hintStyle: TextStyle(
                        color: Colors.grey.shade500,
                        fontStyle: FontStyle.italic,
                      ),
                      prefixIcon: Icon(Icons.search, color: AppColors.appColor),
                      suffixIcon: IconButton(
                        icon: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 200),
                          child: Icon(
                            searchController.text.isEmpty ? null : Icons.clear,
                            key: ValueKey(searchController.text.isEmpty),
                            color: AppColors.appColor,
                          ),
                        ),
                        onPressed: () {
                          if (searchController.text.isEmpty) {
                            Navigator.pop(context);
                          } else if (!isCleared) {
                            searchController.clear();
                            setState(() {
                              filteredLanguages = List.from(languages);
                              isCleared = true;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                      ),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppColors.appColor, width: 2),
                      ),
                    ),
                    style: h4.copyWith(fontSize: 16, color: Colors.black87),
                    onChanged: (value) {
                      setState(() {
                        filteredLanguages = languages.where((lang) {
                          final query = value.toLowerCase();
                          return lang.name.toLowerCase().contains(query) ||
                              lang.region.toLowerCase().contains(query);
                        }).toList();
                        isCleared = false;
                      });
                    },
                  ),
                  const SizedBox(height: 16),
                  // Enhanced language list
                  Expanded(
                    child: filteredLanguages.isEmpty
                        ? Center(
                      child: Text(
                        'No languages found',
                        style: h4.copyWith(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    )
                        : ListView.separated(
                      itemCount: filteredLanguages.length,
                      separatorBuilder: (context, index) => Divider(
                        color: Colors.grey.shade300,
                        height: 1,
                      ),
                      itemBuilder: (context, index) {
                        final lang = filteredLanguages[index];
                        return AnimatedOpacity(
                          opacity: 1.0,
                          duration: const Duration(milliseconds: 200),
                          child: ListTile(
                            leading: CircleAvatar(
                              radius: 16,
                              backgroundColor: AppColors.appColor3.withOpacity(0.1),
                              child: Text(
                                lang.name[0],
                                style: TextStyle(
                                  color: AppColors.appColor3,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            title: Text(
                              lang.name,
                              style: h4.copyWith(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black87,
                              ),
                            ),
                            subtitle: Text(
                              lang.region,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade600,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.check,
                              color: Colors.transparent, // Placeholder for selection indication
                            ),
                            onTap: () {
                              controller.selectedLanguage.value = lang.name;
                              Navigator.pop(context);
                            },
                            tileColor: Colors.white,
                            hoverColor: Colors.grey.shade100,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}