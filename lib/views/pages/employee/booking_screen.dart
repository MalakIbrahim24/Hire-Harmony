import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/chatePage.dart';
import 'package:intl/intl.dart';

class BookingScreen extends StatelessWidget {
  const BookingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3, // عدد التبويبات
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.black),
            onPressed: () {
              Navigator.pop(context);
              // الرجوع للخلف
            },
          ),
          title: const Text(
            'Booking',
            style: TextStyle(color: Colors.black, fontSize: 18),
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
              Tab(text: 'New Requests'),
              Tab(text: 'Active Bookings'),
              Tab(text: 'Booking History'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // تبويب الطلبات الجديدة
            NewRequestsTab(),
            // تبويب الحجوزات النشطة
            ActiveBookingsTab(),
            // تبويب سجل الحجوزات
            BookingHistoryTab(),
          ],
        ),
      ),
    );
  }
}

// تبويب الطلبات الجديدة
// New Requests Tab
class NewRequestsTab extends StatefulWidget {
  const NewRequestsTab({super.key});

  @override
  State<NewRequestsTab> createState() => _NewRequestsTabState();
}

class _NewRequestsTabState extends State<NewRequestsTab> {
  Future<void> _acceptRequest(String requestId, String receiverId) async {
    try {
      // Fetch the request data to get senderId
      final requestDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .collection('recievedRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Request does not exist.');
      }

      final data = requestDoc.data() as Map<String, dynamic>;
      final senderId = data['senderId'];

      // Get sender's info
      final senderDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .get();

      if (!senderDoc.exists) {
        throw Exception('Sender does not exist.');
      }

      final senderData = senderDoc.data() as Map<String, dynamic>;
      final senderEmail = senderData['email'];
      final senderName = senderData['name'];

      // Generate chatRoomID in a consistent order
      final chatRoomID = receiverId.compareTo(senderId) < 0
          ? '${receiverId}_$senderId'
          : '${senderId}_$receiverId';

      // Update status to "active" in both collections
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .collection('recievedRequests')
          .doc(requestId)
          .update({'status': 'active'});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('sentRequests')
          .doc(requestId)
          .update({'status': 'active'});

      // Check if a chat room exists
      final chatRoomDoc = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomID)
          .get();

      if (chatRoomDoc.exists) {
        // If chat room exists, update chatController
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(chatRoomID)
            .update({'chatController': 'open'});
      } else {
        // If no chat room exists, create a new one
        await FirebaseFirestore.instance
            .collection('chat_rooms')
            .doc(chatRoomID)
            .set({
          'participants': [receiverId, senderId],
          'chatController': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request accepted successfully!')),
      );

      // Navigate to the chat room
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => Chatepage(
            reciverEmail: senderEmail,
            reciverID: senderId,
            reciverName: senderName,
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error accepting request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error accepting request: $e')),
      );
    }
  }

