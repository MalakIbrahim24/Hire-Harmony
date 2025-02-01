import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:hire_harmony/services/admin_service.dart';
import 'package:hire_harmony/utils/app_colors.dart';

class FirestoreService {
  //singleton
  FirestoreService._();
  static final instance = FirestoreService._();

  FirebaseFirestore get firestore => FirebaseFirestore.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  FirestoreService._internal();
  // FirestoreService.dart

// Create (Add)
  Future<void> addData({
    required String collectionPath,
    required Map<String, dynamic> data,
  }) async {
    await firestore.collection(collectionPath).add(data);
  }

// Update (Edit)
  Future<void> updateData({
    required String documentPath,
    required Map<String, dynamic> data,
  }) async {
    await firestore.doc(documentPath).update(data);
  }

// Delete

  /*Future<void> deleteData({required String documentPath}) async {
    final reference = firestore.doc(documentPath);
    debugPrint('delete: $documentPath');
    await reference.delete();
  }*/
 /// 🗑 **حذف أي مستند مع جميع الـ subcollections الخاصة به**
  Future<void> deleteData({required String documentPath}) async {
    final DocumentReference docRef = firestore.doc(documentPath);
    debugPrint('🗑 Deleting: $documentPath');

    try {
      // 🔹 استخراج معرف المستخدم من المسار (إذا كان المستند داخل `users`)
      String userId = documentPath.split('/').last;

      // 🔹 التأكد أنه مستند مستخدم قبل حذف كل بياناته
      if (documentPath.startsWith('users/')) {
        await _deleteUserWithAllData(userId);
      } else {
        await docRef.delete();
        debugPrint("✅ Successfully deleted document: $documentPath");
      }
    } catch (e) {
      debugPrint("❌ Error deleting document: $e");
    }
  }

  /// 🗑 **حذف المستخدم مع جميع الـ subcollections الخاصة به**
  Future<void> _deleteUserWithAllData(String userId) async {
    final DocumentReference userDocRef = firestore.collection('users').doc(userId);

    try {
      // 🔹 قائمة جميع الـ subcollections المحتملة للمستخدم
      List<String> subcollectionNames = [
        'serviceImages',
        'reviews',
        'orders',
        'items',
        'empcategories',
        'completedOrders',
        'bookingHistory',
        'advertisements'
      ];

      // 🔹 حذف جميع المستندات داخل كل subcollection إذا كان موجودًا
      for (var subcollection in subcollectionNames) {
        var subDocs = await userDocRef.collection(subcollection).get();
        if (subDocs.docs.isNotEmpty) {
          for (var doc in subDocs.docs) {
            await doc.reference.delete();
            debugPrint("🗑 Deleted document: ${doc.id} from subcollection: $subcollection");
          }
          debugPrint("✅ Deleted subcollection: $subcollection for user: $userId");
        }
      }

      // 🔹 حذف المستخدم نفسه بعد حذف كل البيانات الخاصة به
      await userDocRef.delete();
      debugPrint("✅ Successfully deleted user and all subcollections: users/$userId");

    } catch (e) {
      debugPrint("❌ Error deleting user with subcollections: $e");
    }
  }

