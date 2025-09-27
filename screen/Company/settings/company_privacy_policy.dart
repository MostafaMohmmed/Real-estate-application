// lib/screen/company/company_privacy_policy.dart
import 'package:flutter/material.dart';
import '../../../modle/modservice.dart';

class Company_Privacy_Policy extends StatefulWidget {
  const Company_Privacy_Policy({super.key});

  @override
  State<Company_Privacy_Policy> createState() => _CompanyPrivacyPolicyState();
}

class _CompanyPrivacyPolicyState extends State<Company_Privacy_Policy> {
  // محتوى سياسة الخصوصية المخصص للشركات/المُلّاك
  final List<modservice> mod1 = [
    modservice(
      Title: 'Introduction',
      desc:
      '''This Company Privacy Policy explains how we collect, use, and protect information of property owners, agencies, and company staff using our real estate platform ("Platform"). By operating a company account, you agree to this Policy.''',
    ),
    modservice(
      Title: 'Information We Collect (Company)',
      desc:
      '''We may collect:
• Company profile data (legal name, trade name, logo, website, address).
• Owner/agent contact data (name, email, phone, role).
• KYC/business verification docs you upload (e.g., certificates).
• Listings data (property details, media, pricing, availability).
• Billing & payout data (where applicable) processed by payment providers.
• Usage and device data (logs, analytics, crash reports).''',
    ),
    modservice(
      Title: 'How We Use Company Data',
      desc:
      '''We use company data to:
• Create and manage your company profile and staff accounts.
• Publish and promote listings to buyers/tenants.
• Provide analytics and lead-management tools.
• Communicate about inquiries, updates, and policy changes.
• Detect and prevent fraud and misuse; comply with legal obligations.''',
    ),
    modservice(
      Title: 'Sharing & Disclosure',
      desc:
      '''We may share:
• Public listing information with users of the Platform and search engines.
• Leads and inquiry details with your authorized staff/agents.
• Data with service providers (hosting, analytics, messaging, payments) under contracts.
• Data when required by law or to protect rights, safety, and property.
We do not sell your personal information.''',
    ),
    modservice(
      Title: 'Your Controls',
      desc:
      '''As a company admin you can:
• Update or remove listings and media.
• Add/disable staff/agent accounts and set permissions.
• Edit company profile and contact settings.
• Request data export or deletion (subject to legal retention).''',
    ),
    modservice(
      Title: 'Media & Intellectual Property',
      desc:
      '''By uploading photos, videos, floorplans, and logos you confirm you have the right to use and publish them. You grant us a license to host and display this content on the Platform and our marketing channels as needed to operate the service.''',
    ),
    modservice(
      Title: 'Payments & Payouts',
      desc:
      '''Payment information (if any) is processed by PCI-compliant providers. We store only limited metadata (e.g., last4, brand) and payout preferences necessary to operate billing. For full card/bank details, see the provider's policy.''',
    ),
    modservice(
      Title: 'Security',
      desc:
      '''We implement reasonable technical and organizational measures (encryption in-transit, access controls, audit logs). No method is 100% secure—keep your admin and staff credentials safe and enable multi-factor authentication where available.''',
    ),
    modservice(
      Title: 'Data Retention',
      desc:
      '''We retain company and listing data while your account is active and as required for legal, tax, and fraud-prevention purposes. Media removed from listings may persist in backups for a limited period before deletion.''',
    ),
    modservice(
      Title: 'International Transfers',
      desc:
      '''Your data may be stored or processed in other countries by our service providers. We apply appropriate safeguards for such transfers where required by law.''',
    ),
    modservice(
      Title: 'Children’s Data',
      desc:
      '''Our services are not directed to children under 13 (or the age required by local law). We do not knowingly collect information from children.''',
    ),
    modservice(
      Title: 'Contact & Requests',
      desc:
      '''For privacy questions, data access or deletion requests, contact: privacy@yourcompany.com. We may ask to verify your identity and authority over the company account.''',
    ),
    modservice(
      Title: 'Effective Date',
      desc:
      '''This Policy is effective as of Sep 18, 2025 and may be updated from time to time. We will notify admins of material changes where required.''',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    const primaryColor = Color(0xff22577A);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Privacy Policy',
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
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
            // شريط "آخر تحديث"
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

            // القائمة القابلة للتمدد
            Expanded(
              child: ListView.separated(
                itemCount: mod1.length,
                separatorBuilder: (_, __) => SizedBox(height: size.height * 0.014),
                itemBuilder: (context, i) {
                  final item = mod1[i];
                  return Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: Theme(
                      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                      child: ExpansionTile(
                        leading: const Icon(Icons.description_outlined),
                        iconColor: primaryColor,
                        collapsedIconColor: Colors.grey[700],
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
                        title: Text(
                          item.Title,
                          style: TextStyle(
                            fontSize: size.width * 0.045,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        children: [
                          const SizedBox(height: 6),
                          Text(
                            item.desc,
                            textAlign: TextAlign.justify,
                            style: TextStyle(
                              fontSize: size.width * 0.038,
                              color: Colors.grey[800],
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
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
