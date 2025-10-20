import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CompanyBootstrap {
  static final _db = FirebaseFirestore.instance;

  /// نادِها بعد تسجيل الدخول مباشرة (مرة واحدة لكل شركة)
  static Future<void> ensureCompanyDoc({int initialFree = 5}) async {
    final u = FirebaseAuth.instance.currentUser;
    if (u == null) return;

    final ref = _db.collection('companies').doc(u.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      // أول مرة: نفعل الخطة المجانية
      await ref.set({
        'displayName': u.displayName ?? 'Company',
        'email': (u.email ?? '').toLowerCase(),

        // الخطة المجانية تبدأ فعّالة
        'planStatus': initialFree > 0 ? 'active' : 'none',  // none|pending|active
        'planType'  : initialFree > 0 ? 'free'   : '',
        'quotaRemaining': initialFree,                      // 5 مجانًا
        'unlimited' : false,

        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // عندك وثيقة قديمة بلا حقول الخطة؟ نزبطها بدون كسر القيم الموجودة.
      final d = snap.data() ?? {};
      final hasPlanStatus = d.containsKey('planStatus');
      final hasQuota      = d.containsKey('quotaRemaining');
      final hasType       = d.containsKey('planType');
      final hasUnlimited  = d.containsKey('unlimited');

      if (!hasPlanStatus || !hasQuota || !hasType || !hasUnlimited) {
        await ref.set({
          if (!hasPlanStatus) 'planStatus': initialFree > 0 ? 'active' : 'none',
          if (!hasType)       'planType'  : initialFree > 0 ? 'free'   : '',
          if (!hasQuota)      'quotaRemaining': initialFree,
          if (!hasUnlimited)  'unlimited' : false,
        }, SetOptions(merge: true));
      }
    }
  }
}
