import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/services/chat/chat_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/chatePage.dart';

class ChatListPage extends StatefulWidget {
  const ChatListPage({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _ChatListPageState createState() => _ChatListPageState();
}

class _ChatListPageState extends State<ChatListPage> {
  final ChatServices _chatService = ChatServices();
  final AuthServices authService = AuthServicesImpl();

  @override
  void dispose() {
    // Cancel or clean up any ongoing operations, if necessary
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Theme.of(context).colorScheme.surface,

        centerTitle: true,
        title: Text(
          'Messages',
          textAlign: TextAlign.center,
          style: GoogleFonts.montserratAlternates(
            color: AppColors().navy,
            fontSize: 20,
          ),
        ),
      ),
      body: _buildUserList(),
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
        return const Center(child: Text('No conversations found.'));
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
          return const SizedBox
              .shrink(); // Handle gracefully when there's no data
        }

        var userData = snapshot.data!.data() as Map<String, dynamic>;

        return ListTile(
          leading: CircleAvatar(
            backgroundImage:
                userData['img'] != null && userData['img'].isNotEmpty
                    ? NetworkImage(userData['img'])
                    : const NetworkImage(
                        'https://thumbs.dreamstime.com/b/default-avatar-profile-icon-vector-social-media-user-image-182145777.jpg',
                      ),
          ),
          title: Text(
            userData['name'] ?? 'Unknown User',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          subtitle: Text(
            chatData['lastMessage'] ?? 'No messages yet...',
            style: const TextStyle(color: Colors.grey),
          ),
          trailing: Text(
            chatData['lastUpdated'] != null
                ? _formatTimestamp(chatData['lastUpdated'])
                : '',
            style: const TextStyle(color: Colors.grey, fontSize: 12),
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chatepage(
                  reciverEmail: userData['email'],
                  reciverID: otherUserID,
                  reciverName:userData['name']
                ),
              ),
            );
          },
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
