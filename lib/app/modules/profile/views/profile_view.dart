import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../common/appColors.dart';
import '../../../../common/customFont.dart';
import '../../../../common/widgets/auth/custom_button.dart';
import '../../../../common/widgets/auth/custom_textField.dart';
import '../../../../common/widgets/customAppBar.dart';
import '../../../data/services/api_services.dart';
import '../../home/controllers/home_controller.dart';
import '../controllers/profile_controller.dart';

class ProfileView extends StatefulWidget {
  const ProfileView({Key? key}) : super(key: key);

  @override
  State<ProfileView> createState() => _EditProfileViewState();
}

class _EditProfileViewState extends State<ProfileView> {
  XFile? _pickedImage;
  final ProfileController profileController = Get.put(ProfileController());
  final HomeController homeController = Get.put(HomeController());

  // Initialize the TextEditingControllers directly with values
  late final TextEditingController _nameController =
      TextEditingController(text: homeController.name.value);
  late final TextEditingController _emailController =
      TextEditingController(text: homeController.email.value);
  late final TextEditingController _addressController =
      TextEditingController(text: homeController.address.value);
  late final TextEditingController _phoneController =
      TextEditingController(text: homeController.phone.value);
  late final TextEditingController _genderController =
      TextEditingController(text: homeController.gender.value);

  String baseUrl = ApiService().baseUrl.endsWith('/')
      ? ApiService().baseUrl.substring(0, ApiService().baseUrl.length - 1)
      : ApiService().baseUrl;

  @override
  void initState() {
    super.initState();

    // Fetch profile data and update controllers
    homeController.fetchProfileData().then((_) {
      setState(() {
        _phoneController.text = homeController.phone.value;
        _nameController.text = homeController.name.value;
        _emailController.text = homeController.email.value;
        _addressController.text = homeController.address.value;
        _genderController.text = homeController.gender.value;
      });
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _pickedImage = image;
      });
    }
  }

  @override
  void dispose() {
    // Dispose controllers to free up resources
    _phoneController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _genderController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          print("Second icon pressed");
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 40,
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
                          : homeController.profilePicUrl.value.isNotEmpty
                              ? NetworkImage(
                                  '$baseUrl${homeController.profilePicUrl.value}')
                              : const AssetImage(
                                      'assets/images/profile/profile_avatar.png')
                                  as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: SvgPicture.asset(
                              'assets/images/profile/edit_pic.svg'),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Obx(() => Text(
                            homeController.username.value,
                            style: h1.copyWith(
                                fontSize: 18, fontWeight: FontWeight.bold),
                          )),
                      const SizedBox(height: 10),
                      Obx(() => CustomButton(
                            backgroundColor: AppColors.appColor,
                            isGem: true,
                            width: 180,
                            fontSize: 12,
                            text: homeController.package_name.value == 'Free Trial' ? 'standard_account'.tr : 'premium_account'.tr,
                            onPressed: () {},
                          )),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            CustomTextField(
              label: 'full_name'.tr,
              // Localized label
              controller: _nameController,
              prefixIcon: Icons.person_outline_rounded,
              onChanged: (value) {
                profileController.updateName(value);
              },
              hint: 'enter_your_name'.tr, // Localized hint
            ),
            SizedBox(height: 20),
            CustomTextField(
              readOnly: true,
              label: 'email'.tr,
              // Localized label
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              hint: 'enter_your_email'.tr, // Localized hint
            ),
            SizedBox(height: 20),
            CustomTextField(
              phone: true,
              prefixIcon: Icons.phone,
              label: 'phone_number'.tr,
              // Localized label
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              hint: 'enter_phone_number'.tr,
              // Localized hint
              onChanged: (value) {
                profileController.updatePhone(value);
              },
            ),
            SizedBox(height: 20),
            CustomTextField(
              label: 'address'.tr,
              // Localized label
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              keyboardType: TextInputType.emailAddress,
              hint: 'enter_your_address'.tr,
              // Localized hint
              onChanged: (value) {
                profileController.updateAddress(value);
              },
            ),
            SizedBox(height: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'gender'.tr, // Localized label
                    style: h4.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.gray1,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                SizedBox(
                  height: 40, // Match CustomTextField height
                  child: Obx(() {
                    // Determine if the dropdown is focused to change border color
                    final isFocused = homeController.gender.value.isNotEmpty;
                    return Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color:
                              isFocused ? AppColors.appColor : AppColors.gray1,
                          width: isFocused ? 1 : 1,
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      child: Row(
                        children: [
                          // Prefix icon
                          Icon(
                            Icons.male_rounded,
                            color: Colors.grey.shade600,
                            size: 20, // Match CustomTextField icon size
                          ),
                          SizedBox(width: 12),
                          // Space between icon and dropdown
                          Expanded(
                            child: DropdownButton<String>(
                              hint: Text(
                                'select_your_gender'.tr, // Localized hint
                                style: h4.copyWith(
                                  fontSize: 12,
                                  color: AppColors.gray1,
                                ),
                              ),
                              value: homeController.gender.value.isNotEmpty
                                  ? homeController.gender.value
                                  : null,
                              items: [
                                {'value': 'Male', 'label': 'male'.tr},
                                {'value': 'Female', 'label': 'female'.tr},
                                {'value': 'Other', 'label': 'other'.tr},
                              ]
                                  .map((gender) => DropdownMenuItem<String>(
                                        value: gender[
                                            'value'], // Use English value
                                        child: Text(
                                          gender[
                                              'label']!, // Use translated label
                                          style: h4.copyWith(fontSize: 12),
                                        ),
                                      ))
                                  .toList(),
                              onChanged: (value) {
                                if (value != null) {
                                  profileController.updateGender(value);
                                  homeController.gender.value = value;
                                }
                              },
                              isExpanded: true,
                              // Make dropdown fill the container
                              underline: SizedBox(),
                              // Remove default underline
                              icon: Icon(Icons.arrow_drop_down,
                                  color: Colors.grey),
                              dropdownColor: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              ],
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'save'.tr,
              onPressed: () async {
                print(
                    '::::::::edit:::::::::::::NAME:::::::::::${homeController.name.value}');
                // print('::::::::::edit:::::::::::aboutYou:::::::::::${homeController.aboutYou.value}');

                // Set editing flag to true when saving
                //homeController.isEditingProfile.value = true;

                // Handle the profile picture
                File? profilePic;
                if (_pickedImage != null) {
                  profilePic = File(_pickedImage!.path);
                }

                // Call the updateData method
                await profileController.updateData(
                  homeController.name.value,
                  homeController.phone.value,
                  homeController.address.value,
                  homeController.gender.value,
                  profilePic,
                );
              },
            ),
            const SizedBox(height: 58),
          ],
        ),
      ),
    );
  }
}
