import 'package:flutter/material.dart';
import 'roles_screen.dart';

export 'roles_screen.dart';

/// Lớp tương thích ngược cho RbacScreen
class RbacScreen extends StatelessWidget {
  const RbacScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RolesScreen();
  }
}
