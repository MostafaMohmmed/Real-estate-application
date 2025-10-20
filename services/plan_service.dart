import 'package:cloud_firestore/cloud_firestore.dart';

class PlanService {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> getCompanyPlan(String uid) async {
    final snap = await _db.collection('companies').doc(uid).get();
    return snap.data();
  }

  bool canPostNow(Map<String, dynamic> plan) {
    final status = (plan['planStatus'] ?? 'none').toString();
    final unlimited = plan['unlimited'] == true;
    final quota = (plan['quotaRemaining'] ?? 0) as int? ?? 0;
    if (status != 'active') return false;
    if (unlimited) return true;
    return quota > 0;
  }

  /// إنشاء طلب خطة
  Future<void> createPlanRequest({
    required String companyUid,
    required String companyName,
    required String email,
    required String planType, // '5'|'15'|'30'|'unlimited'
  }) async {
    final ref = _db.collection('plan_requests').doc();
    await ref.set({
      'companyUid': companyUid,
      'companyName': companyName,
      'companyEmail': email.toLowerCase(),
      'planType': planType,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });

    // نحدّث حالة الشركة إلى pending (إشارة)
    await _db.collection('companies').doc(companyUid).set({
      'planStatus': 'pending',
      'planType': planType,
    }, SetOptions(merge: true));
  }

  /// استهلاك خانة واحدة (Client-side Transaction)
  Future<void> consumeOneSlot(String uid) async {
    final ref = _db.collection('companies').doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      final data = snap.data() ?? {};
      final unlimited = data['unlimited'] == true;
      if (unlimited) return;
      final qRaw = data['quotaRemaining'];
      int q = 0;
      if (qRaw is int) q = qRaw;
      if (q <= 0) throw Exception('No quota.');
      tx.update(ref, {'quotaRemaining': q - 1});
    });
  }
}
