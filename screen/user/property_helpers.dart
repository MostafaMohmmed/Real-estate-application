import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'propertdetalis.dart';

/// يحوّل أي نوع بايتات قادم من Firestore إلى Uint8List
Uint8List? _bytes(dynamic raw) {
  if (raw == null) return null;
  if (raw is Blob) return raw.bytes;
  if (raw is Uint8List) return raw;
  if (raw is List) return Uint8List.fromList(raw.cast<int>());
  return null;
}

/// افتح صفحة التفاصيل مع تمرير companies/{cid}/properties/{pid} في propertyDocPath
void _openDetailsWithDoc(
    BuildContext context,
    DocumentSnapshot<Map<String, dynamic>> doc,
    ) {
  final d = doc.data() ?? {};

  // doc.parent.path == companies/{companyId}/properties
  final String? companyId = doc.reference.parent.parent?.id;
  final String propId = doc.id;
  final String? path = (companyId != null)
      ? 'companies/$companyId/properties/$propId'
      : null;

  final String url = (d['imageUrl'] ?? '').toString();
  final Uint8List? bts = _bytes(d['imageBlob']);

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => Propertdetalis(
        imageUrl: url.isNotEmpty ? url : null,
        imageBytes: bts,
        title: (d['title'] ?? '—').toString(),
        // لو عندك رقم خليه كما هو، وإلا اعرض النص الموجود
        price: (d['price'] is num)
            ? '\$${(d['price'] as num)}'
            : (d['price'] ?? '-').toString(),
        location: (d['location'] ?? '').toString(),
        type: (d['type'] ?? '').toString(),

        areaSqft: (d['areaSqft'] is num) ? (d['areaSqft'] as num).toDouble() : 0.0,
        beds:     (d['beds']     is num) ? (d['beds']     as num).toInt()    : 0,
        baths:    (d['baths']    is num) ? (d['baths']    as num).toInt()    : 0,

        ownerName: (d['ownerName'] ?? 'Company').toString(),
        ownerImageUrl: (d['ownerImageUrl'] ?? '').toString(),

        // مهم لصفحة التفاصيل و ConfirmPage لاحقاً:
        ownerUid: companyId,           // (اختياري) نفس معرف الشركة
        propertyDocPath: path,         // companies/{cid}/properties/{pid}

        amenities: (d['amenities'] is Iterable)
            ? (d['amenities'] as Iterable).map((e) => e.toString()).toList()
            : const [],
        interior: (d['interior'] is Iterable)
            ? (d['interior'] as Iterable).map((e) => e.toString()).toList()
            : const [],
        construction: (d['construction'] is Iterable)
            ? (d['construction'] as Iterable).map((e) => e.toString()).toList()
            : const [],
      ),
    ),
  );
}
