import 'package:get/get.dart';
import 'package:location/location.dart';

class LocationController extends GetxController {
  // حالة الوصول إلى الموقع
  final isAccessingLocation = false.obs;

  // وصف الأخطاء
  final errorDescription = ''.obs;

  // بيانات الموقع الجغرافي
  final userLocation = Rxn<LocationData>();

  // تحديث حالة الوصول إلى الموقع
  void updateIsAccessingLocation(bool value) {
    isAccessingLocation.value = value;
  }

  // تحديث بيانات الموقع
  void updateUserLocation(LocationData data) {
    userLocation.value = data;
  }

  // إعادة تعيين القيم
  void reset() {
    isAccessingLocation.value = false;
    errorDescription.value = '';
    userLocation.value = null;
  }
}
