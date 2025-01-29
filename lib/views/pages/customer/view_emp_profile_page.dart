import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/chatePage.dart';
//import 'package:hire_harmony/views/pages/chatePage.dart';
//import 'package:hire_harmony/views/pages/chatePage.dart';
import 'package:hire_harmony/views/pages/employee/reviews_page.dart';
import 'package:hire_harmony/views/widgets/customer/cus_photo_tab_view.dart';

class ViewEmpProfilePage extends StatefulWidget {
  final String employeeId;

  const ViewEmpProfilePage({required this.employeeId, super.key});

  @override
  State<ViewEmpProfilePage> createState() => _ViewEmpProfilePageState();
}

class _ViewEmpProfilePageState extends State<ViewEmpProfilePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<String> services = []; // تخزين قائمة الخدمات
  bool isAvailable = false; // افتراضيًا، الموظف غير متاح

  Map<String, dynamic>? employeeData;
  bool isFavorite = false; // Track if the employee is favorited
  final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEmployeeData();
    _checkIfFavorited(); // Check if the employee is in the favorites list
  }

  Future<void> _fetchEmployeeData() async {
    try {
      final doc =
          await _firestore.collection('users').doc(widget.employeeId).get();
      if (doc.exists) {
        setState(() {
          employeeData = doc.data() as Map<String, dynamic>;

          // ✅ جلب قائمة الخدمات (services)
          if (employeeData!['services'] is List) {
            services = List<String>.from(employeeData!['services']);
          } else {
            services = [];
          }
          isAvailable = employeeData!['availability'] ?? false;
        });
      }
    } catch (e) {
      debugPrint('Error fetching employee data: $e');
    }
  }

  Future<void> _checkIfFavorited() async {
    try {
      if (loggedInUserId == null) {
        throw Exception('No user is currently signed in.');
      }

      final doc = await _firestore
          .collection('users')
          .doc(loggedInUserId)
          .collection('favourites')
          .doc(widget.employeeId)
          .get();

      setState(() {
        isFavorite =
            doc.exists; // If the document exists, the employee is favorited
      });
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
    }
  }

  Future<void> _toggleFavorite() async {
    try {
      if (loggedInUserId == null) {
        throw Exception('No user is currently signed in.');
      }

      final favoritesCollection = FirebaseFirestore.instance
          .collection('users')
          .doc(loggedInUserId)
          .collection('favourites');

      if (isFavorite) {
        // Remove from favorites
        await favoritesCollection.doc(widget.employeeId).delete();
      } else {
        // Add to favorites with employeeId as the document ID
        await favoritesCollection.doc(widget.employeeId).set({
          'uid': widget.employeeId, // Use the employee's ID
          'name': employeeData?['name'] ?? 'Unnamed',
          'img': employeeData?['img'] ?? '',
          'location': employeeData?['location'] ?? 'Unknown',
          'rating': employeeData?['rating'] ?? 0,
        });
      }

      setState(() {
        isFavorite = !isFavorite; // Toggle the state
      });
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (employeeData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(
                bottom: 80), // Add padding to prevent overlap
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Image
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(80),
                      child: Image.network(
                        employeeData!['img'] ??
                            'https://via.placeholder.com/150',
                        width: 160,
                        height: 160,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name and Details
                  Center(
                    child: Column(
                      children: [
                        Text(
                          employeeData!['name'] ?? 'Unnamed Employee',
                          style: GoogleFonts.montserratAlternates(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star,
                                color: AppColors().orange, size: 20),
                            const SizedBox(width: 4),
                            Text(
                              '${employeeData!['rating']} (${employeeData!['reviewsNum']} reviews)',
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Me Section with Favorite Icon
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'About me',
                        style: GoogleFonts.montserratAlternates(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.inversePrimary,
                        ),
                      ),
                      IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Colors.grey,
                        ),
                        onPressed: _toggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  Text(
                    employeeData!['about'] ??
                        'This employee has not added any description.',
                    style: GoogleFonts.montserratAlternates(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
// My Services Section
                  if (services.isNotEmpty)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        Text(
                          'My Services',
                          style: GoogleFonts.montserratAlternates(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.inversePrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8.0,
                          runSpacing: 8.0,
                          children: services.map((service) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                color: AppColors().orange.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                    color: AppColors().orange, width: 1),
                              ),
                              child: Text(
                                service,
                                style: GoogleFonts.montserratAlternates(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors().orange,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  const SizedBox(height: 8),

                  // Tabs Section
                  TabBar(
                    dividerColor: AppColors().transparent,
                    controller: _tabController,
                    labelColor: AppColors().orange,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors().orange,
                    labelStyle: const TextStyle(
                      fontSize: 16.5, // Text size for selected tabs
                      fontWeight: FontWeight.bold,
                    ),
                    unselectedLabelStyle: const TextStyle(
                      fontSize: 14, // Text size for unselected tabs
                      fontWeight: FontWeight.normal,
                    ),
                    tabs: const [
                      Tab(text: 'Photos'),
                      Tab(text: 'Reviews'),
                    ],
                  ),
                  SizedBox(
                    height: 400, // Height of TabBarView
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        CusPhotoTabView(
                          employeeId: widget.employeeId,
                        ),
                        ReviewsPage(
                          employeeId: widget.employeeId,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Buttons at the Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 5,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
               
                  const SizedBox(width: 16),
                  ElevatedButton(
                    onPressed: isAvailable
                        ? () {
                            // ✅ يكون قابلًا للنقر فقط إذا كان الموظف متاحًا
                            showDialog(
                              context: context,
                              builder: (BuildContext context) {
                                TextEditingController descriptionController =
                                    TextEditingController();
                                TextEditingController titleController =
                                    TextEditingController();
                                return AlertDialog(
                                  title: Text(
                                    'Send Request',
                                    style: GoogleFonts.montserratAlternates(
                                        fontWeight: FontWeight.bold),
                                  ),
                                  content: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(
                                        'Enter a description for your request:',
                                        style: GoogleFonts.montserratAlternates(
                                            fontSize: 14),
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: titleController,
                                        decoration: const InputDecoration(
                                            hintText: 'Enter the title here'),
                                        maxLines: 3,
                                      ),
                                      const SizedBox(height: 8),
                                      TextField(
                                        controller: descriptionController,
                                        decoration: const InputDecoration(
                                            hintText:
                                                'Enter your description here'),
                                        maxLines: 3,
                                      ),
                                    ],
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.pop(context),
                                      child: Text('Cancel',
                                          style:
                                              GoogleFonts.montserratAlternates(
                                                  color: Colors.red)),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        if (loggedInUserId == null) {
                                          debugPrint(
                                              'No user is currently signed in.');
                                          Navigator.pop(context);
                                          return;
                                        }
                                        String description =
                                            descriptionController.text.trim();
                                        String name =
                                            titleController.text.trim();

                                        if (description.isEmpty) {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Description cannot be empty.')),
                                          );
                                          return;
                                        }

                                        try {
                                          final String requestId = _firestore
                                              .collection('dummy')
                                              .doc()
                                              .id;

                                          final requestData = {
                                            'requestId': requestId,
                                            'senderId': loggedInUserId,
                                            'receiverId': widget.employeeId,
                                            'description': description,
                                            'timestamp':
                                                FieldValue.serverTimestamp(),
                                            'status': 'pending',
                                            'name': name,
                                          };

                                          await _firestore
                                              .collection('users')
                                              .doc(loggedInUserId)
                                              .collection('sentRequests')
                                              .doc(requestId)
                                              .set(requestData);
                                          await _firestore
                                              .collection('users')
                                              .doc(widget.employeeId)
                                              .collection('recievedRequests')
                                              .doc(requestId)
                                              .set(requestData);

                                          Navigator.pop(context);
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Request sent successfully!')),
                                          );
                                        } catch (e) {
                                          debugPrint(
                                              'Error sending request: $e');
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            const SnackBar(
                                                content: Text(
                                                    'Failed to send request.')),
                                          );
                                        }
                                      },
                                      child: Text('Confirm',
                                          style:
                                              GoogleFonts.montserratAlternates(
                                                  color: AppColors().orange)),
                                    ),
                                  ],
                                );
                              },
                            );
                          }
                        : null, // ❌ تعطيل الزر إذا لم يكن متاحًا
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors().orange.withOpacity(
                          isAvailable
                              ? 1.0
                              : 0.5), // ❌ تغيير اللون ليظهر كأنه غير نشط
                      padding: const EdgeInsets.symmetric(
                          horizontal: 40, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24)),
                    ),
                    child: Text(
                      'Send request',
                      style: GoogleFonts.montserratAlternates(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isAvailable ? Colors.white : AppColors().grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
