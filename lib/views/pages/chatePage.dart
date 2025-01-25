// ignore_for_file: file_names

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hire_harmony/component/chat_bubble.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/services/chat/chat_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
class Chatepage extends StatelessWidget {
  final String reciverEmail;
  final String reciverID;
    final String? reciverName;


  final ChatServices _chatServices = ChatServices();
  final AuthServices _authServices = AuthServicesImpl();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController(); // ScrollController

  Chatepage({super.key, required this.reciverEmail, required this.reciverID ,  this.reciverName});

  void sendMessage() async {
    if (_messageController.text.isNotEmpty) {
      // إرسال الرسالة
      await _chatServices.sendMessages(
        reciverID,
        _messageController.text,
      );
      _messageController.clear();
      _scrollToBottom(); // التمرير إلى الأسفل بعد إرسال الرسالة
    }
  }

  void _scrollToBottom() {
    // التمرير إلى الأسفل
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          reciverName?? 'unkown',
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
            // عرض الرسائل
            Expanded(
              child: _buildMessageList(),
            ),
            // إدخال المستخدم
            _buildUserInput(),
          ],
        ),
      ),
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
          _scrollToBottom(); // التمرير إلى الأسفل بعد تحميل الرسائل
        });

        return ListView(
          controller: _scrollController, // ربط ScrollController
          children: snapshot.data!.docs
              .map((doc) => _buildMessageitem(doc))
              .toList(),
        );
      },
    );
  }

  Widget _buildMessageitem(DocumentSnapshot doc) {
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
                    color: Colors.black.withValues(alpha: 0.1),
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
                  color: AppColors().orange.withValues(alpha: 0.4),
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