  Future<void> deleteDataa({
    required String documentPath,
    required String serviceName,
    required String employeeId,
    required String employeeName,
  }) async {
    try {
      // Delete the service document
      await FirebaseFirestore.instance.doc(documentPath).delete();

      // Log deletion
      await AdminService.instance.logDeletedService(
        adminId: FirebaseAuth.instance.currentUser!.uid, // Admin UID
        serviceName: serviceName,
        employeeName: employeeName, // Employee's name for reference
      );

      debugPrint("Service deleted and logged successfully.");
    } catch (e) {
      debugPrint("Failed to delete and log service: $e");
    }
  }

// Read (Get All)
  Stream<List<T>> getDataStream<T>({
    required String collectionPath,
    required T Function(Map<String, dynamic> data, String documentId) builder,
  }) {
    return firestore.collection(collectionPath).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) => builder(doc.data(), doc.id)).toList();
    });
  }

  //add and update data
  Future<void> setData({
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final reference = firestore.doc(path);
    debugPrint('$path: $data');
    await reference.set(data);
  }

  Future<String> getUserRoleByUid(String uid) async {
    try {
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        String role = userDoc['role'] ?? "unknown";
        debugPrint("Role found: $role");
        return role;
      } else {
        debugPrint("No document found for UID: $uid");
        return "unknown";
      }
    } catch (e) {
      print("Error fetching user role: $e");
      return "unknown"; // Handle any issues by returning an "unknown" role
    }
  }

  Stream<List<T>> collectionStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String documentId) builder,
    //filtering the list coming back from the stream
    Query Function(Query query)? queryBuilder,
    //sorting the  list coming back from the stream
    int Function(T lhs, T rhs)? sort,
  }) {
    Query query = firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = query.snapshots();
    return snapshots.map((snapshot) {
      final result = snapshot.docs
          .map((snapshot) =>
              builder((snapshot.data() as Map<String, dynamic>), snapshot.id))
          .where((value) => value != null)
          .toList();

      if (sort != null) {
        result.sort(sort);
      }
      return result;
    });
  }

  Stream<T> documentStream<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String path) builder,
  }) {
    final reference = firestore.doc(path);
    final snapshots = reference.snapshots();
    return snapshots.map((snapshot) =>
        builder(snapshot.data() as Map<String, dynamic>, snapshot.id));
  }

// one time request for the document
  Future<T> getDocument<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String path) builder,
  }) async {
    final reference = firestore.doc(path);
    final snapshot = await reference.get();
    return builder(snapshot.data() as Map<String, dynamic>, snapshot.id);
  }

