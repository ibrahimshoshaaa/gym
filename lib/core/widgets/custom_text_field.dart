import 'package:flutter/material.dart';
import 'gym_ui.dart';
class CustomTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;
  final TextInputType? keyboardType;
  final bool obscureText;
  final IconData? prefixIcon;
  const CustomTextField({super.key, required this.controller, required this.label, this.validator, this.keyboardType, this.obscureText = false, this.prefixIcon});
  @override
  Widget build(BuildContext context) => GymTextField(controller: controller, validator: validator,
    keyboardType: keyboardType, obscureText: obscureText, decoration: InputDecoration(labelText: label, prefixIcon: prefixIcon == null ? null : Icon(prefixIcon)));
}
