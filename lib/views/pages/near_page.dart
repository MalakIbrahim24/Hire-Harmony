import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';
import 'package:hire_harmony/views/pages/map_page.dart';

class NearestUsersPage extends StatefulWidget {
  const NearestUsersPage({Key? key}) : super(key: key);

  @override
  _NearestUsersPageState createState() => _NearestUsersPageState();
}

class _NearestUsersPageState extends State<NearestUsersPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  final AuthServices authService = AuthServicesImpl();
@override
void initState () {
  super.initState();
  requestLocationPermission();
}
  /// 🔹 Calculate distance between two points using Haversine formula
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = (lat2 - lat1) * pi / 180.0;
    double dLon = (lon2 - lon1) * pi / 180.0;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) * cos(lat2 * pi / 180.0) *
        sin(dLon / 2) * sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

Future<void> requestLocationPermission() async {
  LocationPermission permission = await Geolocator.checkPermission();
  if (permission == LocationPermission.denied) {
    permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.deniedForever) {
      print("تم رفض إذن الموقع بشكل دائم. يرجى تغييره من الإعدادات.");
    } else if (permission == LocationPermission.denied) {
      print("إذن الموقع مرفوض.");
    } else {
      print("إذن الموقع ممنوح.");
    }
  }
}

  /// 🔹 Fetch nearest 5 employees
  Future<List<Map<String, dynamic>>> getNearestUsers() async {
    String currentUserID = authService.getCurrentUser()!.uid;
    Position position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    double userLat = position.latitude;
    double userLon = position.longitude;

    QuerySnapshot snapshot = await firestore.collection('users').where('role', isEqualTo: 'employee').get();
    List<Map<String, dynamic>> users = [];

    for (var doc in snapshot.docs) {
      if (doc.id == currentUserID) continue;

      var data = doc.data() as Map<String, dynamic>?;
      if (data == null || !data.containsKey('location') || data['location'] == null) {
        continue;
      }

      Map<String, dynamic> location = data['location'] as Map<String, dynamic>;
      String profileImage = data.containsKey('img') ? data['img'] : '';
      if (location.containsKey('latitude') && location.containsKey('longitude')) {
        double lat = double.tryParse(location['latitude'].toString()) ?? 0.0;
        double lon = double.tryParse(location['longitude'].toString()) ?? 0.0;

        double distance = calculateDistance(userLat, userLon, lat, lon);

        users.add({
          'id': doc.id,
          'name': data['name'] ?? 'Unknown User',
          'img': profileImage,
          'latitude': lat,
          'longitude': lon,
          'distance': distance
        });
      }
    }

    users.sort((a, b) => a['distance'].compareTo(b['distance']));
    return users.take(5).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nearest Employees', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        backgroundColor: AppColors().orange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: getNearestUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('An error occurred: ${snapshot.error}'));
          }

          List<Map<String, dynamic>>? users = snapshot.data;
          if (users == null || users.isEmpty) {
            return const Center(child: Text('No nearby employees found'));
          }

          return ListView.builder(
            itemCount: users.length,
            itemBuilder: (context, index) {
              var user = users[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewEmpProfilePage(employeeId: user['id']),
                    ),
                  );
                },
                child: Card(
                  color: Colors.white,
                  margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: CircleAvatar(
                          backgroundImage:  NetworkImage(user['img']),
                        ),
                        title: Text(user['name'],
                            style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black)),
                        subtitle: Text(
                          "Distance: ${user['distance'].toStringAsFixed(2)} km",
                          style: const TextStyle(color: Colors.grey),
                        ),
                        trailing: const Icon(Icons.arrow_forward_ios, color: Colors.grey),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: ElevatedButton(
                          onPressed: () {
                            // TODO: Implement location viewing
/* Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MapPage(),
                    ),
                  );*/
                  Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) =>  MapScreen(employeeId: user['id']),
  ),
);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors().orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('See Location', style: TextStyle(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      backgroundColor: Colors.white,
    );
  }
}