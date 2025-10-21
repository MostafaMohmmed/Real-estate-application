// lib/widgets/adaptive_navigation.dart
import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:final_iug_2025/screen/admin/AdminGate.dart';
import 'package:final_iug_2025/screen/admin/admin_panel.dart';

import 'package:final_iug_2025/screen/login_signup_app/privacy_page.dart';
import 'package:flutter/services.dart';

import 'about_page.dart';
import 'contact_page.dart';

/// AdaptiveNavigation
/// - Drawer على الشاشات الصغيرة، NavigationRail على العريضة.
/// - About/Contact/Privacy تفتح صفحات جاهزة (push).
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  static const _breakpoint = 900.0;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= _breakpoint) {
      return _Rail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      );
    } else {
      return _Drawer(
        selectedIndex: selectedIndex,
        onDestinationSelected: onDestinationSelected,
      );
    }
  }
}

/* ----------------------- Drawer ----------------------- */
class _Drawer extends StatelessWidget {
  const _Drawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Drawer(
      child: SafeArea(
        child: ListTileTheme(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // --- Header ---
              DrawerHeader(
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.06),
                ),
                margin: EdgeInsets.zero,
                padding: const EdgeInsets.fromLTRB(20, 20, 16, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    Text('RoofLine'.tr(),
                        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),

                  ],
                ),
              ),

              // --- Language ---
              ListTile(
                leading: const Icon(Icons.language),
                title: Text('language'.tr()),
                onTap: () => onDestinationSelected(0),
              ),
              Padding(
                padding: const EdgeInsets.only(left: 12.0, right: 12.0),
                child: Column(
                  children: [
                    RadioListTile<Locale>(
                      value: const Locale('ar'),
                      groupValue: context.locale,
                      title: Text('arabic'.tr()),
                      onChanged: (loc) async {
                        await context.setLocale(const Locale('ar'));
                        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                      },
                    ),
                    RadioListTile<Locale>(
                      value: const Locale('en'),
                      groupValue: context.locale,
                      title: Text('english'.tr()),
                      onChanged: (loc) async {
                        await context.setLocale(const Locale('en'));
                        if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                      },
                    ),
                  ],
                ),
              ),

              const Divider(),
              ListTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: Text('privacy'.tr()),
                onTap: () {
                  Navigator.of(context).maybePop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const PrivacyPage()));
                },
              ),

              // --- Info pages ---

              ListTile(
                leading: const Icon(Icons.support_agent_outlined),
                title: Text('contact_us'.tr()),
                onTap: () {
                  Navigator.of(context).maybePop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ContactPage()));
                },
              ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: Text('about_company'.tr()),
                onTap: () {
                  Navigator.of(context).maybePop();
                  Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AboutPage()));
                },
              ),


              const Spacer(),
              const Divider(height: 1),

              // --- Admin button (bottom) ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10),
                child: FilledButton.icon(
                  icon: const Icon(Icons.build),
                  label: Text('admin_panel'.tr()),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    Navigator.of(context).maybePop();
                    final ok = await openAdminGate(context);
                    if (ok && context.mounted) {
                      Navigator.of(context).push(MaterialPageRoute(builder: (_) => const AdminPanelPage()));
                    }
                  },
                ),
              ),

              // --- Logout ---
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8),
                child: OutlinedButton.icon(
                  icon: const Icon(Icons.logout, color: Colors.red),
                  label: Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  onPressed: () async {
                    try {
                      // تسجيل الخروج من Firebase أولاً
                      await FirebaseAuth.instance.signOut();
                    } catch (_) {}

                    // ثم الخروج من التطبيق نهائياً
                    SystemNavigator.pop();
                  },
                ),
              ),

              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

/* ----------------------- NavigationRail ----------------------- */
class _Rail extends StatelessWidget {
  const _Rail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
        child: Column(
          children: [
            Text('RoofLine'.tr(),
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text('app_tagline'.tr(), style: theme.textTheme.bodySmall),
          ],
        ),
      ),
      trailing: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton.filledTonal(
            tooltip: 'admin_panel'.tr(),
            icon: const Icon(Icons.build),
            onPressed: () async {
              final ok = await openAdminGate(context);
              if (ok && context.mounted) {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminPanelPage()));
              }
            },
          ),
          const SizedBox(height: 6),
          Text('admin_panel'.tr(), style: theme.textTheme.labelSmall),
          const SizedBox(height: 8),
        ],
      ),
      destinations: [

        NavigationRailDestination(
          icon: const Icon(Icons.language),
          selectedIcon: const Icon(Icons.translate),
          label: Text('language'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.privacy_tip_outlined),
          selectedIcon: const Icon(Icons.privacy_tip),
          label: Text('privacy'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.support_agent_outlined),
          selectedIcon: const Icon(Icons.support_agent),
          label: Text('contact_us'.tr()),
        ),
        NavigationRailDestination(
          icon: const Icon(Icons.info_outline),
          selectedIcon: const Icon(Icons.info),
          label: Text('about_company'.tr()),
        ),


        NavigationRailDestination(
          icon: const Icon(Icons.logout),
          selectedIcon: const Icon(Icons.logout),
          label: Text('logout'.tr()),
        ),
      ],
    );
  }
}

/* ----------------------- Helpers ----------------------- */

bool isWideScreen(BuildContext context) => MediaQuery.of(context).size.width >= 900;
