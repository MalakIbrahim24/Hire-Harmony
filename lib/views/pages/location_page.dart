import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/api/firebase_api.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/src/controller/location_controller.dart';
import 'package:hire_harmony/src/services/location_service.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/cus_home_page.dart';
import 'package:hire_harmony/views/pages/customer/custom_buttom_navbar.dart';
import 'package:hire_harmony/views/pages/employee/emp_home_page.dart';
import 'package:hire_harmony/views/pages/employee/emp_navbar.dart';
import 'package:hire_harmony/views/pages/welcome_page.dart';
import 'package:http/http.dart' as http;

class LocationPage extends StatefulWidget {
  const LocationPage({super.key});

  @override
  State<LocationPage> createState() => _LocationPageState();
}

class _LocationPageState extends State<LocationPage> {
  final LocationController locationController = Get.put(LocationController());
  final RxBool isLocationFetched = false.obs;
  final RxString locationDetails = ''.obs;
  final userId = FirebaseAuth.instance.currentUser?.uid;
  final FirestoreService _fireS = FirestoreService.instance;


  Future<void> redirectToHomePage(String uid) async {
    final role = await _fireS.getUserRoleByUid(uid);

    if (role == 'customer') {
      Get.offAll(() =>
          const CustomButtomNavbar()); // استبدل ClientHomePage بالصفحة المناسبة للعميل
    } else if (role == 'employee') {
      Get.offAll(() =>
          const EmpNavbar()); // استبدل UserHomePage بالصفحة المناسبة للمستخدم
    } else {
      print('Unknown user role. Redirecting to default page.');
      Get.offAll(() => const WelcomePage()); 
    }
  }

  Future<void> fetchLocationDetails(String latitude, String longitude) async {
    const apiKey = "AIzaSyCyl4pNb6FhDky0Rad3z8GKDt4Un42ccP4"; 
    final url ='https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=$apiKey';

    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['results'] != null && data['results'].isNotEmpty) {
          final addressComponents = data['results'][0]['address_components'];
          String? city;
          String? country;

          for (var component in addressComponents) {
            if (component['types'].contains('locality')) {
              city = component['long_name'];
            }
            if (component['types'].contains('country')) {
              country = component['long_name'];
            }
          }
    debugPrint('city ${city}');
    debugPrint('country ${country}');

          locationDetails.value =
              '${city ?? 'Unknown City'}, ${country ?? 'Unknown Country'}';
        }
      } else {
        locationController.errorDescription.value =
            'Failed to fetch location: ${response.reasonPhrase}';
      }
    } catch (e) {
      locationController.errorDescription.value = 'Error: $e';
    }
  }

  /// طلب إذن الوصول إلى الموقع
  Future<void> requestLocationAccess() async {
    locationController.isAccessingLocation.value = true;

    try {
      // جلب الموقع
      await LocationService.instance
          .getUserLocation(controller: locationController);

      if (locationController.userLocation.value != null) {
        final latitude = locationController.userLocation.value!.latitude!.toString();
        final longitude = locationController.userLocation.value!.longitude!.toString();

        print('Latitude: $latitude, Longitude: $longitude');

        // جلب تفاصيل الموقع
        await fetchLocationDetails(latitude.toString(), longitude.toString());
        isLocationFetched.value = true;

        // حفظ الإحداثيات في بيانات المستخدم
        await FirebaseApi().saveUserLocation(userId!, latitude, longitude);

        await FirebaseApi().saveUserLocation(userId!, latitude, longitude);

// إعادة التوجيه بناءً على الدور
        await redirectToHomePage(userId!);
      }
    } catch (error) {
      locationController.errorDescription.value =
          "Failed to access location: $error";
    } finally {
      locationController.isAccessingLocation.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(15.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const SizedBox(height: 300),
            Row(
              children: [
                Icon(Icons.home_outlined,
                    color: AppColors().orange, size: 60.0),
                const SizedBox(width: 12),
                Text(
                  'Hire Harmony',
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 36,
                    color: AppColors().navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Obx(() {
              if (locationController.isAccessingLocation.value) {
                return Column(
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 14),
                    Text(
                      'Accessing Location...',
                      style: GoogleFonts.montserratAlternates(
                        fontSize: 20,
                        color: Colors.black,
                      ),
                    ),
                  ],
                );
              } else if (locationController.errorDescription.value.isNotEmpty) {
                return Text(
                  locationController.errorDescription.value,
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 18,
                    color: Colors.red,
                  ),
                );
              } else if (isLocationFetched.value) {
                return Text(
                  locationDetails.value,
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 18,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                );
              } else {
                return Text(
                  'Location access is required to proceed.',
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 18,
                    color: Colors.black54,
                  ),
                  textAlign: TextAlign.center,
                );
              }
            }),
            const SizedBox(height: 80),
            ElevatedButton(
              onPressed: requestLocationAccess,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().orange,
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
              ),
              child: Obx(() {
                return Text(
                  isLocationFetched.value
                      ? 'Redirecting to Home Page...'
                      : 'Allow Location Access',
                  style: GoogleFonts.montserratAlternates(
                    color: AppColors().white,
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }
}