// one time request for a list of documents
  Future<List<T>> getCollection<T>({
    required String path,
    required T Function(Map<String, dynamic> data, String path) builder,
    Query Function(Query query)? queryBuilder,
    int Function(T lhs, T rhs)? sort,
  }) async {
    Query query = firestore.collection(path);
    if (queryBuilder != null) {
      query = queryBuilder(query);
    }
    final snapshots = await query.get();
    final result = snapshots.docs
        .map((snapshot) =>
            builder(snapshot.data() as Map<String, dynamic>, snapshot.id))
        .where((value) => value != null)
        .toList();
    if (sort != null) {
      result.sort(sort);
    }
    return result;
  }

  Future<void> logActivity({
    required String uid,
    required String action,
    required String device,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(uid)
          .collection('activityLogs')
          .add({
        'action': action,
        'timestamp': Timestamp.now(),
        'device': device,
      });
    } catch (e) {
      print("Error logging activity: $e");
    }
  }

  Stream<List<Map<String, dynamic>>> getCategories({int limit = 10}) {
    return firestore
        .collection('categories')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      debugPrint("Documents fetched: ${snapshot.docs.length}");
      return snapshot.docs.map((doc) {
        final data = doc.data();
        debugPrint("Document ID: ${doc.id}, Data: $data");
        return {
          'id': doc.id,
          'data': doc.data(),
        };
      }).toList();
    });
  }

  Stream<List<Map<String, dynamic>>> getPopularServices({int limit = 10}) {
    return FirebaseFirestore.instance
        .collection('popularservices')
        .limit(limit)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'data': doc.data(),
        };
      }).toList();
    });
  }

  // // Log Added Service
  // Future<void> logAddedService(String serviceName) async {
  //   try {
  //     await _firestore.collection('added_services').add({
  //       'service_name': serviceName,
  //       'added_at': DateTime.now().toIso8601String(),
  //     });
  //     debugPrint("Logged added service: $serviceName");
  //   } catch (e) {
  //     debugPrint("Failed to log added service: $e");
  //   }
  // }

  // // Log Deleted Service
  // Future<void> logDeletedService(String serviceName) async {
  //   try {
  //     await _firestore.collection('deleted_services').add({
  //       'service_name': serviceName,
  //       'deleted_at': DateTime.now().toIso8601String(),
  //     });
  //     debugPrint("Logged deleted service: $serviceName");
  //   } catch (e) {
  //     debugPrint("Failed to log deleted service: $e");
  //   }
  // }

  // // Method to get activity logs
  // Stream<List<Map<String, dynamic>>> getActivityLogs(String uid) {
  //   return _firestore
  //       .collection('users')
  //       .doc(uid)
  //       .collection('activityLogs')
  //       .orderBy('timestamp', descending: true)
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  // }

  // Stream<List<Map<String, dynamic>>> getDeletedAccounts(String uid) {
  //   return FirebaseFirestore.instance
  //       .collection('users') // Main 'users' collection
  //       .doc(uid) // Specific user document
  //       .collection('deletedAccounts') // Subcollection 'deletedAccounts'
  //       .snapshots()
  //       .map((snapshot) => snapshot.docs.map((doc) {
  //             final data = doc.data();
  //             return {
  //               'id': doc.id,
  //               'name':
  //                   data['name'] ?? 'Unnamed User', // Default to 'Unnamed User'
  //               'email': data['email'] ?? 'No Email', // Default to 'No Email'
  //             };
  //           }).toList());
  // }

  // Future<String> getDeviceInfo() async {
  //   final deviceInfo = DeviceInfoPlugin();
  //   if (Platform.isAndroid) {
  //     final androidInfo = await deviceInfo.androidInfo;
  //     return 'Android - ${androidInfo.model}';
  //   } else if (Platform.isIOS) {
  //     final iosInfo = await deviceInfo.iosInfo;
  //     return 'iOS - ${iosInfo.utsname.machine}';
  //   } else {
  //     return 'Unknown Device';
  //   }
  // }

  Future<bool> reauthenticateUser(String currentPassword) async {
    User? user = _auth.currentUser;

    if (user != null && user.email != null) {
      AuthCredential credential = EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      try {
        await user.reauthenticateWithCredential(credential);
        return true;
      } catch (e) {
        debugPrint("Re-authentication failed: $e");
        Fluttertoast.showToast(
          msg: "Incorrect current password",
          textColor: AppColors().white,
          backgroundColor: AppColors().red,
        );
        return false;
      }
    }
    return false;
  }

  Future<void> updatePassword(String newPassword) async {
    User? user = _auth.currentUser;

    if (user != null) {
      try {
        await user.updatePassword(newPassword);
        String newPasswordHash = hashPassword(newPassword);

        await _firestore.collection('users').doc(user.uid).update({
          'lastPasswordChange': Timestamp.now(),
          'passwordHash': newPasswordHash,
        });

        Fluttertoast.showToast(
          msg: "Password updated successfully",
          textColor: AppColors().white,
          backgroundColor: AppColors().orange,
        );
      } catch (e) {
        Fluttertoast.showToast(
          msg: "Error updating password: $e",
          textColor: AppColors().white,
          backgroundColor: AppColors().red,
        );
      }
    }
  }

  String hashPassword(String password) {
    final bytes = utf8.encode(password);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  Future<bool> isSameAsCurrentPassword(String newPassword) async {
    User? user = _auth.currentUser;

    if (user != null && user.email != null) {
      try {
        // Get the current password hash
        String currentPasswordHash = hashPassword(newPassword);

        // Fetch the user's document from Firestore
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();

        // Check if the current hashed password matches the new password hash
        if (userDoc.exists && userDoc['passwordHash'] == currentPasswordHash) {
          return true;
        }
      } catch (e) {
        debugPrint("Error checking current password: $e");
      }
    }
    return false;
  }

  // Method to get and update notification settings
  // Future<Map<String, dynamic>> getNotificationSettings(String uid) async {
  //   DocumentSnapshot doc = await _firestore.collection('users').doc(uid).get();
  //   return doc.data()?['notifications'] ?? {};
  // }

  // Future<void> updateNotificationSettings(
  //     String uid, Map<String, dynamic> settings) async {
  //   await _firestore
  //       .collection('users')
  //       .doc(uid)
  //       .update({'notifications': settings});
  // }


Future<Map<String, dynamic>?> getUserData(String userId) async {
  try {
    DocumentSnapshot userDoc = await FirebaseFirestore.instance.collection('users').doc(userId).get();

    if (userDoc.exists) {
      return userDoc.data() as Map<String, dynamic>;
    } else {
      print("No user found with this ID");
      return null;
    }
  } catch (e) {
    print("Error fetching user data: $e");
    return null;
  }
}

}
