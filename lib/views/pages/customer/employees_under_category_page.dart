/*import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';

class EmployeesUnderCategoryPage extends StatelessWidget {
  final String categoryName; // اسم الفئة وليس الـ ID

  const EmployeesUnderCategoryPage({required this.categoryName, super.key});

  Future<List<Map<String, dynamic>>> fetchEmployeesByCategory(String categoryName) async {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      // 🔹 1. البحث عن مستند `category` باستخدام `name`
      QuerySnapshot categorySnapshot = await firestore
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      if (categorySnapshot.docs.isEmpty) {
        print("⚠ No category found with name: $categoryName");
        return [];
      }

      DocumentSnapshot categoryDoc = categorySnapshot.docs.first;
      List<dynamic> workerIds = categoryDoc['workers'] ?? []; // 🔹 جلب الـ `workers`

      if (workerIds.isEmpty) {
        print("⚠ No workers found for category: $categoryName");
        return [];
      }

      // 🔹 2. جلب بيانات المستخدمين بناءً على قائمة `workers`
      QuerySnapshot usersSnapshot = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: workerIds) // 🔹 جلب المستخدمين من القائمة
          .get();

      List<Map<String, dynamic>> employees = usersSnapshot.docs
          .map((userDoc) => {
                'uid': userDoc.id,
                ...userDoc.data() as Map<String, dynamic>,
              })
          .toList();

      print("✅ Found ${employees.length} employees for category: $categoryName");

      return employees;
    } catch (e) {
      print("❌ Error fetching employees: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Employees for $categoryName',
          style: GoogleFonts.montserratAlternates(
            color: AppColors().white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors().white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppColors().orange,
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchEmployeesByCategory(categoryName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final employees = snapshot.data;
          if (employees == null || employees.isEmpty) {
            return  Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                   Image.asset(
                     'lib/assets/images/logo_orange.PNG',
                     width: 120, // Bigger logo for better visibility
                     height: 120,
                   ),
                         const Text('No employees found for this category'),
              
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              final employeeName = employee['name'] ?? 'Unknown Employee';
              final employeeEmail = employee['email'] ?? 'No Email';
              final employeeImg = employee['img'] ?? '';
              final employeeId = employee['uid'];

              return Card(
                margin: const EdgeInsets.symmetric(
                    vertical: 8.0, horizontal: 12.0),
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundImage: employeeImg.isNotEmpty
                            ? NetworkImage(employeeImg)
                            : null,
                        backgroundColor: AppColors().navy,
                        child: employeeImg.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              employeeName,
                              style: GoogleFonts.montserratAlternates(
                                textStyle: TextStyle(
                                  fontSize: 16,
                                  color: AppColors().navy,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Email: $employeeEmail',
                              style: GoogleFonts.montserratAlternates(
                                textStyle: TextStyle(
                                  fontSize: 10,
                                  color: AppColors().grey2,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors().orange,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                        ),
                        onPressed: () {
                          if (employeeId != null) {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => ViewEmpProfilePage(
                                  employeeId: employeeId,
                                ),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'View Profile',
                          style: GoogleFonts.montserratAlternates(
                            textStyle: TextStyle(
                              fontSize: 14,
                              color: AppColors().white,
                            ),
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
      ),
    );
  }
}*/
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';
import 'package:hire_harmony/views/pages/map_page.dart';
import 'package:hire_harmony/views/widgets/employee/shimmer.dart';
import 'package:shimmer/shimmer.dart';

class EmployeesUnderCategoryPage extends StatefulWidget {
  final String categoryName; // اسم الفئة

  const EmployeesUnderCategoryPage({required this.categoryName, super.key});

  @override
  _EmployeesUnderCategoryPageState createState() =>
      _EmployeesUnderCategoryPageState();
}

