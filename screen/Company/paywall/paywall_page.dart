import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart'; // Clipboard
import 'package:final_iug_2025/services/plan_service.dart';

class PaywallPage extends StatelessWidget {
  const PaywallPage({super.key});

  /// رقم الإدارة (دولي بدون +)
  static const _adminWhatsapp = '970599650582';

  Future<void> _request(BuildContext context, String plan) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please sign in first')),
      );
      return;
    }

    final planService = PlanService();
    final name = u.displayName ?? 'Company';
    final email = (u.email ?? '').toLowerCase();

    try {
      // (1) أنشئ طلبًا باللحظة
      await planService.createPlanRequest(
        companyUid: u.uid,
        companyName: name,
        email: email,
        planType: plan, // '5' | '15' | '30' | 'unlimited'
      );

      // (2) حضّر رسالة الواتساب
      final msg = Uri.encodeComponent(
        'Hello, I want plan: $plan'
            '\nCompany: $name'
            '\nEmail: $email'
            '\nUID: ${u.uid}',
      );

      // (3) حاول فتح واتساب مباشرة
      final uriWhatsApp = Uri.parse('whatsapp://send?phone=$_adminWhatsapp&text=$msg');
      final uriWaMe = Uri.parse('https://wa.me/$_adminWhatsapp?text=$msg');

      bool launched = false;

      if (await canLaunchUrl(uriWhatsApp)) {
        launched = await launchUrl(uriWhatsApp, mode: LaunchMode.externalApplication);
      }
      if (!launched) {
        // افتح wa.me بالمتصفح كخطة بديلة (تعمل حتى على المحاكي)
        launched = await launchUrl(uriWaMe, mode: LaunchMode.externalApplication);
      }

      if (!launched) {
        // آخر حل: عرض الرسالة للمستخدم ونسخها للحافظة
        await Clipboard.setData(ClipboardData(text: Uri.decodeComponent(msg)));
        if (context.mounted) {
          await showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('WhatsApp not available'),
              content: const Text(
                'Couldn\'t open WhatsApp. The message was copied to clipboard. '
                    'Please paste it in WhatsApp and send to the admin.',
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
              ],
            ),
          );
        }
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent. We will activate soon.')),
        );
        Navigator.pop(context, true); // ارجع لصفحة الإضافة
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final plans = const [
      {'t': '5 Ads', 'p': '\$10', 'k': '5'},
      {'t': '15 Ads', 'p': '\$25', 'k': '15'},
      {'t': '30 Ads', 'p': '\$45', 'k': '30'},
      {'t': 'Unlimited (year)', 'p': '\$199', 'k': 'unlimited'},
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('Choose a plan')),
      body: ListView.separated(
        itemCount: plans.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (context, i) {
          final it = plans[i];
          return ListTile(
            title: Text(it['t']!),
            subtitle: Text('Price: ${it['p']}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _request(context, it['k']!),
          );
        },
      ),
    );
  }
}
