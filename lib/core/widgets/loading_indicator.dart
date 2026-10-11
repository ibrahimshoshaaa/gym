import 'package:flutter/material.dart';
import 'gym_ui.dart';
class LoadingIndicator extends StatelessWidget {
  final String? message;
  const LoadingIndicator({super.key, this.message});
  @override
  Widget build(BuildContext context) => const GymLoading();
}
