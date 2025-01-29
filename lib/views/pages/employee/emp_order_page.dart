import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class EmpOrderPage extends StatelessWidget {
  const EmpOrderPage({super.key});

  Future<void> _markOrderAsCompleted(
      BuildContext context,
      String orderId,
      String customerId,
      String employeeId,
      Map<String, dynamic> orderData) async {
    try {
      final FirebaseFirestore firestore = FirebaseFirestore.instance;

      // Update order status to 'completed' for both customer and employee
      final orderUpdateData = {
        ...orderData,
        'status': 'completed',
      };

      // Move the order to `completedOrders` for customer
      await firestore
          .collection('users')
          .doc(customerId)
          .collection('completedOrders')
          .doc(orderId)
          .set(orderUpdateData);

      // Move the order to `completedOrders` for employee
      await firestore
          .collection('users')
          .doc(employeeId)
          .collection('completedOrders')
          .doc(orderId)
          .set(orderUpdateData);

      // Remove the order from current `orders` collection
      await firestore
          .collection('users')
          .doc(employeeId)
          .collection('orders')
          .doc(orderId)
          .delete();

      // Close the chat room
      final chatId = employeeId.compareTo(customerId) < 0
          ? '$employeeId$customerId'
          : '$customerId$employeeId';

      await firestore.collection('chat_rooms').doc(chatId).update({
        'chatController': 'closed',
      });

      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Order marked as completed.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _showOrderDialog(BuildContext context, String orderId, String customerId,
      String employeeId, Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Order Options'),
          content: const Text(
              'Would you like to mark this order as completed or cancel?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext); // Close the dialog
                _confirmCompletion(context, orderId, customerId, employeeId,
                    orderData); // Confirm completion
              },
              child: const Text('Completed'),
            ),
          ],
        );
      },
    );
  }

  void _confirmCompletion(BuildContext context, String orderId,
      String customerId, String employeeId, Map<String, dynamic> orderData) {
    showDialog(
      context: context,
      builder: (confirmDialogContext) {
        return AlertDialog(
          title: const Text('Confirm Completion'),
          content: const Text(
              'Are you sure you want to mark this order as completed? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(confirmDialogContext),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(
                    confirmDialogContext); // Close the confirmation dialog
                _markOrderAsCompleted(
                    context, orderId, customerId, employeeId, orderData);
              },
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    if (loggedInUserId == null) {
      return Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
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

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          automaticallyImplyLeading: false,
          centerTitle: true,
          title: Text(
            'Orders',
            style: GoogleFonts.montserratAlternates(
              fontSize: 22,
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
          bottom: TabBar(
            dividerColor: AppColors().transparent,
            labelColor: AppColors().orange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors().orange,
            labelStyle: const TextStyle(
              fontSize: 16, // Text size for selected tabs
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14, // Text size for unselected tabs
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'In Progress'),
              Tab(text: 'Completed'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildOrdersTab(loggedInUserId, 'in progress'),
            _buildOrdersTabCom(
              loggedInUserId,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrdersTab(String loggedInUserId, String status) {
    final Stream<QuerySnapshot> ordersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('orders')
        .where('status', isEqualTo: status)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: ordersStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error fetching $status orders. Please try again later.',
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
              'No $status orders found.',
              style: GoogleFonts.montserratAlternates(
                fontSize: 18,
                color: AppColors().grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;

              final orderId = orders[index].id;
              final customerId = order['senderId'] as String? ?? '';
              final employeeId = loggedInUserId;

              final sentTime = order['confirmedTime'] as Timestamp?;
              final formattedTime = sentTime != null
                  ? DateFormat.jm().format(sentTime.toDate())
                  : 'Unknown Time';
              final formattedDate = sentTime != null
                  ? DateFormat.yMMMMd().format(sentTime.toDate())
                  : 'Unknown Date';

              final orderName = order['name'] as String? ?? 'No Title';
              final orderID = order['orderId'] as String? ?? 'N/A';
              final currentStatus = order['status'] as String? ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(customerId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                              'assets/images/placeholder.png'), // Replace with local placeholder if needed
                        );
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.data() == null) {
                        return const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                              'assets/images/placeholder.png'), // Replace with local placeholder if needed
                        );
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final imgUrl =
                          userData['img'] ?? 'https://via.placeholder.com/150';

                      return CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(imgUrl),
                      );
                    },
                  ),

                  title: Text(
                    orderName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Order ID: $orderID\n'
                      'Sent on: $formattedDate at $formattedTime'),
                  trailing: Icon(
                    Icons.circle,
                    color: _getStatusColor(currentStatus),
                    size: 12,
                  ),
                  onTap: status == 'in progress'
                      ? () => _showOrderDialog(
                          context, orderId, customerId, employeeId, order)
                      : null, // Disable tap for completed orders
                ),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildOrdersTabCom(
    String loggedInUserId,
  ) {
    final Stream<QuerySnapshot> ordersStream = FirebaseFirestore.instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('completedOrders')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
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
              'No Completed orders found.',
              style: GoogleFonts.montserratAlternates(
                fontSize: 18,
                color: AppColors().grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          );
        }

        final orders = snapshot.data!.docs;

        return SafeArea(
          child: ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;

              final customerId = order['senderId'] as String? ?? '';

              final sentTime = order['confirmedTime'] as Timestamp?;
              final formattedTime = sentTime != null
                  ? DateFormat.jm().format(sentTime.toDate())
                  : 'Unknown Time';
              final formattedDate = sentTime != null
                  ? DateFormat.yMMMMd().format(sentTime.toDate())
                  : 'Unknown Date';

              final orderName = order['name'] as String? ?? 'No Title';
              final orderID = order['orderId'] as String? ?? 'N/A';
              final currentStatus = order['status'] as String? ?? 'Unknown';

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: FutureBuilder<DocumentSnapshot>(
                    future: FirebaseFirestore.instance
                        .collection('users')
                        .doc(customerId)
                        .get(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                              'assets/images/placeholder.png'), // Replace with local placeholder if needed
                        );
                      }

                      if (snapshot.hasError ||
                          !snapshot.hasData ||
                          snapshot.data!.data() == null) {
                        return const CircleAvatar(
                          radius: 24,
                          backgroundImage: AssetImage(
                              'assets/images/placeholder.png'), // Replace with local placeholder if needed
                        );
                      }

                      final userData =
                          snapshot.data!.data() as Map<String, dynamic>;
                      final imgUrl =
                          userData['img'] ?? 'https://via.placeholder.com/150';

                      return CircleAvatar(
                        radius: 24,
                        backgroundImage: NetworkImage(imgUrl),
                      );
                    },
                  ),

                  title: Text(
                    orderName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Order ID: $orderID\n'
                      'Sent on: $formattedDate at $formattedTime'),
                  trailing: Icon(
                    Icons.circle,
                    color: _getStatusColor(currentStatus),
                    size: 12,
                  ),
                  onTap: null, // Disable tap for completed orders
                ),
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
