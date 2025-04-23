import 'package:flutter/material.dart';
import 'package:test_drive/user.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key, this.user});
  final ApiGetUser? user;

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('Settings Page test testsetse'),
    );
  }
}
