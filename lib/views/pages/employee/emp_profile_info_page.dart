import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/widgets/employee/build_static_button.dart';
import 'package:hire_harmony/views/widgets/employee/photo_tab_view.dart';
import 'package:hire_harmony/views/widgets/employee/reviews_tab_view.dart';

class EmpProfileInfoPage extends StatefulWidget {
  const EmpProfileInfoPage({super.key});

  @override
  State<EmpProfileInfoPage> createState() => _EmpProfileInfoPageState();
}

class _EmpProfileInfoPageState extends State<EmpProfileInfoPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Employee data fields
  String? profileImageUrl;
  String name = '';
  String location = '';
  String rating = '';
  String id = '';
  bool _isEditing = false;
  String aboutMe = '';
  final TextEditingController _aboutMeController = TextEditingController();
  num reviewsNum = 0;
  List<Map<String, dynamic>> reviews = [];
  List<String> services = []; // Added missing services list

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchEmployeeData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _saveAboutMe() async {
    try {
      final User? user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).update({
        'about': _aboutMeController.text,
      });

      setState(() {
        aboutMe = _aboutMeController.text;
        _isEditing = false;
      });
    } catch (e) {
      debugPrint('Error saving "About Me": $e');
    }
  }

  Future<void> _saveServiceToFirestore(String serviceName) async {
  try {
    final User? user = _auth.currentUser;
    if (user == null) {
      debugPrint('User is not logged in');
      return;
    }

    final DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.update({
      'services': FieldValue.arrayUnion([serviceName]),
    });

    setState(() {
      services.add(serviceName);
    });

    debugPrint('Service added successfully');
  } catch (e) {
    debugPrint('Error adding service: $e');
  }
}

Future<void> _deleteService(String serviceName) async {
  try {
    final User? user = _auth.currentUser;
    if (user == null) {
      debugPrint('User is not logged in');
      return;
    }

    final DocumentReference userDoc = _firestore.collection('users').doc(user.uid);

    await userDoc.update({
      'services': FieldValue.arrayRemove([serviceName]),
    });

    setState(() {
      services.remove(serviceName);
    });

    debugPrint('Service deleted successfully');
  } catch (e) {
    debugPrint('Error deleting service: $e');
  }
}

