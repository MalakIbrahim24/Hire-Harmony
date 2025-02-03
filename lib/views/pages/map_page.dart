
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MapScreen extends StatefulWidget {
  final String employeeId;

  const MapScreen({Key? key, required this.employeeId}) : super(key: key);

  @override
  _MapScreenState createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  double? latitude;
  double? longitude;
  String? cityName;
  String? countryName;
  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeLocation();
  }

  Future<void> _fetchEmployeeLocation() async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      DocumentSnapshot<Map<String, dynamic>> document =
          await firestore.collection('users').doc(widget.employeeId).get();

      if (document.exists) {
        Map<String, dynamic>? data = document.data();
        if (data != null && data['location'] != null) {
          double lat = double.parse(data['location']['latitude'].toString());
          double lng = double.parse(data['location']['longitude'].toString());

          setState(() {
            latitude = lat;
            longitude = lng;
          });

          // استدعاء الدالة لجلب اسم المدينة والدولة
          await _fetchCityAndCountry(lat, lng);
        } else {
          print("⚠️ Location data not found.");
        }
      } else {
        print("⚠️ Document does not exist.");
      }
    } catch (e) {
      print("❌ Error fetching data: $e");
    }

    setState(() {
      isLoading = false;
    });
  }

Future<void> _fetchCityAndCountry(double lat, double lng) async {
  final String url = "https://nominatim.openstreetmap.org/reverse?format=json&lat=$lat&lon=$lng";

  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final data = json.decode(response.body);

      setState(() {
        cityName = data['address']['city'] ??
            data['address']['town'] ?? // إذا لم تكن city موجودة، استخدم town
            data['address']['village'] ?? // إذا لم تكن town موجودة، استخدم village
            data['address']['hamlet'] ?? // إذا لم تكن village موجودة، استخدم hamlet
            data['address']['suburb'] ?? // إذا لم تكن hamlet موجودة، استخدم suburb
            "غير معروف";

        countryName = data['address']['country'] ?? "غير معروف";
      });

    } 
  } catch (e) {
    print("❌ Exception: $e");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Map Location"),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : latitude != null && longitude != null
              ? Column(
                  children: [
                    Expanded(
                      child: FlutterMap(
                        mapController: MapController(),
                        options: MapOptions(
                          initialCenter: LatLng(latitude!, longitude!),
                          initialZoom: 14.0,
                        ),
                        children: [
                          TileLayer(
                            urlTemplate: "https://tile.openstreetmap.org/{z}/{x}/{y}.png",
                          ),
                          MarkerLayer(
                            markers: [
                              Marker(
                                width: 50.0,
                                height: 50.0,
                                point: LatLng(latitude!, longitude!),
                                child: const Icon(
                                  Icons.location_pin,
                                  color: Colors.red,
                                  size: 40,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        "🌍country ${countryName}",
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                )
              : const Center(
                  child: Text(
                    "Location not found.",
                    style: TextStyle(fontSize: 16),
                  ),
                ),
    );
  }
}
