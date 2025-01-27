import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:get/get.dart';
import 'package:hire_harmony/src/controller/location_controller.dart';
import 'package:hire_harmony/utils/app_colors.dart';

class MapPage extends StatelessWidget {
  final LocationController locationController = Get.find<LocationController>();

  MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Your Location',style: TextStyle(
          color: AppColors().white,
        ),),
        
        backgroundColor: AppColors().orange,
      ),
      body: Obx(() {
        if (locationController.userLocation.value == null) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        LatLng initialPosition = LatLng(
          locationController.userLocation.value!.latitude!,
          locationController.userLocation.value!.longitude!,
        );

        return GoogleMap(
          initialCameraPosition: CameraPosition(
            target: initialPosition,
            zoom: 14.0,
          ),
          markers: {
            Marker(
              markerId: const MarkerId('currentLocation'),
              position: initialPosition,
              infoWindow: const InfoWindow(
                title: 'You are here!',
              ),
            ),
          },
          myLocationEnabled: true,
          myLocationButtonEnabled: true,
        );
      }),
    );
  }
}
