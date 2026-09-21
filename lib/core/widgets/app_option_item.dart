import 'package:flutter/material.dart';

class AppOptionItem {
  const AppOptionItem({required this.id, required this.label, this.icon});

  final String id;
  final String label;
  final IconData? icon;
}
