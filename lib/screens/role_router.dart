import 'package:flutter/material.dart';

import '../services/session_service.dart';
import 'live_portals.dart';
import 'login_screen.dart';

class RoleRouter {
  static Widget destinationFor(Map<String, dynamic> user) {
    switch (user['role']) {
      case 'admin':
      case 'super_admin':
        return const AdminPortalScreen();
      case 'doctor':
        return const DoctorPortalScreen();
      case 'lab_tech':
        return const LabPortalScreen();
      case 'nurse':
      case 'receptionist':
        return const StaffPortalScreen();
      default:
        return const PatientPortalScreen();
    }
  }

  static void go(BuildContext context, Map<String, dynamic> user) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => destinationFor(user)),
      (route) => false,
    );
  }

  static Future<void> logout(BuildContext context) async {
    await SessionService.instance.logout();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }
}
