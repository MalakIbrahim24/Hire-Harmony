// ignore_for_file: file_names

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hire_harmony/component/chat_bubble.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/services/chat/chat_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:http/http.dart' as http;

class Chatepage extends StatelessWidget {
  final String reciverEmail;
  final String reciverID;
  final String? reciverName;
  final String? chatController;

  final ChatServices _chatServices = ChatServices();
  final AuthServices _authServices = AuthServicesImpl();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController =
      ScrollController(); // ScrollController

  Chatepage(
      {super.key,
      required this.reciverEmail,
      required this.reciverID,
      this.reciverName,
      this.chatController});
  Future<void> sendPushMessage(String token, String body, String title) async {
    try {
      await http.post(
        Uri.parse('https://fcm.googleapis.com/fcm/send'),
        headers: <String, String>{
          'Content-Type': 'application/json',
          'Authorization':
              'key=ya29.c.c0ASRK0GaQWp6XXbnZOy40icUjTyA7IkbEGKcfo5FfXGOiIepSKVR7NgGinRlJP5sJKlRjbV2gRKDZIrB0jXhPadg0yDkrp8IFXd2nayCMkIauPkjiXE0NHJs7J0etH3Lb1CY3WHD1WwROaQ8Oq0lgCkuVFVchRcgu4CnjqypEKR5hLCgTnzZDH8ZX23948_OXGxOPiRYYcx0QxEpIezVcqXua1w2v1h27xD5DGu0QJtwhi_SPvv2sZDsfMupCc6EvNXQXZge-rSPjAmv86EE3kMN2vd-sBxB3b646P6lo7o3u_3jAGnQVY6oM9uVLjAj9nY4kGCgEablRfK_jKUdb0knVlbvGVz2hLofPL_oB9DpCbwU-cwO3QS4OUmsE388AiZl1lqsyfuXX_UZWkY4FyjRYh-z-oin-eiOzug3QfuguQgaRisviz7F-aqBBWgyR0c99i70qic8RBFY_nkmRtBr_gWhsoRO5qwVaV3fxvg2ldn9XsOj6-eIx1Zywiw3BzelxkiZcut_YyQ6Bzv6SbMu7rzzoi5s6O5bhWbF5VYcuIkm45BnWOyWQcs3uYwMFjuunFIw90J731-p5vxogftv55-mqnQpfz8ugvhkwIVwBpQ6Be0B_dFcWlBdfZZ407MIo0SJMep_3OScMwX1_pV9pQwk6UwVR3QrYrWldokFl2m8WWIYXvW4uOeucZzfacm3sll8fhZvZVv54ROx-_dJvmhghQF6V_wwwUzFhwq9eunrvWQ4JlSSBe1Xyomlpb9BvI82BJko00gIcIt0evay_zhMd8gOVySWrU7peIj6eZ6BRz35aY2Y66zu8xxIis9BQZXZrhW-Mzs0m-oyRhRyrIYZMl2Mse59dzOVOssUqIa3kv44aj3IlSzYvyY164reUucUm-OsZdadS3rQupfh1u0dzByQp7X4suOwuVi5aQU57Rvw1vVx8zl-d0owbge52j2I7q_yYOF5rl6jyrh20VsZrY_vU2v9ZxoQ3M', // ضع مفتاح الخادم الخاص بك هنا
        },
        body: jsonEncode(<String, dynamic>{
          'priority': 'high',
          'data': <String, dynamic>{
            'click_action': 'FLUTTER_NOTIFICATION_CLICK',
            'status': 'done',
            'body': body,
            'title': title,
          },
          'notification': <String, dynamic>{
            'title': title,
            'body': body,
          },
          'to': token,
        }),
      );
      print("Notification sent successfully.");
    } catch (e) {
      print("Error sending push notification: $e");
    }
  }

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      // إرسال الرسالة
      await _chatServices.sendMessages(
        reciverID,
        _messageController.text,
      );

      // 2. الحصول على Token الخاص بالمستلم
      DocumentSnapshot snap = await FirebaseFirestore.instance
          .collection("UserTokens")
          .doc(reciverID) // استخدم ID المستلم
          .get();

      if (snap.exists) {
        final token = snap['token'];
        // 3. إرسال الإشعار
        await sendPushMessage(
          token,
          _messageController.text,
          "New message from ${_authServices.getCurrentUser()!.email}",
        );
      }

