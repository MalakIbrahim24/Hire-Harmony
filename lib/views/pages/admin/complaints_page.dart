import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/chatePage.dart';
import 'package:intl/intl.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});

  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

  Stream<QuerySnapshot> _fetchComplaints() {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('complaints')
        .orderBy('timestamp', descending: true)
        .snapshots();
  }

  /// Function to move the complaint to `resolvedComplaints` and delete it from `complaints`
  Future<void> _resolveComplaint(DocumentSnapshot complaint) async {
    if (loggedInUserId == null) return;

    try {
      final complaintData = complaint.data() as Map<String, dynamic>;

      // Move the complaint to "resolvedComplaints" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(loggedInUserId)
          .collection('resolvedComplaints')
          .doc(complaint.id)
          .set(complaintData);

      // Delete the complaint from "complaints" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(loggedInUserId)
          .collection('complaints')
          .doc(complaint.id)
          .delete();
      final FirebaseFirestore firestore = FirebaseFirestore.instance;
      final data = complaint.data() as Map<String, dynamic>;
      final String userId = data['userId'];
      final String? adminId = FirebaseAuth.instance.currentUser?.uid;
      final String chatRoomID = adminId!.compareTo(userId) < 0
          ? '${adminId}_$userId'
          : '${userId}_$adminId';

      await firestore.collection('chat_rooms').doc(chatRoomID).update({
        'chatController': 'closed',
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint marked as resolved!')),
      );
    } catch (e) {
      debugPrint("Error resolving complaint: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to resolve complaint: $e')),
      );
    }
  }

  void _showComplaintDialog(BuildContext context, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          'Complaint Options',
          style: GoogleFonts.montserratAlternates(
            fontSize: 22,
            color: AppColors().navy,
          ),
        ),
        content: Text(
          'What would you like to do with this complaint?',
          style: GoogleFonts.montserratAlternates(
            fontSize: 12,
            color: AppColors().grey2,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserratAlternates(
                fontSize: 15,
                color: AppColors().navy,
              ),
            ),
          ),
          ElevatedButton(
            style: ButtonStyle(
              backgroundColor: WidgetStatePropertyAll(AppColors().orange),
            ),
            onPressed: () {
              Navigator.pop(context);
              _respondToComplaint(data);
            },
            child: Text(
              'Respond',
              style: GoogleFonts.montserratAlternates(
                fontSize: 15,
                color: AppColors().white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _respondToComplaint(Map<String, dynamic> data) async {
    final String userId = data['userId'];
    final String? adminId = FirebaseAuth.instance.currentUser?.uid;

    if (adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Error: Admin not logged in.')),
      );
      return;
    }

    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not found!')),
      );
      return;
    }

    final userData = userDoc.data()!;
    final String senderEmail = userData['email'];
    final String senderName = userData['name'];

    final String chatRoomID = adminId.compareTo(userId) < 0
        ? '${adminId}_$userId'
        : '${userId}_$adminId';

    final chatRoomDoc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomID)
        .get();

    if (chatRoomDoc.exists) {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomID)
          .update({'chatController': 'open'});
    } else {
      await FirebaseFirestore.instance
          .collection('chat_rooms')
          .doc(chatRoomID)
          .set({
        'participants': [adminId, userId],
        'chatController': 'open',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Chatepage(
          reciverEmail: senderEmail,
          reciverID: userId,
          reciverName: senderName,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'User Complaints',
          style: GoogleFonts.montserratAlternates(
            fontSize: 18,
            color: AppColors().navy,
          ),
        ),
        backgroundColor: AppColors().transparent,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _fetchComplaints(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                'No complaints found.',
                style: GoogleFonts.montserratAlternates(
                  fontSize: 14,
                  color: AppColors().grey,
                ),
              ),
            );
          }

          final complaints = snapshot.data!.docs;

          return SafeArea(
            child: ListView.builder(
              padding: const EdgeInsets.all(10),
              itemCount: complaints.length,
              itemBuilder: (context, index) {
                final complaint = complaints[index];
                final data = complaint.data() as Map<String, dynamic>;

                final String message = data['message'] ?? 'No message';
                final String userId = data['userId'] ?? 'Unknown User';
                final String userName = data['name'] ?? 'Unknown User';

                final Timestamp? timestamp = data['timestamp'] as Timestamp?;
                final formattedDate = timestamp != null
                    ? DateFormat('yyyy-MM-dd HH:mm:ss')
                        .format(timestamp.toDate())
                    : 'Unknown Date';

                return Slidable(
                  key: Key(complaint.id),
                  startActionPane: ActionPane(
                    motion: const BehindMotion(),
                    children: [
                      SlidableAction(
                        onPressed: (context) => _resolveComplaint(complaint),
                        backgroundColor: Colors.green,
                        icon: Icons.check,
                        label: 'Resolve',
                      ),
                    ],
                  ),
                  child: GestureDetector(
                    onTap: () => _showComplaintDialog(context, data),
                    child: Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 3,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(15),
                        title: Text(
                          'Name: $userName',
                          style: GoogleFonts.montserratAlternates(
                              fontSize: 16.5,
                              color: AppColors().navy,
                              fontWeight: FontWeight.w500 // Default color
                              ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 5),
                            Text(
                              message,
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 15,
                                color: AppColors().navy,
                                // Default color
                              ),
                            ),
                            Text(
                              'User ID: $userId',
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 12,
                                color: AppColors().grey2,
                              ),
                            ),
                            Text(
                              'Date: $formattedDate',
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 12,
                                color: AppColors().grey2, // Default color
                              ),
                            ),
                          ],
                        ),
                        leading: const Icon(Icons.report, color: Colors.red),
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
