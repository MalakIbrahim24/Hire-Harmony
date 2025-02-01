import 'dart:io';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:hire_harmony/views/widgets/admin/adn_profile_container.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AdnPersonalInfoPage extends StatefulWidget {
  const AdnPersonalInfoPage({super.key});

  @override
  State<AdnPersonalInfoPage> createState() => _AdnPersonalInfoPageState();
}

class _AdnPersonalInfoPageState extends State<AdnPersonalInfoPage> {
  final AuthServices authServices = AuthServicesImpl();

  String? adminImageUrl;

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    try {
      final String adminUid = authServices.getCurrentUser()?.uid ?? '';
      if (adminUid.isEmpty) return;

      final DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .get();

      if (adminSnapshot.exists) {
        final adminData = adminSnapshot.data() as Map<String, dynamic>;
        setState(() {
          adminImageUrl = adminData['img'] as String? ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
    }
  }

  Future<void> _changeProfileImage() async {
    try {
      // Pick a new image
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(source: ImageSource.gallery);

      if (image == null) return;

      // Upload the image to Supabase
      final String filePath = image.path;
      final String fileName =
          'profile_images/${authServices.getCurrentUser()?.uid}.jpg';

      final supabase.SupabaseClient supabaseClient =
          supabase.Supabase.instance.client;
      final storageResponse = await supabaseClient.storage
          .from('serviceImages') // Replace with your Supabase bucket name
          .upload(fileName, File(filePath),
              fileOptions: const supabase.FileOptions(
                  cacheControl: '3600', upsert: true));

      if (storageResponse.isNotEmpty) {
        // Get the public URL of the uploaded image
        final String publicUrl = supabaseClient.storage
            .from('serviceImages') // Replace with your Supabase bucket name
            .getPublicUrl(fileName);

        // Update Firebase with the new image URL
        final String adminUid = authServices.getCurrentUser()?.uid ?? '';
        await FirebaseFirestore.instance
            .collection('users')
            .doc(adminUid)
            .update({'img': publicUrl});

        // Update the UI
        setState(() {
          adminImageUrl = publicUrl;
        });

        Fluttertoast.showToast(
          msg: "Profile image updated successfully",
          textColor: AppColors().white,
          backgroundColor: AppColors().orange,
        );
      } else {
        Fluttertoast.showToast(
          msg: "Failed to upload image to Supabase",
          textColor: AppColors().white,
          backgroundColor: AppColors().red,
        );
      }
    } catch (e) {
      debugPrint('Error changing profile image: $e');
      Fluttertoast.showToast(
        msg: "Error: $e",
        textColor: AppColors().white,
        backgroundColor: AppColors().red,
      );
    }
  }

  Future<void> _updatePassword() async {
    // The password update logic remains unchanged
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors().white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          // Background Image with Gradient Overlay
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                image: adminImageUrl != null && adminImageUrl!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(adminImageUrl!),
                        fit: BoxFit.cover,
                      )
                    : const DecorationImage(
                        image: AssetImage('lib/assets/images/noimg.jpg'),
                        fit: BoxFit.cover,
                      ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors().black.withValues(alpha: 0.5),
                      AppColors().black.withValues(alpha: 0.8),
                    ],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 17.0, sigmaY: 17.0),
              child: Container(
                color: AppColors().navy.withValues(alpha: 0.3),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Profile Header with Circle Avatar
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _changeProfileImage, // Trigger image change on tap
                  child: CircleAvatar(
                    radius: 100,
                    backgroundImage:
                        adminImageUrl != null && adminImageUrl!.isNotEmpty
                            ? NetworkImage(adminImageUrl!)
                            : const AssetImage('lib/assets/images/noimg.jpg')
                                as ImageProvider,
                    child: adminImageUrl == null || adminImageUrl!.isEmpty
                        ? const Icon(Icons.add_a_photo, size: 50)
                        : null,
                  ),
                ),
                const SizedBox(height: 30),
                Text(
                  'Malak\'s Personal Information',
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: AppColors().white,
                  ),
                ),
                const SizedBox(height: 60),

                // Information Cards
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: ListView(
                      children: [
                        AdnProfileContainer(
                          title: 'Reset Password',
                          icon: Icons.lock_reset,
                          onTap: _updatePassword,
                        ),
                        const SizedBox(height: 50),
                        AdnProfileContainer(
                          title: 'View Activity',
                          icon: Icons.access_time_outlined,
                          onTap: () {
                            Navigator.pushNamed(
                                context, AppRoutes.adnactivityPage);
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
