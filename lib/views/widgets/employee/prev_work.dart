import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/widgets/employee/photo_tab_view.dart';
import 'package:hire_harmony/views/widgets/employee/reviews_tab_view.dart';

class PrevWork extends StatefulWidget {
  const PrevWork({super.key});

  @override
  State<PrevWork> createState() => _PrevWorkState();
}

class _PrevWorkState extends State<PrevWork> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? id; // Make it nullable to handle initialization properly

  @override
  void initState() {
    super.initState();
    fetchEmployeeId();
  }

  Future<void> fetchEmployeeId() async {
    final User? user = _auth.currentUser;
    if (user != null) {
      setState(() {
        id = user.uid; // Fetch the UID of the logged-in user
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (id == null) {
      // Display a loading indicator while fetching the ID
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 10),
          Text(
            'Previous Work',
            style: GoogleFonts.montserratAlternates(
              textStyle: TextStyle(
                fontSize: 15,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 10),
          DefaultTabController(
            length: 2, // Number of tabs
            child: Column(
              children: [
                TabBar(
                  dividerColor: Colors.transparent,
                  labelColor: AppColors().orange,
                  unselectedLabelColor: AppColors().grey2,
                  indicatorColor: AppColors().orange,
                  tabs: const [
                    Tab(text: 'Photo'),
                    Tab(text: 'Reviews'),
                  ],
                ),
                SizedBox(
                  height: 300, // Appropriate height for displaying content
                  child: TabBarView(
                    children: [
                      PhotoTabView(
                        employeeId: id!, // Pass the fetched user ID
                      ), // First tab content
                      ReviewsTapView(
                        employeeId: id!,
                      ), // Second tab content
                    ],
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
