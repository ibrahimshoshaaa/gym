import 'package:flutter/material.dart';
import '../screens/workspace_menu.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});
  @override
  Widget build(BuildContext context) => const Drawer(child: SafeArea(child: WorkspaceMenu(inDrawer: true)));
}
