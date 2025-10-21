// lib/screen/info/contact_page.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactPage extends StatelessWidget {
  const ContactPage({super.key});

  static const String adminPhone = '970599650582'; // بدون + أو 00 (wa.me expects country+number)
  static const String adminEmail = 'mstfyklab997@gmail.com';

  Future<void> _openWhatsApp(BuildContext context) async {
    final message = Uri.encodeComponent('contact_whatsapp_message'.tr());
    final url = Uri.parse('https://wa.me/$adminPhone?text=$message');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('cant_open_whatsapp'.tr())));
      }
    }
  }

  Future<void> _openEmail(BuildContext context) async {
    final subject = Uri.encodeComponent('Contact from App');
    final body = Uri.encodeComponent('Hello, I would like to...');
    final url = Uri.parse('mailto:$adminEmail?subject=$subject&body=$body');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('cant_open_email'.tr())));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    return Scaffold(
      appBar: AppBar(title: Text('contact_us'.tr())),
      body: Padding(
        padding: EdgeInsets.all(size.width * 0.05),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.phone, size: 30),
                title: Text('contact_phone_title'.tr()),
                subtitle: Text('+$adminPhone'),
                trailing: FilledButton.icon(
                  icon:  Icon(Icons.call),
                  label: Text('contact_whatsapp'.tr()),
                  onPressed: () => _openWhatsApp(context),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: const Icon(Icons.email_outlined, size: 30),
                title: Text('contact_email_title'.tr()),
                subtitle: Text(adminEmail),
                trailing: FilledButton.icon(
                  icon: const Icon(Icons.send),
                  label: Text('contact_email'.tr()),
                  onPressed: () => _openEmail(context),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Text('contact_help_text'.tr(), style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 14),
            // Quick message box (local only)
            ElevatedButton.icon(
              icon: const Icon(Icons.message),
              label: Text('contact_send_message'.tr()),
              onPressed: () {
                // هنا تقدر تفتح صفحة فرم أو bottomsheet لإرسال رسالة داخل التطبيق
                ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('feature_coming'.tr())));
              },
            ),
          ],
        ),
      ),
    );
  }
}
