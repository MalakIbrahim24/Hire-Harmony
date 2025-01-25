import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:hire_harmony/views/widgets/back_icon_button.dart';
import 'package:hire_harmony/views/widgets/main_button.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class PhonePage extends StatefulWidget {
  const PhonePage({super.key});

  @override
  State<PhonePage> createState() => _PhonePageState();
}

class _PhonePageState extends State<PhonePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();

  bool isSmsSent = false;
  bool isVerifyButtonEnabled = false;
  bool isSendOtpButtonEnabled = false;
  String verificationId = "";

  // Validate phone number format (basic validation)
  bool isValidPhoneNumber(String phoneNumber) {
    final phoneRegex =
        RegExp(r'^\+\d{12,15}$'); // Matches + followed by 10-15 digits
    return phoneRegex.hasMatch(phoneNumber);
  }

  // Hash a password using SHA-256
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  // Send OTP
  Future<void> sendOtp() async {
    final String phoneNumber = '+970${_phoneController.text.trim()}';

    if (!isValidPhoneNumber(phoneNumber)) {
      Fluttertoast.showToast(
        msg: "Please enter a valid phone number.",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
      return;
    }

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        timeout: const Duration(seconds: 60),
        verificationCompleted: (PhoneAuthCredential credential) async {
          await _auth.signInWithCredential(credential);
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Phone number verified!')),
          );
          setState(() {
            isVerifyButtonEnabled = true;
          });
        },
        verificationFailed: (FirebaseAuthException e) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors().red,
              content: Text(
                'Verification failed: ${e.message}',
                style: GoogleFonts.montserratAlternates(
                  color: AppColors().white,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
        codeSent: (String verId, int? resendToken) {
          if (!mounted) return;
          setState(() {
            verificationId = verId;
            isSmsSent = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: AppColors().green,
              content: Text(
                'OTP sent successfully!',
                style: GoogleFonts.montserratAlternates(
                  color: AppColors().white,
                  fontSize: 15,
                ),
              ),
            ),
          );
        },
        codeAutoRetrievalTimeout: (String verId) {
          if (!mounted) return;
          setState(() {
            verificationId = verId;
          });
        },
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors().red,
          content: Text(
            'Error sending OTP: $e',
            style: GoogleFonts.montserratAlternates(
              color: AppColors().white,
              fontSize: 15,
            ),
          ),
        ),
      );
    }
  }

  // Function to upload images to Supabase
  Future<String> _uploadToSupabase(File image, String fileName) async {
    final supabasee = supabase.Supabase.instance.client;
    try {
      // Specify the path in the `auth_images` folder
      String filePath = 'auth_images/$fileName';

      // Attempt to upload the image
      await supabasee.storage.from('serviceImages').upload(filePath, image);

      // If successful, return the public URL
      return supabasee.storage.from('serviceImages').getPublicUrl(filePath);
    } catch (e) {
      // Handle the exception and throw a custom error message
      throw Exception('Failed to upload image: $e');
    }
  }

  // Verify OTP and register the user
  Future<void> verifyOtpAndRegister(
      Map<String, dynamic> formData, List<String> categories) async {
    const availability = 'available';
    const state = 'accepted';
    const img =
        'https://thumbs.dreamstime.com/b/default-avatar-profile-icon-vector-social-media-user-image-182145777.jpg';

    try {
      // Verify the OTP and sign in the user with the phone credential
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: _otpController.text,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('User creation failed.');
      }

      final User user = userCredential.user!;

      // Link email and password as additional providers
      final emailCredential = EmailAuthProvider.credential(
        email: formData['email']!,
        password: formData['password']!,
      );

      await user.linkWithCredential(emailCredential);

      // Store user details in Firestore
      String hashedPassword = _hashPassword(formData['password']!);

      // Upload images to Supabase
      final idImage = formData['idImage'] as File;
      final selfieImage = formData['selfieImage'] as File;

      final idImageUrl = await _uploadToSupabase(
          idImage, 'id_${DateTime.now().millisecondsSinceEpoch}.jpg');
      final selfieImageUrl = await _uploadToSupabase(
          selfieImage, 'selfie_${DateTime.now().millisecondsSinceEpoch}.jpg');

      // Save user data in the `users` collection
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': formData['name'],
        'email': formData['email'],
        'passwordHash': hashedPassword,
        'phone': '+970${_phoneController.text.trim()}',
        'role': 'employee',
        'idImageUrl': idImageUrl,
        'selfieImageUrl': selfieImageUrl,
        'uid': user.uid,
        'img': img,
        'availability': availability,
        'state': state,
        'similarity': formData['similarity'],
      });

      // Save categories in the `empcategories` collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('empcategories')
          .add({
        'categories': categories,
      });

      // Navigate to the success page
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.empVerificationSuccessPage);
    } catch (e) {
      // Handle errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors().red,
          content: Text(
            'Invalid OTP or Error: $e',
            style: GoogleFonts.montserratAlternates(
              color: AppColors().white,
              fontSize: 15,
            ),
          ),
        ),
      );
    }
  }

  Future<void> verifyOtpAndRegisterCus(Map<String, dynamic> formData) async {
    const img =
        'https://thumbs.dreamstime.com/b/default-avatar-profile-icon-vector-social-media-user-image-182145777.jpg';

    try {
      // Verify the OTP and sign in the user with the phone credential
      final PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: _otpController.text,
      );

      final UserCredential userCredential =
          await _auth.signInWithCredential(credential);

      if (userCredential.user == null) {
        throw Exception('User creation failed.');
      }

      final User user = userCredential.user!;

      // Link email and password as additional providers
      final emailCredential = EmailAuthProvider.credential(
        email: formData['email']!,
        password: formData['password']!,
      );

      await user.linkWithCredential(emailCredential);

      // Store user details in Firestore
      String hashedPassword = _hashPassword(formData['password']!);

      // Upload images to Supabase

      // Save data in Firestore
      await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
        'name': formData['name'],
        'email': formData['email'],
        'passwordHash': hashedPassword,
        'phone': '+970${_phoneController.text.trim()}',
        'role': 'employee',
        'uid': user.uid,
        'img': img,
      });

      // Navigate to the success page
      if (!mounted) return;
      Navigator.pushNamed(context, AppRoutes.empVerificationSuccessPage);
    } catch (e) {
      // Handle errors
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors().red,
          content: Text(
            'Invalid OTP or Error: $e',
            style: GoogleFonts.montserratAlternates(
              color: AppColors().white,
              fontSize: 15,
            ),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Retrieve data passed from EmpIdVerificationPage

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

// Validate and extract the role
    final String? role = formData['role'];

    if (role == null) {
      return const Center(
        child: Text(
          'Error: Role not provided.',
          style: TextStyle(fontSize: 18, color: Colors.red),
        ),
      );
    }

    // Safely cast the values from `formData` when needed

    return Scaffold(
      backgroundColor: AppColors().white,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: Stack(
              children: [
                Positioned(
                  top: 40,
                  left: 10,
                  child: Row(
                    children: [
                      const BackIconButton(),
                      const SizedBox(width: 20),
                      Padding(
                        padding: const EdgeInsets.only(top: 5.0),
                        child: Text(
                          'Verify',
                          style: GoogleFonts.montserratAlternates(
                            fontSize: 20,
                            color: AppColors().navy,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 65),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 20),
                            Text(
                              'Phone number',
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 15,
                                color: AppColors().navy,
                              ),
                            ),
                            const SizedBox(height: 20),
                            TextFormField(
                              controller: _phoneController,
                              keyboardType: TextInputType.phone,
                              decoration: InputDecoration(
                                prefixIcon:
                                    const Icon(Icons.phone_android_outlined),
                                prefixText: '+970 ',
                                border: InputBorder.none,
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10),
                                  borderSide: BorderSide(
                                    color: AppColors().grey.withAlpha(128),
                                    width: 1.0,
                                  ),
                                ),
                                hintText: 'Enter your phone number',
                              ),
                              onChanged: (value) {
                                setState(() {
                                  isSendOtpButtonEnabled = isValidPhoneNumber(
                                      '+970${_phoneController.text.trim()}');
                                });
                              },
                            ),
                            const SizedBox(height: 60),
                            if (isSmsSent)
                              PinCodeTextField(
                                appContext: context,
                                controller: _otpController,
                                length: 6,
                                onChanged: (value) {
                                  setState(() {
                                    isVerifyButtonEnabled = value.length == 6;
                                  });
                                },
                                pinTheme: PinTheme(
                                  shape: PinCodeFieldShape.underline,
                                  fieldHeight: 50,
                                  fieldWidth: 40,
                                  inactiveColor: AppColors().grey,
                                  activeColor: AppColors().orange,
                                  selectedColor: AppColors().orange,
                                ),
                              ),
                            const SizedBox(height: 20),
                            MainButton(
                              color: isSendOtpButtonEnabled
                                  ? AppColors().white
                                  : AppColors().grey,
                              text: "Send OTP",
                              bgColor: isSendOtpButtonEnabled
                                  ? AppColors().orange
                                  : AppColors().greylight,
                              onPressed:
                                  isSendOtpButtonEnabled ? sendOtp : null,
                            ),
                            const SizedBox(height: 20),
                            MainButton(
                              color: isVerifyButtonEnabled
                                  ? AppColors().white
                                  : AppColors().grey,
                              text: "Verify",
                              bgColor: isVerifyButtonEnabled
                                  ? AppColors().orange
                                  : AppColors().greylight,
                              onPressed: isVerifyButtonEnabled
                                  ? () async {
                                      if (role == 'employee') {
                                        await verifyOtpAndRegister(
                                            formData, categories);
                                      } else if (role == 'customer') {
                                        await verifyOtpAndRegisterCus(formData);
                                      } else {
                                        if (!mounted) return;
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            backgroundColor: AppColors().red,
                                            content: const Text(
                                              'Invalid role. Please contact support.',
                                            ),
                                          ),
                                        );
                                      }
                                    }
                                  : null,
                            ),
                          ],
                        ),
                      ),
                    ],
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