  Future<void> _cancelRequest(String requestId, String receiverId) async {
    try {
      // Fetch request to get senderId
      final requestDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .collection('recievedRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Request does not exist.');
      }

      final senderId = requestDoc['senderId'];

      // Delete request from both collections
      await FirebaseFirestore.instance
          .collection('users')
          .doc(receiverId)
          .collection('recievedRequests')
          .doc(requestId)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('sentRequests')
          .doc(requestId)
          .delete();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request canceled successfully!')),
      );
    } catch (e) {
      debugPrint('Error canceling request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error canceling request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    if (loggedInUserId == null) {
      return const Center(
        child: Text(
          'User not logged in.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    final Stream<QuerySnapshot> receivedRequestsStream = FirebaseFirestore
        .instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('recievedRequests')
        .where('status', isEqualTo: 'pending')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: receivedRequestsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.new_releases, size: 100, color: AppColors().orange),
                const SizedBox(height: 16),
                const Text(
                  'No new requests found!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final requests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (context, index) {
            final request = requests[index];
            final senderId = request['senderId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(senderId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage('https://via.placeholder.com/150'),
                      radius: 30,
                    ),
                    title: Text('Unknown User'),
                    subtitle: Text('No data available'),
                  );
                }

                final userDoc = snapshot.data!;
                final userImg =
                    userDoc['img'] ?? 'https://via.placeholder.com/150';
                final senderName = userDoc['name'] ?? 'Unknown Sender';
                final description =
                    request['description'] ?? 'No description provided';
                final timestamp = request['timestamp'] as Timestamp?;
                final formattedTime = timestamp != null
                    ? DateFormat.jm().format(timestamp.toDate())
                    : 'Unknown time';
                final formattedDate = timestamp != null
                    ? DateFormat.yMMMMd().format(timestamp.toDate())
                    : 'Unknown date';

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(userImg),
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                senderName,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(description),
                              const SizedBox(height: 4),
                              Text(
                                'Requested on $formattedDate at $formattedTime',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () => _acceptRequest(
                                request.id,
                                loggedInUserId,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors().navy,
                                minimumSize: const Size(80, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Accept',
                                  style: TextStyle(color: AppColors().white)),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _cancelRequest(
                                request.id,
                                loggedInUserId,
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors().red,
                                minimumSize: const Size(80, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text('Cancel',
                                  style: TextStyle(color: AppColors().white)),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// تبويب الحجوزات النشطة
class ActiveBookingsTab extends StatelessWidget {
  const ActiveBookingsTab({super.key});

  Future<void> _confirmBooking(
      BuildContext context, DocumentSnapshot activeRequest) async {
    try {
      final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;
      if (loggedInUserId == null) throw Exception('User not logged in.');

      final data = activeRequest.data() as Map<String, dynamic>;
      final String senderId = data['senderId'] ?? '';

      // Prepare data for the orders collection
      final orderData = {
        'name': data['name'] ?? 'Unknown',
        'orderId': activeRequest.id, // Same as request document ID
        'senderId': senderId,
        'reciverId': loggedInUserId,
        'img': data['senderImg'] ?? 'https://via.placeholder.com/150',
        'description': data['description'] ?? 'No description provided',
        'confirmedTime': FieldValue.serverTimestamp(),
        'status': 'in progress',
      };

      // Check if a chat room exists
      final chatRoomQuery = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: loggedInUserId)
          .get();

      DocumentReference? chatRoomRef;

// Check if the query has any documents
      if (chatRoomQuery.docs.isNotEmpty) {
        // Try to find the matching chat room
        final matchingChatRooms = chatRoomQuery.docs.where((doc) {
          final participants = doc['participants'] as List<dynamic>;
          return participants.contains(senderId) && participants.length == 2;
        }).toList();

        if (matchingChatRooms.isNotEmpty) {
          final chatRoomDoc =
              matchingChatRooms.first; // Get the first matching chat room
          chatRoomRef = FirebaseFirestore.instance
              .collection('chat_rooms')
              .doc(chatRoomDoc.id);
          await chatRoomRef.update({'chatController': 'open'});
        }
      }

// If no matching chat room is found, create a new one
      if (chatRoomRef == null) {
        chatRoomRef = FirebaseFirestore.instance.collection('chat_rooms').doc();
        await chatRoomRef.set({
          'participants': [loggedInUserId, senderId],
          'chatController': 'open',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      // Update the status to "in progress" in both collections
      await FirebaseFirestore.instance
          .collection('users')
          .doc(loggedInUserId)
          .collection('recievedRequests')
          .doc(activeRequest.id)
          .update({'status': 'in progress'});

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('sentRequests')
          .doc(activeRequest.id)
          .update({'status': 'in progress'});

      // Add the booking to the "orders" collection of the employee
      await FirebaseFirestore.instance
          .collection('users')
          .doc(loggedInUserId)
          .collection('orders')
          .doc(activeRequest.id)
          .set(orderData);

      // Add the booking to the "orders" collection of the customer
      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('orders')
          .doc(activeRequest.id)
          .set(orderData);

      // Add the booking to the "bookingHistory" collection of the employee
      await FirebaseFirestore.instance
          .collection('users')
          .doc(loggedInUserId)
          .collection('bookingHistory')
          .doc(activeRequest.id)
          .set(orderData);

      // Remove the request from both `sentRequests` and `recievedRequests` collections
      await FirebaseFirestore.instance
          .collection('users')
          .doc(loggedInUserId)
          .collection('recievedRequests')
          .doc(activeRequest.id)
          .delete();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(senderId)
          .collection('sentRequests')
          .doc(activeRequest.id)
          .delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Booking confirmed successfully!')),
      );
    } catch (e) {
      debugPrint('Error confirming booking: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error confirming booking: $e')),
      );
    }
  }

  Future<void> _revokeRequest(BuildContext context,
      DocumentSnapshot activeRequest, String loggedInUserId) async {
    try {
      // Extract customer (sender) ID
      final data = activeRequest.data() as Map<String, dynamic>;
      final String senderId = data['senderId'] ?? '';

      // Query Firestore to find the correct chat room
      final chatRoomQuery = await FirebaseFirestore.instance
          .collection('chat_rooms')
          .where('participants', arrayContains: loggedInUserId)
          .get();

      // Find the chat room with the matching participants
      final chatRoomDoc = chatRoomQuery.docs.firstWhere(
        (doc) {
          final participants = doc['participants'] as List<dynamic>;
          return participants.contains(senderId) && participants.length == 2;
        },
        orElse: () => throw Exception('Chat room not found.'),
      );

      final chatRoomId = chatRoomDoc.id;

      // Update the chatController field to "closed" in the chat room
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomId)
          .update({'chatController': 'closed'});

      // Delete the request document
      await activeRequest.reference.delete();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Request revoked successfully!')),
      );
    } catch (e) {
      debugPrint('Error revoking request: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error revoking request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    if (loggedInUserId == null) {
      return const Center(
        child: Text(
          'User not logged in.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Firestore query for active bookings
    final Stream<QuerySnapshot> activeBookingsStream = FirebaseFirestore
        .instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('recievedRequests')
        .where('status', isEqualTo: 'active')
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: activeBookingsStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox, size: 100, color: AppColors().orange),
                const SizedBox(height: 16),
                const Text(
                  'No active bookings found!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final activeRequests = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: activeRequests.length,
          itemBuilder: (context, index) {
            final activeRequest = activeRequests[index];

            final data = activeRequest.data() as Map<String, dynamic>;
            final senderId = data['senderId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(senderId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage('https://via.placeholder.com/150'),
                      radius: 30,
                    ),
                    title: Text('Unknown User'),
                    subtitle: Text('No data available'),
                  );
                }

                final userDoc = snapshot.data!;
                final userImg =
                    userDoc['img'] ?? 'https://via.placeholder.com/150';
                final name = userDoc['name'] ?? 'Unknown';
                final description =
                    data['description'] ?? 'No description provided';
                final acceptedOnTimestamp =
                    data['acceptedOn'] as Timestamp? ?? Timestamp.now();
                final formattedAcceptedDate =
                    DateFormat.yMMMMd().format(acceptedOnTimestamp.toDate());
                final formattedAcceptedTime =
                    DateFormat.jm().format(acceptedOnTimestamp.toDate());

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(userImg),
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(description),
                              const SizedBox(height: 4),
                              Text(
                                'Accepted on $formattedAcceptedDate at $formattedAcceptedTime',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          children: [
                            ElevatedButton(
                              onPressed: () =>
                                  _confirmBooking(context, activeRequest),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors().navy,
                                minimumSize: const Size(80, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Confirm',
                                style: GoogleFonts.montserratAlternates(
                                  fontSize: 12,
                                  color: AppColors().white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () => _revokeRequest(
                                  context, activeRequest, loggedInUserId),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors().red,
                                minimumSize: const Size(80, 36),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Revoke',
                                style: GoogleFonts.montserratAlternates(
                                  fontSize: 12,
                                  color: AppColors().white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// تبويب سجل الحجوزات
class BookingHistoryTab extends StatelessWidget {
  const BookingHistoryTab({super.key});

  @override
  Widget build(BuildContext context) {
    final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

    if (loggedInUserId == null) {
      return const Center(
        child: Text(
          'User not logged in.',
          style: TextStyle(fontSize: 18, color: Colors.grey),
        ),
      );
    }

    // Firestore query for booking history
    final Stream<QuerySnapshot> bookingHistoryStream = FirebaseFirestore
        .instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('bookingHistory')
        .orderBy('confirmedTime', descending: true)
        .snapshots();

    return StreamBuilder<QuerySnapshot>(
      stream: bookingHistoryStream,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.history, size: 100, color: AppColors().grey),
                const SizedBox(height: 16),
                const Text(
                  'No booking history found!',
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
              ],
            ),
          );
        }

        final bookings = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final booking = bookings[index];
            final data = booking.data() as Map<String, dynamic>;
            final senderId = data['senderId'];

            return FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance
                  .collection('users')
                  .doc(senderId)
                  .get(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || !snapshot.data!.exists) {
                  return const ListTile(
                    leading: CircleAvatar(
                      backgroundImage:
                          NetworkImage('https://via.placeholder.com/150'),
                      radius: 30,
                    ),
                    title: Text('Unknown User'),
                    subtitle: Text('No data available'),
                  );
                }

                final userDoc = snapshot.data!;
                final userImg =
                    userDoc['img'] ?? 'https://via.placeholder.com/150';
                final name = userDoc['name'] ?? 'Unknown';
                final description =
                    data['description'] ?? 'No description provided';
                final confirmedTimestamp =
                    data['confirmedTime'] as Timestamp? ?? Timestamp.now();
                final formattedDate =
                    DateFormat.yMMMMd().format(confirmedTimestamp.toDate());
                final formattedTime =
                    DateFormat.jm().format(confirmedTimestamp.toDate());

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundImage: NetworkImage(userImg),
                          radius: 30,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(description),
                              const SizedBox(height: 4),
                              Text(
                                'Confirmed on $formattedDate at $formattedTime',
                                style: const TextStyle(color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        const Icon(
                          Icons.check_circle,
                          color: Colors.green,
                          size: 24,
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}
