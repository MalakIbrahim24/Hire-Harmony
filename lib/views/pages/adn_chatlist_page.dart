import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/services/chat/chat_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/chatePage.dart';

class AdnChatlistPage extends StatefulWidget {
  const AdnChatlistPage({super.key});

  @override
  _AdnChatlistPageState createState() => _AdnChatlistPageState();
}

class _AdnChatlistPageState extends State<AdnChatlistPage> {
  final ChatServices _chatService = ChatServices();
  final AuthServices authService = AuthServicesImpl();

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors().transparent,
        centerTitle: true,
        title: Text(
          'Messages',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserratAlternates(
            fontSize: 22,
            color: AppColors().white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'lib/assets/images/notf.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
            child: Container(
              color: AppColors().navy.withValues(alpha: 0.3),
            ),
          ),
        ),
        _buildUserList(),
      ]),
    );
  }

  Widget _buildUserList() {
    String currentUserID = authService.getCurrentUser()!.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: _chatService.getUserChats(currentUserID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Center(child: Text('An error occurred.'));
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return ListView(
            children: snapshot.data!.docs.map((doc) {
              var chatData = doc.data() as Map<String, dynamic>;
              return _buildUserListItem(chatData, context);
            }).toList(),
          );
        }
        return Center(
          child: Text(
            'No conversations found.',
            style: GoogleFonts.montserratAlternates(
              fontSize: 18,
              color: AppColors().white,
              fontWeight: FontWeight.bold,
            ),
          ),
        );
      },
    );
  }

  Widget _buildUserListItem(
      Map<String, dynamic> chatData, BuildContext context) {
    String currentUserID = authService.getCurrentUser()!.uid;

    List<dynamic> participants = chatData['participants'];
    String otherUserID = participants.firstWhere(
      (id) => id != currentUserID,
      orElse: () => '',
    );

    if (otherUserID.isEmpty) {
      return const SizedBox.shrink();
    }

    return FutureBuilder<DocumentSnapshot>(
      future:
          FirebaseFirestore.instance.collection('users').doc(otherUserID).get(),
      builder: (context, snapshot) {
        if (!mounted) return const SizedBox.shrink();
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data == null || snapshot.data!.data() == null) {
          return const SizedBox.shrink();
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;

        return Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withValues(alpha: 0.2),
                blurRadius: 6,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            leading: CircleAvatar(
              radius: 30, // Larger avatar
              backgroundImage:
                  userData['img'] != null && userData['img'].isNotEmpty
                      ? NetworkImage(userData['img'])
                      : const NetworkImage(
                          'https://thumbs.dreamstime.com/b/default-avatar-profile-icon-vector-social-media-user-image-182145777.jpg',
                        ),
            ),
            title: Text(
              userData['name'] ?? 'Unknown User',
              style: GoogleFonts.montserratAlternates(
                fontSize: 14,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              chatData['lastMessage'] ?? 'No messages yet...',
              style: GoogleFonts.montserratAlternates(
                fontSize: 13,
                color: Colors.grey,
              ),
            ),
            trailing: Text(
              chatData['lastUpdated'] != null
                  ? _formatTimestamp(chatData['lastUpdated'])
                  : '',
              style: GoogleFonts.montserratAlternates(
                fontSize: 12,
                color: Colors.grey,
              ),
            ),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => Chatepage(
                    reciverEmail: userData['email'],
                    reciverID: otherUserID,
                    reciverName: userData['name'],
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp is Timestamp) {
      DateTime dateTime = timestamp.toDate();
      return "${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
    return '';
  }
}