      _messageController.clear();
      _scrollToBottom(); // التمرير إلى الأسفل بعد إرسال الرسالة
    }
  }

  void _scrollToBottom() {
    // Scroll to bottom
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<String> _getChatControllerStatus(String chatRoomID) async {
    // Fetch the chat room's document
    final chatRoomDoc = await FirebaseFirestore.instance
        .collection('chat_rooms')
        .doc(chatRoomID)
        .get();

    if (chatRoomDoc.exists) {
      final data = chatRoomDoc.data() as Map<String, dynamic>;
      return data['chatController'] ?? 'closed'; // Default to 'closed'
    }

    throw Exception('Chat room does not exist.');
  }

  @override
  Widget build(BuildContext context) {
    final String currentUserID = _authServices.getCurrentUser()!.uid;

    // Generate chatRoomID in a consistent order
    final String chatRoomID = currentUserID.compareTo(reciverID) < 0
        ? '${currentUserID}_$reciverID'
        : '${reciverID}_$currentUserID';

    return FutureBuilder<String>(
      future: _getChatControllerStatus(chatRoomID),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            appBar: AppBar(title: const Text('Loading Chat...')),
            body: const Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasError) {
          return Scaffold(
            appBar: AppBar(title: const Text('Error')),
            body: Center(child: Text('Error loading chat: ${snapshot.error}')),
          );
        }

        // If the chatController is "open", show the chat interface
        if (snapshot.data == 'open') {
          return Scaffold(
            appBar: AppBar(
              title: Text(
                reciverName ?? 'Unknown',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Colors.grey,
              elevation: 0,
            ),
            body: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: NetworkImage(
                      "https://e0.pxfuel.com/wallpapers/722/149/desktop-wallpaper-message-background-whatsapp-message-background.jpg"),
                  fit: BoxFit.cover,
                ),
              ),
              child: Column(
                children: [
                  // Message list
                  Expanded(
                    child: _buildMessageList(),
                  ),
                  // User input
                  _buildUserInput(),
                ],
              ),
            ),
          );
        } else {
          // If the chatController is "closed", lock the page
          return Scaffold(
            appBar: AppBar(
              title: Text(
                reciverName ?? 'Unknown',
                style: TextStyle(color: Theme.of(context).colorScheme.primary),
              ),
              backgroundColor: Theme.of(context).colorScheme.surface,
              foregroundColor: Colors.grey,
              elevation: 0,
            ),
            body: const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock, size: 100, color: Colors.grey),
                  SizedBox(height: 20),
                  Text(
                    'This chat room is locked.',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'You cannot access this chat right now.',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                ],
              ),
            ),
          );
        }
      },
    );
  }

  Widget _buildMessageList() {
    final senderID = _authServices.getCurrentUser()!.uid;

    return StreamBuilder(
      stream: _chatServices.getMessage(senderID, reciverID),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return const Text("ERROR");
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Text("Loading ...");
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Text("No messages yet.");
        }

        WidgetsBinding.instance.addPostFrameCallback((_) {
          _scrollToBottom(); // Scroll to bottom after loading messages
        });

        return ListView(
          controller: _scrollController, // Bind ScrollController
          children:
              snapshot.data!.docs.map((doc) => _buildMessageItem(doc)).toList(),
        );
      },
    );
  }

  Widget _buildMessageItem(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isCurrentUser =
        data['senderID'] == _authServices.getCurrentUser()!.uid;
    var alignment =
        isCurrentUser ? Alignment.centerLeft : Alignment.centerRight;

    return Container(
        alignment: alignment,
        child: Column(
          mainAxisAlignment:
              isCurrentUser ? MainAxisAlignment.end : MainAxisAlignment.start,
          children: [
            ChatBubble(message: data["message"], isCurrentUser: isCurrentUser)
          ],
        ));
  }

  Widget _buildUserInput() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 15.0),
      color: Colors.grey[200],
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.attach_file, color: Colors.grey[600]),
            onPressed: () {},
          ),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 15.0),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(25.0),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(25),
                    blurRadius: 5.0,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: "Type a message",
                  border: InputBorder.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10.0),
          Container(
            decoration: BoxDecoration(
              color: AppColors().orange,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppColors().orange.withAlpha(100),
                  blurRadius: 6.0,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: IconButton(
              icon: Icon(Icons.send, color: AppColors().white),
              onPressed: () {
                sendMessage();
              },
            ),
          ),
        ],
      ),
    );
  }
}
