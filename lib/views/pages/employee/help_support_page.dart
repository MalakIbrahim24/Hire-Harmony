import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';

class HelpSupportPage extends StatefulWidget {
  final String? adminId; // Admin ID to send the complaint

  const HelpSupportPage({super.key, this.adminId});

  @override
  State<HelpSupportPage> createState() => _HelpSupportPageState();
}

class _HelpSupportPageState extends State<HelpSupportPage> {
  final TextEditingController _messageController = TextEditingController();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  bool _isLoading = false;

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  Future<void> _submitMessage() async {
    final message = _messageController.text.trim();
    if (message.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please enter a message before submitting.')),
      );
      return;
    }

    final String? currentUserId = _auth.currentUser?.uid;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User not logged in!')),
      );
      return;
    }

    if (widget.adminId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Admin ID not found. Cannot send complaint.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;
      final DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(loggedInUserId)
          .get();
      final name = adminSnapshot['name'];
      // Store complaint in the admin's "complaints" collection
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.adminId)
          .collection('complaints')
          .add({
        'userId': currentUserId,
        'message': message,
        'timestamp': FieldValue.serverTimestamp(),
        'name': name,
      });

      _messageController.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Complaint sent successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending complaint: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Help & Support',
          style: GoogleFonts.montserratAlternates(
            textStyle: TextStyle(
              fontSize: 20,
              color: AppColors().white,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        backgroundColor: AppColors().orange,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Container(
        color: AppColors().orange,
        padding: const EdgeInsets.symmetric(horizontal: 16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'What Went Wrong?',
              style: TextStyle(
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.white),
            ),
            const SizedBox(height: 16.0),
            Container(
              height: 200.0,
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors().orangelight,
                borderRadius: BorderRadius.circular(15.0),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 6.0,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                maxLines: 7,
                minLines: 1,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 15.0, vertical: 10.0),
                  border: InputBorder.none,
                  hintText: 'You can write your problem here...',
                  hintStyle: TextStyle(color: AppColors().grey3, fontSize: 14),
                ),
                style: const TextStyle(color: Colors.black),
              ),
            ),
            const SizedBox(height: 16.0),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors().navy,
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8.0)),
              ),
              onPressed: _isLoading ? null : _submitMessage,
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      'Submit',
                      style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18.0),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
