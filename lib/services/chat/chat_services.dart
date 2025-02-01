import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hire_harmony/models/message.dart';
import 'package:hire_harmony/models/message_model.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/utils/route/api_paths.dart';

class ChatServices {
  final _firestoreServices = FirestoreService.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  //stream getMessages
  Stream<List<MessageModel>> getMessages() {
    //try and catch
    try {
      //get messages from firestore
      return _firestoreServices.collectionStream(
        path: ApiPaths.messages(),
        builder: (data, documentId) => MessageModel.fromMap(data),
      );
    } catch (e) {
      print('Error fetching messages: $e');

      rethrow;
    }
  }

//للشات الجماعية استخدمنا المسج موديل
  Future<void> sendMessage(MessageModel message) async {
    try {
      await _firestoreServices.setData(
        path: ApiPaths.sendMessage(message.id),
        data: message.toMap(),
      );
    } catch (e) {
      print('Error sending message: $e');

      rethrow;
    }
  }

  Future<void> sendMessages(String reciverid, message) async {
    final String currentUserID = _auth.currentUser!.uid;
    final String currentUserEmail = _auth.currentUser!.email!;
    final Timestamp timestamp = Timestamp.now();

    Message newMessage = Message(
        senderID: currentUserID,
        senderEmail: currentUserEmail,
        message: message,
        reciverID: reciverid,
        timestamp: timestamp
        );

    List<String> ids = [currentUserID, reciverid];
    ids.sort();
    String chatRoomID =
        getChatRoomID(newMessage.senderID, newMessage.reciverID);
    await _firestore.collection("chat_rooms").doc(chatRoomID).set({
      'participants': ids,
      'lastMessage': newMessage.message,
      'lastUpdated': timestamp,
    }, SetOptions(merge: true)); // هذا يدمج الحقول الجديدة مع الحقول الحالية

//add new message to database
    await _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .add(newMessage.toMap());
  }

  //لتوليد شات اي د\ي
  String getChatRoomID(String senderID, String receiverID) {
    List<String> ids = [senderID, receiverID];
    ids.sort(); // ترتيب المعرفات لضمان التناسق
    return ids.join('_'); // دمج المعرفين بفاصل "_"
  }

  Stream<QuerySnapshot> getMessage(String userID, otherUserID) {
    List<String> ids = [userID, otherUserID];
    ids.sort();
    String chatRoomID = getChatRoomID(userID, otherUserID); // إنشاء معرف الغرفة
    print('Generated chatRoomID: $chatRoomID');

    return _firestore
        .collection("chat_rooms")
        .doc(chatRoomID)
        .collection("messages")
        .orderBy('timestamp', descending: false)
        .snapshots();
  }

  //get instance of firestore
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  //get user stream
  Stream<List<Map<String, dynamic>>> getUserStream() {
    return _firestore.collection('users').snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final user = doc.data();
        return user;
      }).toList();
    });
  }

  Stream<QuerySnapshot> getUserChats(String currentUserID) {
    return FirebaseFirestore.instance
        .collection('chat_rooms')
        .where('participants', arrayContains: currentUserID)
        .snapshots();
  }
}
