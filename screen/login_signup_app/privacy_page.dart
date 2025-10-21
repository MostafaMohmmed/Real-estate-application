// lib/screen/info/privacy_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

class PrivacyPage extends StatelessWidget {
  const PrivacyPage({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(title: Text('privacy'.tr())),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('privacy_title'.tr(), style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Text('privacy_body'.tr(), style: Theme.of(context).textTheme.bodyMedium),
            const SizedBox(height: 18),
            Text('privacy_data_title'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('privacy_data_body'.tr()),
            const SizedBox(height: 12),
            Text('privacy_contact_title'.tr(), style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('privacy_contact_body'.tr()),
          ],
        ),
      ),
    );
  }
}
