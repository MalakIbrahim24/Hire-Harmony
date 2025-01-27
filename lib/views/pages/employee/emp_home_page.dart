import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get/get_core/src/get_main.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/api/firebase_api.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/employee/advertisement_screen.dart';
import 'package:hire_harmony/views/pages/employee/booking_screen.dart';
import 'package:hire_harmony/views/pages/employee/contact_us_page.dart';
import 'package:hire_harmony/views/pages/employee/emp_notifications_page.dart';
import 'package:hire_harmony/views/pages/employee/tickets_page.dart';
import 'package:hire_harmony/views/pages/location_page.dart';
import 'package:hire_harmony/views/widgets/employee/prev_work.dart';

class EmpHomePage extends StatefulWidget {
  const EmpHomePage({super.key});

  @override
  State<EmpHomePage> createState() => _EmpHomePageState();
}

class _EmpHomePageState extends State<EmpHomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String userName = "User"; // Default user name
    final String? userId = FirebaseAuth.instance.currentUser?.uid;

 @override
  void initState() {
    super.initState();
    _checkUserLocation();
    fetchUserName(); // Fetch user name when the page initializes

  }

  Future<void> _checkUserLocation() async {
    await Future.delayed(const Duration(seconds: 10)); // الانتظار لمدة 10 ثوانٍ

    // افترض أن لديك Firebase API تتحقق من الموقع
    final isLocationSaved = await FirebaseApi().isUserLocationSaved(userId!);

 if (!isLocationSaved) {
  // تحويل المستخدم إلى صفحة الموقع باستخدام GetX
  await Get.to(() => const LocationPage());
}

  }
  Future<String?> _fetchEmployeeState(String userId) async {
    try {
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['state'] as String?;
      }
    } catch (e) {
      debugPrint("Error fetching employee state: $e");
    }
    return null;
  }

  Future<void> fetchUserName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        // Fetch the user's document from Firestore
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          setState(() {
            userName = userDoc['name'] ?? "User"; // Update the username
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching user name: $e");
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(100),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                AppColors().navy,
                AppColors().orange,
              ], // Navy and Orange colors
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 15),
          child: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(width: 10),
                        Text(
                          textAlign: TextAlign.center,
                          'Welcome, $userName', // Display the fetched user name
                          style: GoogleFonts.montserratAlternates(
                            textStyle: const TextStyle(
                              fontSize: 16,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.notifications_active_outlined,
                        color: Colors.white,
                        size: 25,
                      ),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) =>
                                  const EmpNotificationsPage()),
                        );
                      },
                    )
                  ],
                ),
                const SizedBox(height: 15),
              ],
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Overview',
                  style: GoogleFonts.montserratAlternates(
                    textStyle: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                const SizedBox(height: 10),
                GridView.count(
                  crossAxisCount: 3,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    OverviewCard(
                      title: 'Booking',
                      
                      icon: Icons.book_online,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const BookingScreen(),
                          ),
                        );
                      },
                      cardColor: AppColors().lightblue,
                      iconColor: AppColors().orange,
                    ),
                    OverviewCard(
                      title: 'Post Ad',
                      icon: Icons.post_add,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const AdvertisementScreen(),
                          ),
                        );
                      },
                      cardColor: AppColors().orangelight,
                      iconColor: AppColors().navy,
                    ),
                    OverviewCard(
                      title: 'Contact Us ',
                      icon: Icons.support_agent,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ContactUsPage(),
                          ),
                        );
                      },
                      cardColor: AppColors().lightblue,
                      iconColor: AppColors().orange,
                    ),
                    OverviewCard(
                      title: 'Tickets',
                      icon: Icons.list,
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const TicketsPage(),
                          ),
                        );
                      },
                      cardColor: AppColors().orangelight,
                      iconColor: AppColors().navy,
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const PrevWork(),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OverviewCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback? onTap;
  final Color cardColor;
  final Color iconColor;
  final bool showCounter; // Indicates whether to show the badge

  const OverviewCard({
    super.key,
    required this.title,
    required this.icon,
    this.onTap,
    required this.cardColor,
    required this.iconColor,
    this.showCounter = false, // Default to false
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center, // Align all children to the center
        children: [
          Card(
            color: cardColor,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            elevation: 1,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, color: iconColor, size: 30),
                  const SizedBox(height: 5),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.montserratAlternates(fontSize: 14),
                  ),
                ],
              ),
            ),
          ),
          if (showCounter) // Show the badge if showCounter is true
            Positioned(
              top: 10,
              right: 10,
              child: _PendingRequestsBadge(),
            ),
        ],
      ),
    );
  }
}

class _PendingRequestsBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    if (loggedInUserId == null) {
      return const SizedBox(); // Return an empty widget if the user is not logged in
    }

    // Firestore query for pending requests count
    final Stream<QuerySnapshot> pendingRequestsStream = FirebaseFirestore
        .instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('recievedRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: pendingRequestsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox(); // Do not show the badge if no data or empty
        }

        final pendingCount = snapshot.data!.docs.length;

        return Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: AppColors().orange,
            shape: BoxShape.circle,
          ),
          child: Text(
            '$pendingCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }
}

class WorkPhotoCard extends StatelessWidget {
  final String image;
  final String title;

  const WorkPhotoCard({super.key, required this.image, required this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 16),
      width: 150,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
        color: Colors.grey.shade200,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
            child: Image.network(image, height: 100, fit: BoxFit.cover),
          ),
          const SizedBox(height: 5),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Text(
              title,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          )
        ],
      ),
    );
  }
}
