import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';

class EmpAccountDeletionScreen extends StatelessWidget {
  const EmpAccountDeletionScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Theme.of(context).colorScheme.primary),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          title: Text(
            'Account Deletion',
            style: GoogleFonts.montserratAlternates(
              textStyle: TextStyle(
                fontSize: 18,
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          centerTitle: true,
        ),
        body: const AccountDeletionBody(),
      ),
    );
  }
}

class AccountDeletionBody extends StatefulWidget {
  const AccountDeletionBody({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _AccountDeletionBodyState createState() => _AccountDeletionBodyState();
}

class _AccountDeletionBodyState extends State<AccountDeletionBody> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String? selectedReason;
  String? userImage;

  @override
  void initState() {
    super.initState();
    _fetchUserImage();
  }
   Future<void> getUserCategories(String userID) async {
    try {
      FirebaseFirestore firestore = FirebaseFirestore.instance;

      // 🔹 البحث عن وثيقة `empcategories` داخل `users` لهذا المستخدم
      QuerySnapshot empCategoriesSnapshot = await firestore
          .collection('users')
          .doc(userID)
          .collection('empcategories')
          .get();

      if (empCategoriesSnapshot.docs.isEmpty) {
        print("⚠️ لا توجد كاتيجوري للمستخدم $userID");
      }

      // 🔹 استخراج جميع الكاتيجوريز من كل المستندات
      List<String> allCategories = [];

      for (var doc in empCategoriesSnapshot.docs) {
        List<dynamic> categories = doc['categories'] ?? [];
        allCategories.addAll(categories.cast<String>());
      }

      print("✅ الكاتيجوري الخاصة بالمستخدم $userID: $allCategories");
      List<String> userCategories = allCategories;
      decrementEmpNumForCategories(userCategories, userID);
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
    DocumentSnapshot categoryDoc =
        await firestore.collection('categories').doc(categoryId).get();

    if (!categoryDoc.exists) {
      print("⚠️ الوثيقة الخاصة بـ '$categoryName' غير موجودة.");
      continue;
    }

    Map<String, dynamic> categoryData =
        categoryDoc.data() as Map<String, dynamic>;

    // 🔹 الحصول على العدد الحالي للعمال
    int currentEmpNum = (categoryData['empNum'] ?? 0) as int;

    // 🔹 التحقق من أن العدد لن يصبح سالبًا بعد الحذف
    int updatedEmpNum = (currentEmpNum > 0) ? currentEmpNum - 1 : 0;

    // 🔹 تحديث `workers` وإزالة `employeeId` باستخدام `FieldValue.arrayRemove()`
    await firestore.collection('categories').doc(categoryId).update({
      'empNum': updatedEmpNum, // ✅ تحديث عدد العمال
      'workers': FieldValue.arrayRemove([employeeId]), // ✅ إزالة الموظف من القائمة
    });

    print("✅ تم تحديث `empNum` إلى $updatedEmpNum وإزالة $employeeId من `workers` في '$categoryName'.");
  }
}

  Future<void> _fetchUserImage() async {
    final User? user = _auth.currentUser;
    if (user == null) return;

    try {
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        setState(() {
          userImage = doc['img'] ??
              'https://via.placeholder.com/150'; // Fallback to placeholder image
        });
      }
    } catch (e) {
      debugPrint('Error fetching user image: $e');
    }
  }

