import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:http/http.dart' as http;

/// القيمة التي نرجعها إلى صفحة الإضافة
class MapPickResult {
  final double lat;
  final double lng;
  final String address; // قد تكون فاضية لو ما عملنا Reverse Geocoding
  const MapPickResult({required this.lat, required this.lng, required this.address});
}

/// صفحة اختيار موقع مجانًا على OSM
class MapPickerPage extends StatefulWidget {
  const MapPickerPage({super.key, this.initial});

  /// تمركز مبدئي (اختياري). إن لم تُمرّر نستخدم غزة تقريبًا.
  final LatLng? initial;

  @override
  State<MapPickerPage> createState() => _MapPickerPageState();
}

class _MapPickerPageState extends State<MapPickerPage> {
  late final MapController _map;
  late LatLng _picked;

  @override
  void initState() {
    super.initState();
    _map = MapController();
    _picked = widget.initial ?? const LatLng(31.5017, 34.4668); // تمركز افتراضي
  }

  Future<String> _reverseGeocode(LatLng p) async {
    try {
      final uri = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=json'
            '&lat=${p.latitude}&lon=${p.longitude}&zoom=18&addressdetails=1',
      );
      final res = await http.get(
        uri,
        headers: const {
          // مهم لنظافة الاستخدام حسب شروط Nominatim
          'User-Agent': 'final_iug_2025/1.0 (contact: example@email.com)'
        },
      );
      if (res.statusCode == 200) {
        final json = jsonDecode(res.body) as Map<String, dynamic>;
        final disp = (json['display_name'] ?? '').toString();
        return disp;
      }
    } catch (_) {}
    return '';
  }

  Future<void> _confirm() async {
    final addr = await _reverseGeocode(_picked);
    if (!mounted) return;
    Navigator.pop(
      context,
      MapPickResult(
        lat: _picked.latitude,
        lng: _picked.longitude,
        address: addr,
      ),
    );
  }

  void _onTap(TapPosition _, LatLng p) {
    setState(() => _picked = p);
  }

  @override
  Widget build(BuildContext context) {
    final marker = Marker(
      point: _picked,
      width: 60,
      height: 60,
      alignment: Alignment.center,
      child: const Icon(Icons.location_on, size: 48, color: Colors.red),
    );

    return Scaffold(
      appBar: AppBar(title: const Text('Pick location')),
      body: FlutterMap(
        mapController: _map,
        options: MapOptions(
          initialCenter: _picked,     // v7 API
          initialZoom: 15,
          onTap: _onTap,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://{s}.tile.openstreetmap.fr/osmfr/{z}/{x}/{y}.png',
            subdomains: const ['a', 'b', 'c'],
            userAgentPackageName: 'com.example.final_iug_2025',
          ),


          MarkerLayer(markers: [marker]),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _confirm,
        label: const Text('Use this location'),
        icon: const Icon(Icons.check),
      ),
    );
  }
}
