import 'package:flutter/material.dart';
import '../../../../modle/modservice.dart';

class Privacy_Policy extends StatefulWidget {
  const Privacy_Policy({super.key});

  @override
  State<Privacy_Policy> createState() => _CompanyPrivacyPolicyState();
}

class _CompanyPrivacyPolicyState extends State<Privacy_Policy> {
  // ======================== NEW: محتوى حقيقي للـ Privacy Policy ========================
  // الشرح (عربي): استبدلت الـ dummy content بقائمة أقسام واضحة ومفيدة لتطبيق عقاري:
  // - كل عنصر يحتوي Title و desc (إنجليزي للواجهة)، وتقدر توسّع/تطوي النص بتحكّم UI.
  final List<modservice> mod1 = [
    modservice(
      Title: 'Introduction',
      desc: '''This Privacy Policy explains how we collect, use, and protect your information when you use our real estate marketplace app (the "App"). By using the App, you agree to this Policy.''',
    ),
    modservice(
      Title: 'Information We Collect',
      desc: '''We may collect:
• Account details (name, email, phone).
• Listing details (property address, price, features).
• Photos & media you upload for listings or your profile.
• Approximate location (to show nearby properties) if enabled.
• Usage data (app interactions, crash logs) and device identifiers.''',
    ),
    modservice(
      Title: 'How We Use Your Information',
      desc: '''We use your info to:
• Operate and improve the App and our services.
• Create and manage your account and listings.
• Show relevant properties and recommendations.
• Communicate with you about updates, offers, or support.
• Ensure safety, prevent fraud, and enforce our Terms.''',
    ),
    modservice(
      Title: 'Sharing Your Information',
      desc: '''We may share:
• With buyers/sellers/agents when you interact or submit a listing.
• With service providers (hosting, analytics, payments) under contracts.
• When required by law or to protect rights, safety, and property.
We do not sell your personal information.''',
    ),
    modservice(
      Title: 'Your Choices & Rights',
      desc: '''You can:
• Access, update, or delete your profile and listings.
• Manage notifications in settings.
• Disable location access from your device settings.
• Request data export or deletion by contacting us.''',
    ),
    modservice(
      Title: 'Data Retention',
      desc: '''We keep your data as long as your account is active or as needed to provide the App and comply with legal obligations. We may keep minimal records for fraud prevention and security.''',
    ),
    modservice(
      Title: 'Security',
      desc: '''We use reasonable technical and organizational measures to protect your data. However, no method of transmission or storage is 100% secure.''',
    ),
    modservice(
      Title: 'Children’s Privacy',
      desc: '''The App is not directed to children under 13 (or the age required by local law). We do not knowingly collect information from children.''',
    ),
    modservice(
      Title: 'International Transfers',
      desc: '''Your data may be processed in countries other than your own. We take steps to ensure appropriate safeguards for such transfers.''',
    ),
    modservice(
      Title: 'Contact Us',
      desc: '''If you have questions about this Policy or your data, contact us at: support@yourapp.com''',
    ),
    modservice(
      Title: 'Effective Date',
      desc: '''This Policy is effective as of Sep 18, 2025 and may be updated from time to time. We will notify you of material changes where required.''',
    ),
  ];
  // ====================================================================================

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xff22577A);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          // ======================== NEW: تغيير العنوان ليعكس المحتوى ========================
          // الشرح (عربي): خليته "Privacy Policy" بدل "Terms of Service" بما إن المحتوى سياسة خصوصية.
          'Privacy Policy',
          // =================================================================================
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        centerTitle: true,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.05,
          vertical: size.height * 0.02,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ======================== NEW: بانر Last Updated ========================
            // الشرح (عربي): شريط خفيف في الأعلى يوضح تاريخ آخر تحديث للسياسة—لمسة احترافية.
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(size.width * 0.035),
              margin: EdgeInsets.only(bottom: size.height * 0.015),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: primaryColor.withOpacity(0.15)),
              ),
              child: Row(
                children: [
                  Icon(Icons.privacy_tip_outlined, color: primaryColor),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Last updated: Sep 18, 2025',
                      style: TextStyle(
                        color: Colors.black87,
                        fontSize: size.width * 0.036,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // =========================================================================

            Expanded(
              // ======================== NEW: ListView.separated داخل Expanded ========================
              // الشرح (عربي): حطّيناه داخل Expanded ليملأ المساحة المتاحة ويكون Scrollable بسلاسة.
              child: ListView.separated(
                itemCount: mod1.length,
                separatorBuilder: (context, index) =>
                    SizedBox(height: size.height * 0.014),
                itemBuilder: (context, index) {
                  final item = mod1[index];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    // ======================== NEW: استخدام ExpansionTile ========================
                    // الشرح (عربي): أفضل لقابلية القراءة—العنوان ظاهر، والوصف يظهر عند التوسيع.
                    child: Theme(
                      // الشرح: تصغير مساحة التوسيع الافتراضية وتحسين التباعد
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        tilePadding: EdgeInsets.symmetric(
                          horizontal: size.width * 0.04,
                          vertical: size.height * 0.006,
                        ),
                        childrenPadding: EdgeInsets.fromLTRB(
                          size.width * 0.04,
                          0,
                          size.width * 0.04,
                          size.height * 0.018,
                        ),
                        leading: const Icon(Icons.description_outlined),
                        title: Text(
                          item.Title,
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        iconColor: primaryColor,
                        collapsedIconColor: Colors.grey[700],
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            item.desc,
                            style: TextStyle(
                              fontSize: size.width * 0.038,
                              color: Colors.grey[800],
                              height: 1.45,
                            ),
                            textAlign: TextAlign.justify,
                          ),
                        ],
                      ),
                    ),
                    // =========================================================================
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
