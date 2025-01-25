import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'package:hire_harmony/utils/app_colors.dart';

class OrderPage extends StatefulWidget {
  const OrderPage({super.key});

  @override
  State<OrderPage> createState() => _OrderPageState();
}

class _OrderPageState extends State<OrderPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this); // Two tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    if (loggedInUserId == null) {
      return Scaffold(
        backgroundColor: AppColors().orange,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: Colors.white,
          elevation: 0,
          centerTitle: true,
          title: Text(
            'Orders',
            style: TextStyle(color: AppColors().navy),
          ),
        ),
        body: const Center(
          child: Text('User not logged in'),
        ),
      );
    }

    final Stream<List<Map<String, dynamic>>> pendingRequestsStream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(loggedInUserId)
            .collection('sentRequests')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList());

    final Stream<List<Map<String, dynamic>>> ordersStream = FirebaseFirestore
        .instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('orders')
        .where('status', isEqualTo: 'in progress')
        .snapshots()
        .map((snapshot) =>
            snapshot.docs.map((doc) => {...doc.data(), 'id': doc.id}).toList());

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'Orders & Requests',
          style: GoogleFonts.montserratAlternates(
            fontSize: 22,
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors().orange,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors().orange,
          tabs: const [
            Tab(text: 'Pending Requests'),
            Tab(text: 'Orders'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPendingRequestsTab(pendingRequestsStream),
          _buildOrdersTab(ordersStream),
        ],
      ),
    );
  }

  // Pending Requests Tab
  Widget _buildPendingRequestsTab(
      Stream<List<Map<String, dynamic>>> pendingRequestsStream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: pendingRequestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No pending requests found.',
              style: GoogleFonts.montserratAlternates(
                fontSize: 18,
                color: AppColors().navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final requests = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final sentTime = request['sentTime'] as Timestamp?;
            final formattedTime = sentTime != null
                ? DateFormat.jm().format(sentTime.toDate())
                : 'Unknown time';
            final formattedDate = sentTime != null
                ? DateFormat.yMMMMd().format(sentTime.toDate())
                : 'Unknown date';

            return ListTile(
              title: Text(
                request['name'] as String? ?? 'No Title',
                style: GoogleFonts.montserratAlternates(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Request ID: ${request['id']}\nSent: $formattedDate at $formattedTime',
                style: GoogleFonts.montserratAlternates(fontSize: 14),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.delete, color: Colors.red),
                onPressed: () async {
                  final employeeId = request['receiverId'] as String;
                  await _deleteRequest(
                    customerId: FirebaseAuth.instance.currentUser!.uid,
                    requestId: request['id'],
                    employeeId: employeeId,
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  // Orders Tab
  Widget _buildOrdersTab(Stream<List<Map<String, dynamic>>> ordersStream) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              'No orders found.',
              style: GoogleFonts.montserratAlternates(
                fontSize: 18,
                color: AppColors().navy,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final orders = snapshot.data!;

        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            final sentTime = order['sentTime'] as Timestamp?;
            final formattedTime = sentTime != null
                ? DateFormat.jm().format(sentTime.toDate())
                : 'Unknown time';
            final formattedDate = sentTime != null
                ? DateFormat.yMMMMd().format(sentTime.toDate())
                : 'Unknown date';

            return ListTile(
              title: Text(
                order['name'] as String? ?? 'No Title',
                style: GoogleFonts.montserratAlternates(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Text(
                'Order ID: ${order['id']}\nStarted: $formattedDate at $formattedTime',
                style: GoogleFonts.montserratAlternates(fontSize: 14),
              ),
              trailing: Icon(
                Icons.check_circle,
                color: AppColors().green,
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _deleteRequest({
    required String customerId,
    required String requestId,
    required String employeeId,
  }) async {
    try {
      // Delete from customer's collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(customerId)
          .collection('sentRequests')
          .doc(requestId)
          .delete();

      // Delete from employee's collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(employeeId)
          .collection('recievedRequests')
          .doc(requestId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request deleted successfully!')),
      );
    } catch (e) {
      debugPrint('Error deleting request: $e');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Failed to delete request. Please try again.')),
      );
    }
  }
}
