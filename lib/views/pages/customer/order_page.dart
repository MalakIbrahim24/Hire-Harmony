import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hire_harmony/views/pages/customer/reviews_page.dart';
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
    _tabController = TabController(length: 3, vsync: this); // Three tabs
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<String> getEmployeeNameById(String userId) async {
    try {
      DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        return userDoc['name'] ?? 'Unknown';
      } else {
        return 'Unknown';
      }
    } catch (e) {
      print("Error fetching employee name: $e");
      return 'Error';
    }
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

    final Stream<List<Map<String, dynamic>>> inProgressOrdersStream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(loggedInUserId)
            .collection('orders')
            .where('status', isEqualTo: 'in progress')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList());

    final Stream<List<Map<String, dynamic>>> completedOrdersStream =
        FirebaseFirestore.instance
            .collection('users')
            .doc(loggedInUserId)
            .collection('completedOrders')
            .snapshots()
            .map((snapshot) => snapshot.docs
                .map((doc) => {...doc.data(), 'id': doc.id})
                .toList());

    return SafeArea(
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          automaticallyImplyLeading: false,
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
              Tab(text: 'Pending'),
              Tab(text: 'In progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildPendingRequestsTab(pendingRequestsStream),
            _buildOrdersTab(inProgressOrdersStream),
            _buildOrdersTab(completedOrdersStream,
                isCompleted: true), // ✅ تمكين النقر للطلبات المكتملة فقط
          ],
        ),
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

  // Orders and Completed Orders Tabs
  Widget _buildOrdersTab(Stream<List<Map<String, dynamic>>> ordersStream,
      {bool isCompleted = false}) {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Text(
              isCompleted ? 'No completed orders found.' : 'No orders found.',
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

            final status = order['status'] as String? ?? 'Unknown';

            return ListTile(
              title: Text(
                order['name'] as String? ?? 'No Title',
                style: GoogleFonts.montserratAlternates(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              subtitle: FutureBuilder<String>(
                future: getEmployeeNameById(order['reciverId']),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Text(
                      'Loading...',
                      style: GoogleFonts.montserratAlternates(fontSize: 14),
                    );
                  } else if (snapshot.hasError) {
                    return Text(
                      'Error fetching name',
                      style: GoogleFonts.montserratAlternates(
                          fontSize: 14, color: Colors.red),
                    );
                  } else {
                    return Text(
                      'Employee Name: ${snapshot.data!}',
                      style: GoogleFonts.montserratAlternates(fontSize: 14),
                    );
                  }
                },
              ),
              trailing: Icon(
                Icons.circle,
                color: (order['reviewed'] == true)
                    ? Colors.grey
                    : _getStatusColor(status),
                size: 12,
              ),

              onTap: isCompleted
                  ? () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReviewPage(
                            orderId:
                                order['id']?.toString() ?? 'Unnamed Employee',
                            employeeId: order['reciverId']?.toString() ??
                                'Unnamed Employee',
                            employeeName:
                                order['name']?.toString() ?? 'Unnamed Employee',
                          ),
                        ),
                      );
                    }
                  : null, // لا يفعل شيئًا إذا لم يكن الطلب مكتملًا
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
