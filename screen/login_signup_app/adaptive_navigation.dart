import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';

import '../admin/AdminGate.dart';
import '../admin/admin_panel.dart';

/// نفس العناصر تظهر كـ Drawer على الموبايل وRail على الشاشات الكبيرة
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
        onDestinationSelected: (i) {
          Navigator.of(context).maybePop();
          onDestinationSelected(i);
        },
      );
    }
  }
}

class _Drawer extends StatelessWidget {
  const _Drawer({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: _CommonList(
          selectedIndex: selectedIndex,
          onDestinationSelected: onDestinationSelected,
          isRail: false,
        ),
      ),
    );
  }
}

class _Rail extends StatelessWidget {
  const _Rail({
    required this.selectedIndex,
    required this.onDestinationSelected,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    return NavigationRail(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      labelType: NavigationRailLabelType.all,
      leading: Padding(
        padding: const EdgeInsets.only(top: 8.0),
        child: Text(
          'RoofLine'.tr(),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ),
      trailing: Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Divider(),
            IconButton.filledTonal(
              tooltip: 'admin_panel'.tr(),
              icon: const Icon(Icons.build),
              onPressed: () async {
                final ok = await openAdminGate(context);
                if (ok && context.mounted) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminPanelPage()),
                  );
                }
              },
            ),
            const SizedBox(height: 4),
            Text('admin_panel'.tr(), style: Theme.of(context).textTheme.labelSmall),
          ],
        ),
      ),
      destinations: const [
        NavigationRailDestination(
          icon: Icon(Icons.language),
          selectedIcon: Icon(Icons.translate),
          label: Text('Language'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.info_outline),
          selectedIcon: Icon(Icons.info),
          label: Text('About'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.support_agent_outlined),
          selectedIcon: Icon(Icons.support_agent),
          label: Text('Contact'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.privacy_tip_outlined),
          selectedIcon: Icon(Icons.privacy_tip),
          label: Text('Privacy'),
        ),
        NavigationRailDestination(
          icon: Icon(Icons.logout),
          selectedIcon: Icon(Icons.logout),
          label: Text('Logout'),
        ),
      ],
    );
  }
}

class _CommonList extends StatelessWidget {
  const _CommonList({
    required this.selectedIndex,
    required this.onDestinationSelected,
    required this.isRail,
  });

  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isRail;

  @override
  Widget build(BuildContext context) {
    final locale = context.locale;

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      children: [
        ListTile(
          title: Text(
            'RoofLine'.tr(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        const Divider(),

        ListTile(
          leading: const Icon(Icons.language),
          title: Text('language'.tr()),
          selected: selectedIndex == 0,
          onTap: () => onDestinationSelected(0),
        ),
        Padding(
          padding: const EdgeInsetsDirectional.only(start: 16.0, end: 8),
          child: Column(
            children: [
              RadioListTile<Locale>(
                value: const Locale('ar'),
                groupValue: locale,
                title: Text('arabic'.tr()),
                onChanged: (loc) async {
                  await context.setLocale(const Locale('ar'));
                  if (Navigator.of(context).canPop()) Navigator.of(context).pop();
                },
              ),
              RadioListTile<Locale>(
                value: const Locale('en'),
                groupValue: locale,
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
          leading: const Icon(Icons.info_outline),
          title: Text('about_company'.tr()),
          selected: selectedIndex == 1,
          onTap: () => onDestinationSelected(1),
        ),
        ListTile(
          leading: const Icon(Icons.support_agent_outlined),
          title: Text('contact_us'.tr()),
          selected: selectedIndex == 2,
          onTap: () => onDestinationSelected(2),
        ),
        ListTile(
          leading: const Icon(Icons.privacy_tip_outlined),
          title: Text('privacy'.tr()),
          selected: selectedIndex == 3,
          onTap: () => onDestinationSelected(3),
        ),

        const Divider(),

        // Admin panel من الدروار
        ListTile(
          leading: const Icon(Icons.build),
          title: Text('admin_panel'.tr()),
          onTap: () async {
            Navigator.of(context).maybePop();
            final ok = await openAdminGate(context);
            if (ok && context.mounted) {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AdminPanelPage()),
              );
            }
          },
        ),

        const Divider(),

        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: Text('logout'.tr(), style: const TextStyle(color: Colors.red)),
          selected: selectedIndex == 4,
          onTap: () => onDestinationSelected(4),
        ),
      ],
    );
  }
}

bool isWideScreen(BuildContext context) =>
    MediaQuery.of(context).size.width >= _Breakpoints.rail;

class _Breakpoints {
  static const rail = 900.0;
}
