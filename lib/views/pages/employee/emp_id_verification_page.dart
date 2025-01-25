import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:flutter_face_api/flutter_face_api.dart';

class EmpIdVerificationPage extends StatefulWidget {
  const EmpIdVerificationPage({super.key});

  @override
  State<EmpIdVerificationPage> createState() => _EmpIdVerificationPageState();
}

class _EmpIdVerificationPageState extends State<EmpIdVerificationPage> {
  File? idImage;
  File? selfieImage;
  bool isProcessing = false;
  Future<bool> initializeFaceSdk() async {
    var faceSdk = FaceSDK.instance;
    var license = await rootBundle.load('assets/regula.license');
    var config = InitConfig(license.buffer.asUint8List() as ByteData);
    var (success, error) = await faceSdk.initialize(config: config);
    if (!success) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Face SDK initialization failed: ${error?.message}')),
      );
    }
    return success;
  }

  @override
  void initState() {
    super.initState();
    initializeFaceSdk();
  }

  // Function to pick an image from the gallery
  Future<void> _pickImage(ImageSource source, bool isIdImage) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source);

    if (image != null) {
      setState(() {
        if (isIdImage) {
          idImage = File(image.path);
        } else {
          selfieImage = File(image.path);
        }
      });
    }
  }

  // Function to navigate to PhonePage
  Future<void> _navigateToPhonePage(
      Map<String, String> userData, List<String> categories) async {
    if (idImage == null || selfieImage == null) return;

    setState(() {
      isProcessing = true;
    });

    try {
      // Convert images to bytes
      var idImageBytes = idImage!.readAsBytesSync();
      var selfieImageBytes = selfieImage!.readAsBytesSync();

      // Create MatchFacesImage instances
      var idMatchImage = MatchFacesImage(idImageBytes, ImageType.PRINTED);
      var selfieMatchImage = MatchFacesImage(selfieImageBytes, ImageType.LIVE);

      // Match faces
      var faceSdk = FaceSDK.instance;
      var request = MatchFacesRequest([idMatchImage, selfieMatchImage]);
      var response = await faceSdk.matchFaces(request);

      // Get similarity result
      var matchedFaces =
          await faceSdk.splitComparedFaces(response.results, 0.75);
      if (matchedFaces.matchedFaces.isNotEmpty) {
        var similarity = matchedFaces.matchedFaces[0].similarity * 100;

        if (similarity > 75) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: AppColors().green,
                content: Text(
                  'Match Successful! Similarity: ${similarity.toStringAsFixed(2)}%',
                  style: GoogleFonts.montserratAlternates(
                    color: AppColors().white,
                    fontSize: 15,
                  ),
                )),
          );

          // Navigate to the next page
          Navigator.pushNamed(context, AppRoutes.phonePage, arguments: {
            'name': userData['name']!,
            'email': userData['email']!,
            'password': userData['password']!,
            'idImage': idImage!,
            'selfieImage': selfieImage!,
            'role': 'employee',
            'similarity': similarity,
            'categories': categories,
          });
        } else {
          if (!mounted) return;

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                backgroundColor: AppColors().red,
                content: Text(
                  'Match Failed! Similarity: ${similarity.toStringAsFixed(2)}%',
                  style: GoogleFonts.montserratAlternates(
                    color: AppColors().white,
                    fontSize: 15,
                  ),
                )),
          );
        }
      } else {
        if (!mounted) return;

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              backgroundColor: AppColors().red,
              content: Text(
                'No match found.',
                style: GoogleFonts.montserratAlternates(
                  color: AppColors().white,
                  fontSize: 15,
                ),
              )),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            backgroundColor: AppColors().red,
            content: Text(
              'Error during face matching: $e',
              style: GoogleFonts.montserratAlternates(
                color: AppColors().white,
                fontSize: 15,
              ),
            )),
      );
    } finally {
      setState(() {
        isProcessing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve arguments passed from SignUpPage
    final Map<String, dynamic>? formData =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>?;

    final List<String> categories =
        (formData?['categories'] as List<dynamic>?)?.cast<String>() ?? [];

    if (formData == null) {
      return const Center(
        child: Text(
          'Error: No user data provided.',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors().white,
      appBar: AppBar(
        title: Text(
          "Upload ID & Selfie",
          style: GoogleFonts.montserratAlternates(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors().navy,
          ),
        ),
        backgroundColor: AppColors().white,
        iconTheme: IconThemeData(color: AppColors().navy),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Status message
                const SizedBox(
                  height: 50,
                ),
                Text(
                  "Upload your ID and a selfie for verification.",
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors().grey3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 50),

                // ID Image Picker
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.gallery, true),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        idImage != null ? FileImage(idImage!) : null,
                    backgroundColor: idImage == null
                        ? AppColors().orangelight
                        : Colors
                            .transparent, // Set orange background when no image
                    child: idImage == null
                        ? Icon(Icons.insert_drive_file,
                            size: 40, color: AppColors().grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Upload ID Picture",
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors().navy,
                  ),
                ),

                const SizedBox(height: 30),

                // Selfie Image Picker
                GestureDetector(
                  onTap: () => _pickImage(ImageSource.camera, false),
                  child: CircleAvatar(
                    radius: 60,
                    backgroundImage:
                        selfieImage != null ? FileImage(selfieImage!) : null,
                    backgroundColor: idImage == null
                        ? AppColors().orangelight
                        : Colors
                            .transparent, // Set orange background when no image
                    child: selfieImage == null
                        ? Icon(Icons.add_a_photo,
                            size: 40, color: AppColors().grey)
                        : null,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "Upload Selfie",
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: AppColors().navy,
                  ),
                ),

                const Spacer(),

                // Upload Button
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: (idImage != null && selfieImage != null)
                        ? AppColors().orange
                        : AppColors().grey,
                    padding: const EdgeInsets.symmetric(
                        vertical: 15, horizontal: 50),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed:
                      (idImage != null && selfieImage != null && !isProcessing)
                          ? () => _navigateToPhonePage(
                                formData.map((key, value) => MapEntry(
                                    key,
                                    value
                                        .toString())), // Convert to Map<String, String>
                                categories,
                              )
                          : null,
                  child: isProcessing
                      ? const CircularProgressIndicator()
                      : Text(
                          "Next",
                          style: GoogleFonts.montserratAlternates(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: AppColors().navy,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