  void _showConfirmationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor:Theme.of(context).colorScheme.surface,
          shadowColor: Theme.of(context).colorScheme.tertiary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 30,
                backgroundImage: userImage != null && userImage!.isNotEmpty
                    ? NetworkImage(userImage!) as ImageProvider
                    : const AssetImage('lib/assets/images/employee.png'),
              ),
              const SizedBox(height: 10),
              Text(
                'Delete Your Account?',
                style: GoogleFonts.montserratAlternates(
                  textStyle: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'This will completely erase all your data. You won’t be able to recover your account once it has been deleted.',
                textAlign: TextAlign.center,
                style: GoogleFonts.montserratAlternates(
                  textStyle: TextStyle(
                    fontSize: 14,
                    color: Theme.of(context).colorScheme.tertiary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().orangelight,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: () {
                  Navigator.of(context).pop();
                  _showFinalConfirmationDialog(context);
                },
                child: Text(
                  'Confirm & Delete',
                  style: GoogleFonts.montserratAlternates(
                    textStyle: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.secondary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: Text(
                  'Cancel & Keep',
                  style: GoogleFonts.montserratAlternates(
                    textStyle: TextStyle(
                      fontSize: 15,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFinalConfirmationDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return AlertDialog(
        backgroundColor: AppColors().white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        title: Text(
          'Are you absolutely sure?',
          style: GoogleFonts.montserratAlternates(
            textStyle: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors().navy,
            ),
          ),
        ),
        content: Text(
          'This is your last chance to cancel.',
          style: GoogleFonts.montserratAlternates(
            textStyle: TextStyle(
              fontSize: 14,
              color: AppColors().grey,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(
              'Cancel',
              style: GoogleFonts.montserratAlternates(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors().navy,
                ),
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              final User? user = FirebaseAuth.instance.currentUser;
           

              if (user != null) {
                await _deleteAccount(context, user.uid);
          
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors().orange,
            ),
            child: Text(
              'Delete Account',
              style: GoogleFonts.montserratAlternates(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors().white,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}


  Future<String?> _getPasswordFromUser(BuildContext context) async {
    String? password;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Re-enter Password'),
          content: TextField(
            obscureText: true,
            decoration: const InputDecoration(labelText: 'Password'),
            onChanged: (value) {
              password = value;
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Confirm'),
            ),
          ],
        );
      },
    );
    return password;
  }
  
Future<void> _deleteAccount(BuildContext context, String userId) async {
  try {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user != null) {
        final password = await _getPasswordFromUser(context);
        if (password == null || password.isEmpty) {
          _showErrorDialog(
              // ignore: use_build_context_synchronously
              context,
              'Password is required to delete your account.');
          return;
        }

        // Re-authenticate the user
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: password,
        );
        await user?.reauthenticateWithCredential(credential);

    }

  await  getUserCategories(user!.uid);

    
    // 🔹 حذف بيانات المستخدم من Firestore
    await FirestoreService.instance.deleteData(documentPath: 'users/$userId');

    // 🔹 حذف الحساب من Firebase Authentication
    
    if (user != null) {
      await user.delete();
    }

    // 🔹 توجيه المستخدم إلى صفحة تسجيل الدخول
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(
      context,
      AppRoutes.loginPage,
      (Route<dynamic> route) => route.settings.name == AppRoutes.welcomePage,
    );

    debugPrint('✅ الحساب تم حذفه بنجاح');
  } catch (e) {
    debugPrint('❌ خطأ أثناء حذف الحساب: $e');
    _showErrorDialog(context, 'فشل حذف الحساب، حاول مرة أخرى.');
  }
}




  void _showErrorDialog(BuildContext context, String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  void _handleDeleteAccount(BuildContext context) {
    if (selectedReason == null) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('No Reason Selected'),
            content:
                const Text('Please select a reason for deleting your account.'),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                },
                child: const Text('OK'),
              ),
            ],
          );
        },
      );
    } else {
      _showConfirmationDialog(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const SizedBox(height: 20),
        CircleAvatar(
          radius: 50,
          backgroundImage: NetworkImage(
            userImage ?? 'https://via.placeholder.com/150',
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text(
            'If you want to delete your account and you’re sure, choose a reason.',
            textAlign: TextAlign.center,
            style: GoogleFonts.montserratAlternates(
              textStyle: TextStyle(
                fontSize: 16,
                color: AppColors().grey,
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        // Reasons for deletion
        _buildReasonsCard(),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors().orange,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () {
              _handleDeleteAccount(context);
            },
            child: Text(
              'Delete Account',
              style: GoogleFonts.montserratAlternates(
                textStyle: TextStyle(
                  fontSize: 18,
                  color: AppColors().white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _buildReasonsCard() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Card(
        color: AppColors().white,
        shadowColor: AppColors().grey,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Column(
          children: [
            _buildReasonTile('No longer need the platform'),
            const Divider(),
            _buildReasonTile('Privacy concerns'),
            const Divider(),
            _buildReasonTile('Personal reasons'),
            const Divider(),
            _buildReasonTile('Other'),
          ],
        ),
      ),
    );
  }

  Widget _buildReasonTile(String reason) {
    return RadioListTile<String>(
      value: reason,
      groupValue: selectedReason,
      title: Text(
        reason,
        style: GoogleFonts.montserratAlternates(
          textStyle: TextStyle(
            fontSize: 16,
            color: AppColors().navy,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      onChanged: (value) {
        setState(() {
          selectedReason = value;
        });
      },
    );
  }
}
