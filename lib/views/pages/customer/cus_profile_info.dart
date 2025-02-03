import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/cus_edit_profile_page.dart';
import 'package:hire_harmony/views/pages/map_page.dart';

class CusProfileInfo extends StatefulWidget {
  const CusProfileInfo({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _CusProfileInfoState createState() => _CusProfileInfoState();
}

class _CusProfileInfoState extends State<CusProfileInfo> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      setState(() {
        isLoading = false;
        errorMessage = "No user is currently logged in.";
      });
      return;
    }

    try {
      final DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(currentUser.uid).get();

      if (userDoc.exists) {
        setState(() {
          userData = userDoc.data() as Map<String, dynamic>;
          isLoading = false;
        });
      } else {
        setState(() {
          isLoading = false;
          errorMessage = "User data not found.";
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = "Error fetching user data: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (errorMessage != null) {
      return Scaffold(
        body: Center(
          child: Text(
            errorMessage!,
            style: const TextStyle(color: Colors.red, fontSize: 16),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Theme.of(context).colorScheme.primary,
          ),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: Text(
          'Profile Info',
          style: GoogleFonts.montserratAlternates(
            textStyle: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.edit, color: AppColors().orange),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CusEditProfilePage(),
                ),
              ).then((_) {
                _fetchUserData(); // Refresh the user data after editing
              });
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 20),
            CircleAvatar(
              radius: 50,
              backgroundImage: (userData?['img'] != null &&
                      (userData!['img'] as String).isNotEmpty)
                  ? NetworkImage(userData!['img'])
                  : const AssetImage('lib/assets/images/customer.png')
                      as ImageProvider,
            ),
            const SizedBox(height: 10),
            Text(
              userData?['name'] ?? 'No Name Available',
              style: GoogleFonts.montserratAlternates(
                textStyle: TextStyle(
                  fontSize: 20,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Text(
              userData?['email'] ?? 'No Email Available',
              style: GoogleFonts.montserratAlternates(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors().grey,
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Card(
                  color: Theme.of(context).colorScheme.surface,
                  shadowColor: Theme.of(context).colorScheme.tertiary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Column(
                    children: [
                      ListTile(
                        leading: Icon(Icons.person,
                            color: Theme.of(context).colorScheme.secondary),
                        title: Text(
                          userData?['name'] ?? 'N/A',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        subtitle: Text(
                          'Full name',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.location_on,
                            color: Theme.of(context).colorScheme.secondary),
                        title: Text(
                          'Location',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        trailing: ElevatedButton(
                          onPressed: () {
                            if (userData?['location'] != null) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => MapScreen(
                                      employeeId: _auth.currentUser!.uid),
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content:
                                        Text("❌no location for this user.")),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors().orange,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                          ),
                          child: const Text('See Location',
                              style: TextStyle(color: Colors.white)),
                        ),
                      ),
                      const Divider(),
                      ListTile(
                        leading: Icon(Icons.phone,
                            color: Theme.of(context).colorScheme.secondary),
                        title: Text(
                          userData?['phone'] ?? 'No Contact Info',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                        subtitle: Text(
                          'Contact',
                          style: TextStyle(
                              color: Theme.of(context).colorScheme.primary),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
