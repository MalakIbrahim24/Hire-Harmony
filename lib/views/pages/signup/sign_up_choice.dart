import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:hire_harmony/views/widgets/sign_up_widget.dart';

class SignUpChoice extends StatelessWidget {
  const SignUpChoice({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: Padding(
          padding: const EdgeInsets.all(5.0),
          child: Container(
            decoration: BoxDecoration(
                color: AppColors().orange,
                borderRadius: BorderRadius.circular(35)),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: AppColors().white),
              onPressed: () {
                Navigator.pop(context);
              },
            ),
          ),
        ),
        title: Text(
          textAlign: TextAlign.left,
          'Register a new account',
          style: GoogleFonts.montserratAlternates(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: AppColors().navy,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Placeholder for the logo
                  Center(
                    child: Image.asset(
                      'lib/assets/images/logo_orange.PNG',
                      width: 200, // Bigger logo for better visibility
                      height: 200,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Hire Harmony',
                    style: GoogleFonts.montserratAlternates(
                      fontSize: 24,
                      color: AppColors().navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 15),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 100),
                Text(
                  'Please choose your role',
                  textAlign: TextAlign.left,
                  style: GoogleFonts.montserratAlternates(
                    fontSize: 16,
                    color: AppColors().navy,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                SignUpWidget(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.signUpPage, // Navigate to sign-up page
                      arguments: {
                        'role': 'customer' // Pass the 'customer' role
                      },
                    );
                  },
                  userType: 'Customer',
                  description:
                      'Finding a helper here has never been easier than before!',
                  image: Image.asset('lib/assets/images/customer.png'),
                ),
                const SizedBox(height: 15),
                SignUpWidget(
                  onPressed: () {
                    Navigator.pushNamed(
                      context,
                      AppRoutes.signUpPage, // Navigate to sign-up page
                      arguments: {
                        'role': 'employee' // Pass the 'employee' role
                      },
                    );
                  },
                  userType: 'EMPLOYEE',
                  description:
                      'Let’s recruit you faster here.\n Share your experience!',
                  image: Image.asset('lib/assets/images/employee.png'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
