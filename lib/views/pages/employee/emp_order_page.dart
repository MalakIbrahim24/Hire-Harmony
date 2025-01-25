import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EmpOrderPage extends StatelessWidget {
  const EmpOrderPage({super.key});

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

  @override
  Widget build(BuildContext context) {
    final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    if (loggedInUserId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          automaticallyImplyLeading: false,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Orders',
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ),
        body: const Center(
          child: Text('User not logged in'),
        ),
      );
    }

    return FutureBuilder<String?>(
      future: _fetchEmployeeState(loggedInUserId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
              automaticallyImplyLeading: false,
            ),
            extendBodyBehindAppBar: true,
            body: Center(
              child: Text(
                'Error loading data. Please try again later.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserratAlternates(
                  fontSize: 18,
                  color: AppColors().navy,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        } else if (snapshot.data == null) {
          return Scaffold(
            appBar: AppBar(
              backgroundColor: AppColors().transparent,
              automaticallyImplyLeading: false,
            ),
            extendBodyBehindAppBar: true,
            body: Center(
              child: Text(
                'No orders found.',
                style: GoogleFonts.montserratAlternates(
                  fontSize: 14,
                  color: AppColors().grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          );
        }

        final String? employeeState = snapshot.data;

        if (employeeState == 'pending') {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            extendBodyBehindAppBar: true,
            body: Stack(
              children: [
                Container(
                  color: Colors.black.withValues(alpha: 0.35), // Dark overlay
                ),
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.lock,
                        size: 70,
                        color: AppColors().white,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        textAlign: TextAlign.center,
                        'Orders are locked for now, we are checking your information',
                        style: GoogleFonts.montserratAlternates(
                          fontSize: 20,
                          color: AppColors().white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Please wait until we verify your identity.',
                        style: GoogleFonts.montserratAlternates(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        // Stream for orders collection
        final Stream<QuerySnapshot> ordersStream = FirebaseFirestore.instance
            .collection('users')
            .doc(loggedInUserId)
            .collection('orders')
            .snapshots();

        return Scaffold(
          backgroundColor: Theme.of(context).colorScheme.surface,
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            automaticallyImplyLeading: false,
            elevation: 0,
            centerTitle: true,
            title: Text(
              'Orders',
              style: GoogleFonts.montserratAlternates(
                fontSize: 22,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          body: StreamBuilder<QuerySnapshot>(
            stream: ordersStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'Error fetching orders. Please try again later.',
                    style: GoogleFonts.montserratAlternates(
                      fontSize: 16,
                      color: AppColors().navy,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return Center(
                  child: Text(
                    'No orders found.',
                    style: GoogleFonts.montserratAlternates(
                      fontSize: 18,
                      color: AppColors().grey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                );
              }

              final orders = snapshot.data!.docs;

              return ListView.builder(
                padding: const EdgeInsets.all(10),
                itemCount: orders.length,
                itemBuilder: (context, index) {
                  final order = orders[index].data() as Map<String, dynamic>;

                  // Safely fetch fields with null checks
                  final sentTime = order['confirmedTime'] as Timestamp?;
                  final formattedTime = sentTime != null
                      ? DateFormat.jm().format(sentTime.toDate())
                      : 'Unknown Time';
                  final formattedDate = sentTime != null
                      ? DateFormat.yMMMMd().format(sentTime.toDate())
                      : 'Unknown Date';

                  final orderName = order['name'] as String? ?? 'No Title';
                  final orderID = order['orderId'] as String? ?? 'N/A';
                  final status = order['status'] as String? ?? 'Unknown';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: NetworkImage(
                          order['img'] ?? 'https://via.placeholder.com/150',
                        ),
                      ),
                      title: Text(
                        orderName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Order ID: $orderID\n'
                          'Sent on: $formattedDate at $formattedTime'),
                      trailing: Icon(
                        Icons.circle,
                        color: _getStatusColor(status),
                        size: 12,
                      ),
                    ),
                  );
                },
              );
            },
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'in progress':
        return AppColors().orange;
      case 'completed':
        return AppColors().green;
      case 'assigned':
        return AppColors().navy2;
      case 'accepted':
        return Colors.pink;
      default:
        return Colors.grey;
    }
  }
}
