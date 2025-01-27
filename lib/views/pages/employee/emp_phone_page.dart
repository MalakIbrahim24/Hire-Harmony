import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/views/pages/forms/emp_phone_form.dart';
import 'package:hire_harmony/views/widgets/back_icon_button.dart';

class EmpPhonePage extends StatefulWidget {
  const EmpPhonePage({super.key});

  @override
  State<EmpPhonePage> createState() => _EmpPhonePageState();
}

class _EmpPhonePageState extends State<EmpPhonePage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: SafeArea(
            child: Stack(
              children: [
                // Positioned back button inside Stack
                Row(
                  children: [
                    const Positioned(
                      top: 40, // Adjust the top position as needed
                      left: 10,
                      // Adjust the lbeft position as needed
                      child: BackIconButton(),
                    ),
                    const SizedBox(
                      width: 20,
                    ),
                    Padding(
                      padding: const EdgeInsets.only(top: 5.0),
                      child: Text(
                        'Phone number verification',
                        style: GoogleFonts.montserratAlternates(
                          fontSize: 20,
                          color: Theme.of(context).colorScheme.primary,

                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                // Main content inside a Padding widget
                const Padding(
                  padding: EdgeInsets.only(
                      top: 80), // Adjust top padding to avoid overlap
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Top section with logo and title
                      SizedBox(height: 28),
                      EmpPhoneForm(), // Login form
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
