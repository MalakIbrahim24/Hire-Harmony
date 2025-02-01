import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  String searchQuery = '';
  
  Future<void> getUserCategories(String? userID) async {
  try {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // 🔹 التأكد من أن `userID` ليس فارغًا
    if (userID == null || userID.isEmpty) {
      print("❌ خطأ: userID فارغ أو غير صالح.");
      return;
    }

    // 🔹 البحث عن وثيقة `empcategories` داخل `users` لهذا المستخدم
    QuerySnapshot empCategoriesSnapshot = await firestore
        .collection('users')
        .doc(userID)
        .collection('empcategories')
        .get();

    if (empCategoriesSnapshot.docs.isEmpty) {
      print("⚠️ لا توجد كاتيجوري للمستخدم $userID");
      return;
    }

    // 🔹 استخراج جميع الكاتيجوريز من كل المستندات
    List<String> allCategories = [];

    for (var doc in empCategoriesSnapshot.docs) {
      List<dynamic> categories = doc['categories'] ?? [];
      allCategories.addAll(categories.cast<String>());
    }

    print("✅ الكاتيجوري الخاصة بالمستخدم $userID: $allCategories");

    // 🔹 استدعاء `decrementEmpNumForCategories` لتحديث العدد وحذف المستخدم
    await decrementEmpNumForCategories(allCategories, userID);
  } catch (e) {
    print("❌ خطأ أثناء جلب الكاتيجوري للمستخدم $userID: $e");
  }
}

 Future<void> decrementEmpNumForCategories(List<String> categories, String employeeId) async {
  FirebaseFirestore firestore = FirebaseFirestore.instance;

  for (String categoryName in categories) {
    categoryName = categoryName.trim(); // 🔹 إزالة المسافات الإضافية

    // 🔹 البحث عن الكاتيجوري في `categories`
    QuerySnapshot categorySnapshot = await firestore
        .collection('categories')
        .where('name', isEqualTo: categoryName)
        .get();

    if (categorySnapshot.docs.isEmpty) {
      print("⚠️ الكاتيجوري '$categoryName' غير موجودة في Firestore.");
      continue; // ⏭ تخطي هذه الكاتيجوري
    }

    // 🔹 استخراج `ID` الخاص بالكاتيجوري
    String categoryId = categorySnapshot.docs.first.id;

    // 🔹 جلب بيانات الكاتيجوري
    DocumentSnapshot categoryDoc = await firestore.collection('categories').doc(categoryId).get();

    if (!categoryDoc.exists) {
      print("⚠️ الوثيقة الخاصة بـ '$categoryName' غير موجودة.");
      continue;
    }

    Map<String, dynamic> categoryData = categoryDoc.data() as Map<String, dynamic>;

    // 🔹 الحصول على العدد الحالي للعمال
    int currentEmpNum = (categoryData['empNum'] ?? 0) as int;

    // 🔹 جلب قائمة العمال الحالية أو إنشاء قائمة جديدة
    List<String> currentWorkers = (categoryData['workers'] as List<dynamic>? ?? [])
        .map((e) => e.toString())
        .toList();

    // 🔹 التحقق من أن `employeeId` موجود بالفعل قبل إزالته
    if (currentWorkers.contains(employeeId)) {
      currentWorkers.remove(employeeId);
    }

    // 🔹 التأكد من أن العدد لن يصبح سالبًا بعد الحذف
    int updatedEmpNum = (currentEmpNum > 0) ? currentEmpNum - 1 : 0;

    // 🔹 تحديث `empNum` وإزالة `employeeId` باستخدام `FieldValue.arrayRemove()`
    await firestore.collection('categories').doc(categoryId).update({
      'empNum': updatedEmpNum, // ✅ تحديث عدد العمال
      'workers': FieldValue.arrayRemove([employeeId]), // ✅ إزالة الموظف من القائمة
    });

    print("✅ تم تحديث `empNum` إلى $updatedEmpNum وإزالة $employeeId من `workers` في '$categoryName'.");
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: AppColors().transparent,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        leading: Padding(
          padding: const EdgeInsets.all(5.0),
          child: IconButton(
            icon: Icon(
              Icons.arrow_back,
              size: 30,
              color: AppColors().white,
            ),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ),
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'lib/assets/images/accControl.jpeg',
            fit: BoxFit.cover,
          ),
        ),
        // Blur Filter
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 17.0, sigmaY: 17.0),
            child: Container(
              color: AppColors().navy.withValues(alpha: 0.3),
            ),
          ),
        ),
        SafeArea(
          child: Column(
            children: [
              Text(
                'Accounts Management',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserratAlternates(
                  fontSize: 24,
                  color: AppColors().white,
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  decoration: InputDecoration(
                    labelText: 'Search Users',
                    labelStyle: GoogleFonts.montserratAlternates(
                      color: AppColors().white,
                    ),
                    prefixIcon: Icon(Icons.search, color: AppColors().white),

                    // Default border
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors().navy.withValues(
                            alpha: 0.5), // Navy border when not focused
                      ),
                    ),

                    // Focused border
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors().navy, // Navy border when focused
                        width: 2, // Thicker border for emphasis
                      ),
                    ),

                    // Error border (optional)
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors().red, // Red border when error occurs
                      ),
                    ),

                    // Focused error border (optional)
                    focusedErrorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(
                        color: AppColors()
                            .red, // Red border when focused with error
                      ),
                    ),
                  ),
                  onChanged: (value) {
                    setState(() {
                      searchQuery = value.toLowerCase();
                    });
                  },
                ),
              ),
              Expanded(
                child: StreamBuilder<List<Map<String, dynamic>>>(
                  stream: FirestoreService.instance.collectionStream(
                    path: 'users',
                    builder: (data, documentId) => {
                      'id': documentId,
                      'name': data['name']?.toString() ?? 'Unnamed',
                      'email': data['email']?.toString() ?? 'No email',
                    },
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: GoogleFonts.montserratAlternates(
                            color: AppColors().navy,
                          ),
                        ),
                      );
                    }
                    if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return Center(
                        child: Text(
                          'No users found',
                          style: GoogleFonts.montserratAlternates(
                            color: AppColors().navy,
                          ),
                        ),
                      );
                    }

                    final users = snapshot.data!
                        .where((user) => user['name']
                            .toString()
                            .toLowerCase()
                            .contains(searchQuery))
                        .toList();

                    return ListView.builder(
                      itemCount: users.length,
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final userid = user['uid']?.toString() ?? '';

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                              color: AppColors().navy.withValues(alpha: 0.2),
                              width: 1,
                            ),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: ListTile(
                            title: Text(
                              user['name'],
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: AppColors().navy,
                              ),
                            ),
                            subtitle: Text(
                              user['email'],
                              style: GoogleFonts.montserratAlternates(
                                fontSize: 14,
                                color: AppColors().navy,
                              ),
                            ),
                            trailing: IconButton(
                              icon:
                                  Icon(Icons.delete, color: AppColors().orange),
                              onPressed: () async {
                                // First Confirmation Dialog
                                final confirm1 = await _showConfirmationDialog(
                                  context,
                                  title: 'Delete User',
                                  content:
                                      'Are you sure you want to delete this user?',
                                );

                                if (confirm1 == true) {
                                  // Second Confirmation Dialog
                                  final confirm2 =
                                      await _showConfirmationDialog(
                                    // ignore: use_build_context_synchronously
                                    context,
                                    title: 'Final Confirmation',
                                    content:
                                        'This action cannot be undone. Delete this user?',
                                  );

                                  // Update delete logic in UserManagementPage
                                  if (confirm2 == true) {
                                    final deletionTime = DateTime.now();

                                    await getUserCategories(user['id']);
                                    // Capture the deletion timestamp

                                    // Add deleted user to Firestore "deleted_users" collection
                                    await FirestoreService.instance.addData(
                                      collectionPath: 'deleted_users',
                                      data: {
                                        'name': user['name'],
                                        'email': user['email'],
                                        'deleted_at':
                                            deletionTime.toIso8601String(),
                                      },
                                    );

                                    // Delete the user from "users" collection
                                    await FirestoreService.instance.deleteData(
                                      documentPath: 'users/${user['id']}',
                                    );

                                    // Show success toast notification
                                    Fluttertoast.showToast(
                                      msg: "User deleted successfully",
                                      textColor: AppColors().white,
                                      backgroundColor: AppColors()
                                          .orange
                                          .withValues(alpha: 0.8),
                                    );
                                  }
                                }
                              },
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }

  Future<bool?> _showConfirmationDialog(
    BuildContext context, {
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          title,
          style: GoogleFonts.montserratAlternates(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          content,
          style: GoogleFonts.montserratAlternates(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              'Cancel',
              style: GoogleFonts.montserratAlternates(
                color: AppColors().navy,
              ),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: GoogleFonts.montserratAlternates(
                color: AppColors().red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
