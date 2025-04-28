import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../app/modules/home/controllers/home_controller.dart';
import '../../appColors.dart';
import '../../customFont.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String hint;
  final int maxLine;
  final bool isPassword;
  final bool readOnly;
  final bool phone;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final Function(String)? onChanged;
  final TextInputType? keyboardType;
  final Function()? onTap;
  final double radius;
  final Color textColor;

  const CustomTextField({
    super.key,
    required this.label,
    required this.hint,
    this.isPassword = false,
    this.readOnly = false,
    this.phone = false,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.onChanged,
    this.keyboardType,
    this.onTap,
    this.radius = 10,
    this.maxLine = 1,
    this.textColor = AppColors.gray1,
  });

  @override
  _CustomTextFieldState createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  final HomeController homeController = Get.put(HomeController());

  @override
  void initState() {
    super.initState();
    if (!widget.isPassword) {
      _obscureText = false;
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscureText = !_obscureText;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            widget.label,
            style: h4.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: widget.maxLine > 1 ? 150 : 40, // Increased height for multi-line fields
          child: TextField(
            maxLines: widget.maxLine,
            style: const TextStyle(fontSize: 12),
            cursorColor: AppColors.appColor,
            controller: widget.controller,
            onChanged: widget.onChanged,
            obscureText: widget.isPassword ? _obscureText : false,
            readOnly: widget.readOnly,
            keyboardType: widget.keyboardType,
            onTap: widget.onTap,
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: h4.copyWith(fontSize: 12),
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon, color: Colors.grey.shade600, size: 20)
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                icon: Icon(
                  size: 20,
                  _obscureText
                      ? Icons.visibility_off_rounded
                      : Icons.visibility_rounded,
                  color: AppColors.gray1,
                ),
                onPressed: _togglePasswordVisibility,
              )
                  : (widget.suffixIcon != null
                  ? Icon(widget.suffixIcon, color: AppColors.gray1)
                  : null),
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 12,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.radius),
                borderSide: const BorderSide(color: AppColors.gray1),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.radius),
                borderSide: const BorderSide(color: AppColors.gray1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(widget.radius),
                borderSide: const BorderSide(color: AppColors.appColor, width: 1),
              ),
            ),
          ),
        ),
      ],
    );
  }
}