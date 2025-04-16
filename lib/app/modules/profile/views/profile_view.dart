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
        padding: const EdgeInsets.symmetric(horizontal: 24,vertical: 14),
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
                          ? NetworkImage('$baseUrl${homeController.profilePicUrl.value}')
                          : const AssetImage('assets/images/profile/profile_avatar.png') as ImageProvider,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: CircleAvatar(
                          backgroundColor: Colors.transparent,
                          child: SvgPicture.asset('assets/images/profile/edit_pic.svg'),
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
                        style: h1.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                      )),
                      const SizedBox(height: 10),
                      CustomButton(
                        backgroundColor: AppColors.appColor,
                        isGem: true,
                        width: 180,
                        fontSize: 12,
                        text: 'Standard Account',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 40),
            CustomTextField(
              label: 'Full Name',
              controller: _nameController,
              prefixIcon: Icons.person_outline_rounded,
              onChanged: (value) {
                profileController.updateName(value);
              },
              hint: 'Enter Your Name',
            ),
            SizedBox(height: 40),
            CustomTextField(
              readOnly: true,
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              hint: 'Enter Your Email',
            ),
            SizedBox(height: 40),
            CustomTextField(
              phone: true,
              prefixIcon: Icons.phone,
              label: 'Phone Number',
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              hint: 'Enter Phone Number',
              onChanged: (value) {
                profileController.updatePhone(value);
              },
            ),
            SizedBox(height: 40),
            CustomTextField(
              label: 'Address',
              controller: _addressController,
              prefixIcon: Icons.location_on_outlined,
              keyboardType: TextInputType.emailAddress,
              hint: 'Enter Your Address',
              onChanged: (value) {
                profileController.updateAddress(value);
              },
            ),
            SizedBox(height: 40),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(
                    'Gender',
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
                  child: Obx(() => DropdownButtonFormField<String>(
                    decoration: InputDecoration(
                      hintText: 'Select Your Gender',
                      hintStyle: h4.copyWith(fontSize: 12),
                      prefixIcon: const Icon(
                        Icons.male_rounded,
                        color: Colors.grey,
                        size: 20, // Match CustomTextField icon size
                      ),
                      isDense: true, // Compact layout
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 10, // Match CustomTextField padding
                        horizontal: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10), // Match CustomTextField radius
                        borderSide: const BorderSide(color: AppColors.gray1),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.gray1),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.appColor, width: 1),
                      ),
                    ),
                    value: homeController.gender.value.isNotEmpty ? homeController.gender.value : null,
                    items: ['Male', 'Female', 'Other'].map((gender) => DropdownMenuItem<String>(
                      value: gender,
                      child: Text(
                        gender,
                        style: h4.copyWith(fontSize: 12), // Match CustomTextField text size
                      ),
                    )).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        profileController.updateGender(value);
                        homeController.gender.value = value;
                      }
                    },
                    dropdownColor: Colors.white,
                    menuMaxHeight: 150,
                  )),
                ),
              ],
            ),
            const SizedBox(height: 40),
            CustomButton(
              text: 'Save',
              onPressed: () async {
                print('::::::::edit:::::::::::::NAME:::::::::::${homeController.name.value}');
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