class _EmployeesUnderCategoryPageState
    extends State<EmployeesUnderCategoryPage> {
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  bool filterByDistance = false; // 🔹 متغير لتفعيل الفلترة
  Position? currentPosition; // 🔹 موقع المستخدم الحالي
  String selectedFilter = "None"; // 🔹 الفلتر الافتراضي

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
  }

  /// 🔹 Fetch user location from Firestore
  Future<void> _getCurrentLocation() async {
    try {
      final User? user =
          FirebaseAuth.instance.currentUser; // ✅ Get current user
      if (user == null) {
        print("❌ No authenticated user found.");
        return;
      }

      final String userId = user.uid; // ✅ Get user UID from FirebaseAuth
      DocumentSnapshot userDoc =
          await firestore.collection('users').doc(userId).get();

      if (userDoc.exists) {
        final data = userDoc.data() as Map<String, dynamic>;

        if (data.containsKey('location') &&
            data['location'] is Map<String, dynamic>) {
          var location = data['location'] as Map<String, dynamic>;
          double latitude =
              double.tryParse(location['latitude'].toString()) ?? 0.0;
          double longitude =
              double.tryParse(location['longitude'].toString()) ?? 0.0;

          if (latitude != 0.0 && longitude != 0.0) {
            setState(() {
              currentPosition = Position(
                latitude: latitude,
                longitude: longitude,
                timestamp: DateTime.now(),
                accuracy: 0.0,
                altitude: 0.0,
                altitudeAccuracy: 0.0, // ✅ Required parameter
                heading: 0.0,
                headingAccuracy: 0.0, // ✅ Required parameter
                speed: 0.0,
                speedAccuracy: 0.0,
              );
            });

            print("✅ Location fetched from Firestore: ($latitude, $longitude)");
          } else {
            print("⚠ Location data is invalid.");
          }
        } else {
          print("⚠ Location field is missing in Firestore.");
        }
      } else {
        print("❌ User document not found.");
      }
    } catch (e) {
      print("❌ Error getting location from Firestore: $e");
    }
  }

  /// 🔹 حساب المسافة بين نقطتين باستخدام معادلة Haversine
  double calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371;
    double dLat = (lat2 - lat1) * pi / 180.0;
    double dLon = (lon2 - lon1) * pi / 180.0;

    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180.0) *
            cos(lat2 * pi / 180.0) *
            sin(dLon / 2) *
            sin(dLon / 2);

    double c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  Future<List<Map<String, dynamic>>> fetchEmployeesByCategory(
      String categoryName) async {
    try {
      QuerySnapshot categorySnapshot = await firestore
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      if (categorySnapshot.docs.isEmpty) {
        print("⚠ No category found with name: $categoryName");
        return [];
      }

      DocumentSnapshot categoryDoc = categorySnapshot.docs.first;
      List<dynamic> workerIds = categoryDoc['workers'] ?? [];

      if (workerIds.isEmpty) {
        print("⚠ No workers found for category: $categoryName");
        return [];
      }

      QuerySnapshot usersSnapshot = await firestore
          .collection('users')
          .where(FieldPath.documentId, whereIn: workerIds)
          .get();

      List<Map<String, dynamic>> employees = [];

      for (var userDoc in usersSnapshot.docs) {
        final data = userDoc.data() as Map<String, dynamic>;

        double distance = 0.0;
        double rating = 0.0;

        // ✅ تحويل rating من String إلى double
        if (data.containsKey('rating') && data['rating'] is String) {
          rating = double.tryParse(data['rating'].toString()) ?? 0.0;
        }

        // ✅ حساب المسافة إذا كان الموقع متاحًا
        if (currentPosition != null &&
            data.containsKey('location') &&
            data['location'] is Map<String, dynamic>) {
          var location = data['location'] as Map<String, dynamic>;
          double lat = double.tryParse(location['latitude'].toString()) ?? 0.0;
          double lon = double.tryParse(location['longitude'].toString()) ?? 0.0;

          if (lat != 0.0 && lon != 0.0) {
            distance = calculateDistance(currentPosition!.latitude,
                currentPosition!.longitude, lat, lon);
          }
        }

        employees.add({
          'uid': userDoc.id,
          ...data,
          'distance': distance,
          'rating': rating, 
        });
      }

      if (selectedFilter == "Near") {
        employees.sort((a, b) => a['distance'].compareTo(b['distance']));
      } else if (selectedFilter == "Rating") {
        employees.sort((a, b) => b['rating'].compareTo(a['rating']));
      }

      return employees;
    } catch (e) {
      print("❌ Error fetching employees: $e");
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Employees for ${widget.categoryName}',
          style: GoogleFonts.montserratAlternates(
            color: AppColors().white,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors().white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: AppColors().orange,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.filter_list, color: AppColors().white),
            onSelected: (String value) {
              setState(() {
                selectedFilter = value;
              });
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem(
                value: "None",
                child: Text("No Filter"),
              ),
              const PopupMenuItem(
                value: "Near",
                child: Text("Sort by Distance"),
              ),
              const PopupMenuItem(
                value: "Rating",
                child: Text("Sort by Rating"),
              ),
            ],
          ),
        ],
      ),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: fetchEmployeesByCategory(widget.categoryName),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
           return const ShimmerPage();
           }

          if (snapshot.hasError) {
            return Center(
              child: Text('Error: ${snapshot.error}'),
            );
          }
          final employees = snapshot.data;
          if (employees == null || employees.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'lib/assets/images/logo_orange.PNG',
                    width: 120,
                    height: 120,
                  ),
                  const Text('No employees found for this category'),
                ],
              ),
            );
          }
          return ListView.builder(
            itemCount: employees.length,
            itemBuilder: (context, index) {
              final employee = employees[index];
              final employeeName = employee['name'] ?? 'Unknown Employee';
              final employeeImg = employee['img'] ?? '';
              final employeeId = employee['uid'];
              final employeeRating =
                  employee['rating']; // ✅ الريتينج الآن double

              return InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ViewEmpProfilePage(employeeId: employeeId),
                    ),
                  );
                },
                child: Card(
                  color: Colors.white,
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 30,
                              backgroundImage: employeeImg.isNotEmpty
                                  ? NetworkImage(employeeImg)
                                  : null,
                              backgroundColor: AppColors().navy,
                              child: employeeImg.isEmpty
                                  ? const Icon(Icons.person,
                                      color: Colors.white)
                                  : null,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    employeeName,
                                    style: GoogleFonts.montserratAlternates(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black,
                                    ),
                                  ),
                                  Text(
                                    "Distance: ${employee['distance'].toStringAsFixed(2)} km",
                                    style: const TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.star,
                                          color: Colors.orange, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        employeeRating.toStringAsFixed(
                                            1), // ✅ عرض الريتينج بعد تحويله
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.arrow_forward_ios,
                                color: Colors.grey),
                          ],
                        ),
                        const SizedBox(height: 10),
                        ElevatedButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    MapScreen(employeeId: employeeId),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors().orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 20, vertical: 12),
                          ),
                          child: const Text(
                            'See Location',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
