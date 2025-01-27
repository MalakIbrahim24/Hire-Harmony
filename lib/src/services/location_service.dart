import 'dart:async';
import 'package:get/get.dart';
import 'package:hire_harmony/src/controller/location_controller.dart';
import 'package:location/location.dart';
import 'package:permission_handler/permission_handler.dart' as handler;

class LocationService {
  // إنشاء مثيل وحيد من الخدمة
  LocationService._internal();
  static final LocationService instance = LocationService._internal();

  final Location _location = Location();

  // التحقق من تفعيل خدمة الموقع
  Future<bool> checkForServiceAvailability() async {
    bool isEnabled = await _location.serviceEnabled();
    if (!isEnabled) {
      isEnabled = await _location.requestService();
    }
    return isEnabled;
  }

  // التحقق من أذونات الوصول إلى الموقع
  Future<bool> checkForPermission() async {
    PermissionStatus status = await _location.hasPermission();

    if (status == PermissionStatus.denied) {
      status = await _location.requestPermission();
    }

    if (status == PermissionStatus.deniedForever) {
      Get.snackbar(
        "Permission Needed",
        "We need location permission to provide the service.",
        onTap: (_) async => await handler.openAppSettings(),
      );
      return false;
    }

    return status == PermissionStatus.granted;
  }

  // الحصول على موقع المستخدم
 Future<void> getUserLocation({required LocationController controller}) async {
  controller.updateIsAccessingLocation(true);

  if (!await checkForServiceAvailability()) {
    controller.errorDescription.value = "Location service is disabled.";
    controller.updateIsAccessingLocation(false);
    Get.back(); // العودة إلى الصفحة السابقة في حال حدوث مشكلة في الخدمة
    return;
  }

  if (!await checkForPermission()) {
    controller.errorDescription.value = "Location permission is denied.";
    controller.updateIsAccessingLocation(false);
    Get.back(); // العودة إلى الصفحة السابقة إذا كانت الأذونات مرفوضة
    return;
  }

  try {
    final LocationData data = await _location.getLocation().timeout(
      const Duration(seconds: 10),
      onTimeout: () {
        throw TimeoutException("Request timed out while fetching location.");
      },
    );

    controller.updateUserLocation(data);
  } catch (e) {
    controller.errorDescription.value = "Error accessing location: $e";
  } finally {
    controller.updateIsAccessingLocation(false);
    Get.back(); // العودة إلى الصفحة السابقة بعد معالجة العملية
  }
}
}