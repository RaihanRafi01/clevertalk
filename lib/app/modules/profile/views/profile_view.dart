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

  // Declare the TextEditingControllers
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _aboutYouController;

  @override
  void initState() {
    super.initState();
    // Initialize the controllers
    _nameController = TextEditingController();
    _emailController = TextEditingController();
    _aboutYouController = TextEditingController();
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
    _nameController.dispose();
    _emailController.dispose();
    _aboutYouController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: "CLEVERTALK",
        onFirstIconPressed: () {
          // Action for the first button
          print("First icon pressed");
        },
        onSecondIconPressed: () {
          // Action for the second button
          print("Second icon pressed");
        },
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                Stack(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: _pickedImage != null
                          ? FileImage(File(_pickedImage!.path))
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
                const SizedBox(width: 20), // Add some spacing between the avatar and the column
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start, // Align items to the start (left)
                    children: [
                      Text(
                        'UserName', // Replace with actual username from your controller
                        style: h1.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 10),
                      CustomButton(
                        backgroundColor: AppColors.appColor2,
                        isGem: true,
                        width: 210, // Adjust the width to fill available space
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
                // Update ProfileController whenever the text changes
              },
              hint: 'Enter Your Name',
            ),
            CustomTextField(
              label: 'Email',
              controller: _emailController,
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              hint: 'Enter Your Email',
            ),
            CustomTextField(
              phone: true,
              label: 'Phone Number',
              controller: _emailController,
              keyboardType: TextInputType.phone,
              hint: 'Enter Phone Number',
            ),
            CustomTextField(
              label: 'Address',
              controller: _emailController,
              prefixIcon: Icons.location_on_outlined,
              keyboardType: TextInputType.emailAddress,
              hint: 'Enter Your Address',
            ),
            CustomTextField(
              label: 'Gender',
              controller: _emailController,
              prefixIcon: Icons.male_rounded,
              keyboardType: TextInputType.emailAddress,
              hint: 'Enter Your Gender',
            ),
            const SizedBox(height: 20),
            CustomButton(
              text: 'Save',
              onPressed: () async {
                // Implement save logic here
              },
            ),
            SizedBox(height: 58,)
          ],
        ),
      ),
    );
  }
}