Future<void> _fetchEmployeeData() async {
  try {
    final User? user = _auth.currentUser;
    if (user == null) return;

    final DocumentSnapshot employeeDoc =
        await _firestore.collection('users').doc(user.uid).get();

    if (employeeDoc.exists) {
      final data = employeeDoc.data() as Map<String, dynamic>;

      setState(() {
        profileImageUrl = data['img'] ?? 'https://via.placeholder.com/150';
        name = data['name'] ?? 'Unknown Name';
        location = data['location'] ?? 'Unknown Location';
        rating = data['rating'] ?? '0.0';
        aboutMe = data['about'] ?? 'No description available.';
        _aboutMeController.text = aboutMe;
        reviewsNum = data['reviews'] ?? 0;
        id = data['uid'] ?? 'User ID not found';
        services = (data['services'] as List<dynamic>?)
                ?.cast<String>() ??
            []; // جلب قائمة الخدمات
      });
    }

    final QuerySnapshot reviewsSnapshot = await _firestore
        .collection('users')
        .doc(user.uid)
        .collection('reviews')
        .get();

    setState(() {
      reviews = reviewsSnapshot.docs.map((doc) {
        final reviewData = doc.data() as Map<String, dynamic>;
        return {
          'name': reviewData['name'] ?? 'Anonymous',
          'rating': reviewData['rating'] ?? '0.0',
          'date': reviewData['date'] ?? '',
          'review': reviewData['review'] ?? '',
          'image': reviewData['image'] ??
              'https://via.placeholder.com/50',
        };
      }).toList();
    });
  } catch (e) {
    debugPrint('Error fetching employee data: $e');
  }
}


  void _showAddServiceDialog(BuildContext context) {
    final TextEditingController _serviceController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          title: Text('Add Service',
              style: GoogleFonts.montserratAlternates(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              )),
          content: TextField(
            controller: _serviceController,
            decoration: InputDecoration(
              hintText: 'Enter service name',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                if (_serviceController.text.isNotEmpty) {
                  _saveServiceToFirestore(_serviceController.text.trim());
                  Navigator.of(context).pop();
                }
              },
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.montserratAlternates(
            color: Theme.of(context).colorScheme.inversePrimary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.grey),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: AppColors().orange,
            ),
            onPressed: () {
              if (_isEditing) {
                _saveAboutMe(); // حفظ التغييرات
              } else {
                setState(() {
                  _isEditing = true; // تفعيل وضع التعديل
                });
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile Picture
                  Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: profileImageUrl != null
                          ? Image.network(
                              profileImageUrl!,
                              width: 160,
                              height: 160,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, progress) {
                                if (progress == null) return child;
                                return const CircularProgressIndicator();
                              },
                              errorBuilder: (context, error, stackTrace) =>
                                  const Icon(Icons.broken_image, size: 160),
                            )
                          : const CircularProgressIndicator(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Name, Location, and Rating
                  Center(
                    child: Column(
                      children: [
                        Text(
                          name,
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
                            Icon(Icons.location_on,
                                color: AppColors().orange, size: 20),
                            const SizedBox(width: 4),
                            Text(location,
                                style: GoogleFonts.montserratAlternates(
                                  fontSize: 14,
                                  color: Colors.grey,
                                )),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.star,
                                color: AppColors().orange, size: 20),
                            const SizedBox(width: 4),
                            Text('$rating ($reviewsNum reviews)',
                                style: GoogleFonts.montserratAlternates(
                                  fontSize: 14,
                                  color: Colors.grey,
                                )),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Me
                  Text(
                    'About me',
                    style: GoogleFonts.montserratAlternates(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.inversePrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _aboutMeController,
                    enabled: _isEditing, // النص قابل للتعديل فقط في وضع التعديل
                    maxLines: null,
                    style: TextStyle(
                      fontSize: 16,
                      color: _isEditing
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // My Services
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'My Services',
                            style: GoogleFonts.montserratAlternates(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color:
                                  Theme.of(context).colorScheme.inversePrimary,
                            ),
                          ),
                          if (_isEditing) // إظهار الزر فقط عند التعديل
                            IconButton(
                              icon: Icon(Icons.add, color: AppColors().orange),
                              onPressed: () {
                                _showAddServiceDialog(context);
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: services
                              .map((service) => Padding(
                                    padding: const EdgeInsets.only(right: 8.0),
                                    child: Stack(
                                      alignment: Alignment
                                          .topRight, // محاذاة زر "إكس" في الزاوية
                                      children: [
                                        buildStaticButton(service),
                                        if (_isEditing) // إظهار زر "إكس" فقط عند التعديل
                                          Positioned(
                                            top: -4, // التحكم بمكان الأيقونة
                                            right: -4,
                                            child: GestureDetector(
                                              onTap: () {
                                                _deleteService(
                                                    service); // حذف الخدمة
                                              },
                                              child: Container(
                                                decoration: BoxDecoration(
                                                  color: Theme.of(context)
                                                      .colorScheme
                                                      .surface
                                                      .withValues(alpha: 0.8),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: Icon(
                                                  Icons.close,
                                                  color: AppColors().orange,
                                                  size: 16,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ))
                              .toList(),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // Tabs Section
                  TabBar(
                    controller: _tabController,
                    labelColor: AppColors().orange,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: AppColors().orange,
                    tabs: const [
                      Tab(text: 'Photos'),
                      Tab(text: 'Review'),
                    ],
                  ),
                  SizedBox(
                    height: 400, // Height of TabBarView
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Photos & Videos Tab
                        PhotoTabView(
                          employeeId: id,
                        ),

                        // Reviews Tab
                        ReviewsTapView(
                          employeeId: id,
                        )
                      ],
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