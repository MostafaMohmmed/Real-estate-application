import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'add_property_page.dart';
import 'settings/companysettings.dart';
import 'edit_property_page.dart';
import 'package:final_iug_2025/services/company_bootstrap.dart';

class CompanyHomePage extends StatefulWidget {
  const CompanyHomePage({super.key});

  @override
  State<CompanyHomePage> createState() => _CompanyHomePageState();
}

class _CompanyHomePageState extends State<CompanyHomePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _auth = FirebaseAuth.instance;

  Map<String, dynamic>? _companyData;
  bool _loadingCompany = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // يضمن وثيقة الشركة + 5 مجانًا أول مرة
    CompanyBootstrap.ensureCompanyDoc(initialFree: 5);
    _loadCompanyPlan();
  }

  Future<void> _loadCompanyPlan() async {
    final user = _auth.currentUser;
    if (user == null) return;
    final snap = await FirebaseFirestore.instance
        .collection('companies').doc(user.uid).get();
    if (!mounted) return;
    setState(() {
      _companyData = snap.data() ?? {};
      _loadingCompany = false;
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Uint8List? _bytes(dynamic raw) {
    if (raw == null) return null;
    if (raw is Blob) return raw.bytes;
    if (raw is Uint8List) return raw;
    if (raw is List) return Uint8List.fromList(raw.cast<int>());
    return null;
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> _companyPropsStream({
    required String uid,
    required String type,
  }) {
    return FirebaseFirestore.instance
        .collection('companies')
        .doc(uid)
        .collection('properties')
        .where('type', isEqualTo: type)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<bool> _confirmDelete(BuildContext context) async {
    bool confirmed = false;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete property?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () { confirmed = false; Navigator.pop(context); },
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () { confirmed = true; Navigator.pop(context); },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    return confirmed;
  }

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _buildPlanBadge(Map<String, dynamic> data) {
    final status    = (data['planStatus'] ?? 'none').toString();
    final planType  = (data['planType'] ?? '').toString();
    final raw       = data['quotaRemaining'];
    final quota     = raw is int ? raw : int.tryParse(raw?.toString() ?? '') ?? 0;
    final unlimited = data['unlimited'] == true;

    Color bg;
    String label;
    switch (status) {
      case 'active':
        bg = Colors.green.shade600;
        label = unlimited
            ? 'Unlimited Plan'
            : (planType == 'free'
            ? 'Free plan • $quota left'
            : 'Active: $planType • $quota left');
        break;
      case 'pending':
        bg = Colors.orange.shade600;
        label = 'Pending approval';
        break;
      default:
        bg = Colors.grey.shade500;
        label = 'No active plan';
    }

    return Container(
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final user = _auth.currentUser;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          title: const Text('Company Console', style: TextStyle(color: Colors.black)),
          centerTitle: true,
        ),
        body: const Center(child: Text('Please sign in as a company to continue')),
      );
    }

    return Scaffold(
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xff22577A),
        onPressed: () async {
          await Navigator.push(
              context, MaterialPageRoute(builder: (_) => const AddPropertyPage()));
          await _loadCompanyPlan(); // تحدّث الشارة بعد الرجوع
        },
        child: const Icon(Icons.add, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            IconButton(icon: const Icon(Icons.home), onPressed: () {}),
            SizedBox(width: size.width * 0.1),
            IconButton(
              icon: const Icon(Icons.settings),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const CompanySettings()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Hello!',
              style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.bold,
                fontSize: size.width * 0.045,
              ),
            ),
            Text(user.displayName ?? 'Your Company',
              style: TextStyle(
                color: Colors.black, fontWeight: FontWeight.w500,
                fontSize: size.width * 0.04,
              ),
            ),
            if (!_loadingCompany && _companyData != null)
              _buildPlanBadge(_companyData!)
            else
              const Padding(
                padding: EdgeInsets.only(top: 4.0),
                child: SizedBox(
                  height: 16, width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
          ],
        ),
        actions: const [
          Icon(Icons.bookmark_sharp, color: Colors.blue),
          SizedBox(width: 12),
          CircleAvatar(backgroundImage: AssetImage('assets/images/personal.png')),
          SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.blue,
          unselectedLabelColor: Colors.grey,
          indicatorColor: Colors.blue,
          tabs: const [
            Tab(text: "House"),
            Tab(text: "Apartment"),
            Tab(text: "Office"),
            Tab(text: "Land"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: ["House", "Apartment", "Office", "Land"].map((type) {
          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: _companyPropsStream(uid: user.uid, type: type),
            builder: (context, snapshot) {
              if (snapshot.hasError) {
                return const Center(child: Text('Error loading data'));
              }
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snapshot.data?.docs ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text("No properties yet"));
              }

              return ListView.builder(
                padding: EdgeInsets.all(size.width * 0.03),
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final doc  = docs[index];
                  final data = doc.data();

                  final String imageUrl = (data['imageUrl'] ?? '').toString();
                  final Uint8List? imageBlob = _bytes(data['imageBlob']);

                  final String title    = (data['title'] ?? '').toString();
                  final String pType    = (data['type'] ?? '').toString();
                  final String location = (data['location'] ?? '').toString();
                  final String desc     = (data['description'] ?? '').toString();
                  final String priceStr = (data['price'] ?? '').toString();

                  return Card(
                    margin: EdgeInsets.only(bottom: size.height * 0.012),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 2,
                    clipBehavior: Clip.antiAlias,
                    child: SizedBox(
                      height: size.height * 0.11,
                      child: Row(
                        children: [
                          // image
                          Flexible(
                            flex: 26,
                            child: Container(
                              height: double.infinity,
                              color: Colors.grey[100],
                              child: ClipRRect(
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(10),
                                  bottomLeft: Radius.circular(10),
                                ),
                                child: Builder(
                                  builder: (_) {
                                    if (imageBlob != null) {
                                      return Image.memory(
                                        imageBlob, fit: BoxFit.cover,
                                        width: double.infinity, height: double.infinity,
                                      );
                                    }
                                    if (imageUrl.isNotEmpty) {
                                      return Image.network(
                                        imageUrl, fit: BoxFit.cover,
                                        width: double.infinity, height: double.infinity,
                                        errorBuilder: (_, __, ___) => Container(
                                          color: Colors.grey[200],
                                          child: const Center(
                                            child: Icon(Icons.broken_image, size: 34, color: Colors.grey),
                                          ),
                                        ),
                                      );
                                    }
                                    return Container(
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.image, size: 34, color: Colors.grey),
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ),
                          ),

                          // text
                          Flexible(
                            flex: 52,
                            child: Padding(
                              padding: EdgeInsets.symmetric(
                                horizontal: size.width * 0.03,
                                vertical: size.height * 0.012,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Text(
                                          title,
                                          style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: size.width * 0.038,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: Colors.orange.shade50,
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          pType,
                                          style: TextStyle(
                                            color: Colors.deepOrange.shade700,
                                            fontSize: size.width * 0.028,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    children: [
                                      Icon(Icons.location_on, size: size.width * 0.032, color: Colors.grey[600]),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          location,
                                          style: TextStyle(color: Colors.grey[700], fontSize: size.width * 0.032),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const Spacer(),
                                  Text(
                                    desc,
                                    style: TextStyle(color: Colors.grey[800], fontSize: size.width * 0.032),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // price + actions
                          Flexible(
                            flex: 22,
                            child: Padding(
                              padding: EdgeInsets.symmetric(horizontal: size.width * 0.02),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      priceStr.isEmpty ? '-' : "\$$priceStr",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w800,
                                        fontSize: size.width * 0.042,
                                        color: Colors.blue.shade800,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      SizedBox(
                                        width: size.width * 0.07, height: size.width * 0.07,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints.tightFor(
                                            width: size.width * 0.07, height: size.width * 0.07,
                                          ),
                                          icon: const Icon(Icons.edit, size: 18),
                                          color: Colors.green,
                                          tooltip: 'Edit',
                                          onPressed: () async {
                                            final updated = await Navigator.push<bool>(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => EditPropertyPage(
                                                    docRef: doc.reference, initialData: data),
                                              ),
                                            );
                                            if (updated == true) {
                                              _showSnack('Property updated ✔');
                                            }
                                          },
                                        ),
                                      ),
                                      SizedBox(width: size.width * 0.01),
                                      SizedBox(
                                        width: size.width * 0.07, height: size.width * 0.07,
                                        child: IconButton(
                                          padding: EdgeInsets.zero,
                                          constraints: BoxConstraints.tightFor(
                                            width: size.width * 0.07, height: size.width * 0.07,
                                          ),
                                          icon: const Icon(Icons.delete, size: 18),
                                          color: Colors.red,
                                          tooltip: 'Delete',
                                          onPressed: () async {
                                            final ok = await _confirmDelete(context);
                                            if (!ok) return;
                                            try {
                                              await doc.reference.delete();
                                              _showSnack('Property deleted ✔');
                                            } catch (e) {
                                              _showSnack('Delete failed: $e');
                                            }
                                          },
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        }).toList(),
      ),
    );
  }
}
