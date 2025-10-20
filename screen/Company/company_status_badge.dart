import 'package:flutter/material.dart';
import 'package:final_iug_2025/services/plan_service.dart';

class CompanyStatusBadge extends StatefulWidget {
  const CompanyStatusBadge({super.key});
  @override
  State<CompanyStatusBadge> createState() => _CompanyStatusBadgeState();
}

class _CompanyStatusBadgeState extends State<CompanyStatusBadge> {
  Map<String, dynamic>? plan;
  @override
  void initState() {
    super.initState();
  }


  @override
  Widget build(BuildContext context) {
    final status = (plan?['planStatus'] ?? 'none') as String;
    final text = status == 'active'
        ? 'Plan Active'
        : status == 'pending'
        ? 'Request Pending'
        : 'Free Plan';
    final color = status == 'active'
        ? Colors.green
        : status == 'pending'
        ? Colors.orange
        : Colors.blueGrey;

    return Chip(
      label: Text(text, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
    );
  }
}
