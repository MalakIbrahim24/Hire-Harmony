import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/widgets/customer/build_menu_container.dart';
import 'package:hire_harmony/views/widgets/customer/state_item.dart';

class CusProfilePage extends StatefulWidget {
  const CusProfilePage({super.key});

  @override
  State<CusProfilePage> createState() => _CusProfilePageState();
}

class _CusProfilePageState extends State<CusProfilePage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  int orderCount = 0;
  int ticketCount = 0;
  int pendingRequestCount = 0;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _fetchOrderCount();
    _fetchTicketCount();
    _fetchPendingRequestCount();
  }

  Future<void> _fetchUserData() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        final DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(currentUser.uid).get();
        if (userDoc.exists) {
          setState(() {
            userData = userDoc.data() as Map<String, dynamic>;
          });
        }
      } catch (e) {
        debugPrint('Error fetching user data: $e');
      }
    }
  }

  Future<void> _fetchOrderCount() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        final QuerySnapshot ordersSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('completedOrders')
            .get();

        setState(() {
          orderCount = ordersSnapshot.size;
        });
      } catch (e) {
        debugPrint('Error fetching orders count: $e');
      }
    }
  }

  Future<void> _fetchTicketCount() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        final QuerySnapshot ticketsSnapshot = await _firestore
            .collection('ticketsSent')
            .where('uid', isEqualTo: currentUser.uid)
            .get();

        setState(() {
          ticketCount = ticketsSnapshot.size;
        });
      } catch (e) {
        debugPrint('Error fetching tickets count: $e');
      }
    }
  }

  Future<void> _fetchPendingRequestCount() async {
    final User? currentUser = _auth.currentUser;

    if (currentUser != null) {
      try {
        final QuerySnapshot requestsSnapshot = await _firestore
            .collection('users')
            .doc(currentUser.uid)
            .collection('sentRequests')
            .where('status', isEqualTo: 'pending')
            .get();

        setState(() {
          pendingRequestCount = requestsSnapshot.size;
        });
      } catch (e) {
        debugPrint('Error fetching pending requests count: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          title: Text(
            'Profile',
            style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold),
          ),
          centerTitle: true,
        ),
        body: userData == null
            ? const Center(child: CircularProgressIndicator())
            : Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: userData!['img'] != null
                        ? NetworkImage(userData!['img'])
                        : const AssetImage('lib/assets/images/customer.png')
                            as ImageProvider,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    userData!['name'] ?? 'Unnamed User',
                    style: GoogleFonts.montserratAlternates(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  Text(
                    userData!['email'] ?? 'No email provided',
                    style: GoogleFonts.montserratAlternates(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    padding: const EdgeInsets.all(20),
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
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        StatItem(
                            label: ' Orders \n Complete',
                            value: orderCount.toString()),
                        StatItem(
                            label: ' Support \n Tickets',
                            value: ticketCount.toString()),
                        StatItem(
                            label: ' Pending \n Requests',
                            value: pendingRequestCount.toString()),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Expanded(
                    child: buildMenuContainer(),
                  ),
                ],
              ),
      ),
    );
  }
}
