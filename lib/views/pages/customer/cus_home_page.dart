import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/api/firebase_api.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/search_and_filter.dart';
import 'package:hire_harmony/views/pages/customer/view_all_popular_services.dart';
import 'package:hire_harmony/views/pages/location_page.dart';
import 'package:hire_harmony/views/widgets/customer/best_worker.dart';
import 'package:hire_harmony/views/widgets/customer/category_widget.dart';
import 'package:hire_harmony/views/widgets/customer/custom_carousel_indicator.dart';
import 'package:hire_harmony/views/widgets/customer/invite_link_dialog.dart';
import 'package:hire_harmony/views/widgets/customer/populer_service.dart';
import 'package:hire_harmony/views/widgets/customer/view_all_best_workers_page.dart';
import 'package:hire_harmony/views/widgets/customer/view_all_categories.dart';

class CusHomePage extends StatefulWidget {
  const CusHomePage({super.key});

  @override
  State<CusHomePage> createState() => _CusHomePageState();
}

class _CusHomePageState extends State<CusHomePage> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
  String _userName = "User";

  @override
  void initState() {
    super.initState();
    _checkUserLocation();
    /* updateCategoryWorkerCounts();*/
    _fetchUserName();
  }

  void _fetchUserName() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final userDoc = await FirebaseFirestore.instance
          .collection('users') // Change this to your Firestore collection name
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc.data()?['name'] ?? "User"; // Fetch name field
        });
      }
    }
  }

  Future<void> updateCategoryWorkerCounts() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    // استرجاع جميع الكاتيجوري
    QuerySnapshot categoriesSnapshot =
        await firestore.collection('categories').get();

    // خريطة لحفظ عدد العمال لكل كاتيجوري
    Map<String, int> categoryWorkerCount = {};

    // تحضير جميع الكاتيجوري من قاعدة البيانات
    for (var categoryDoc in categoriesSnapshot.docs) {
      String categoryId = categoryDoc.id;
      categoryWorkerCount[categoryId] = 0; // تعيين العدد مبدئيًا 0
    }

    // استرجاع جميع المستخدمين
    QuerySnapshot usersSnapshot = await firestore.collection('users').get();

    for (var userDoc in usersSnapshot.docs) {
      String userId = userDoc.id;

      // جلب كوليكشن `empcategories` لكل مستخدم
      QuerySnapshot empCategoriesSnapshot = await firestore
          .collection('users')
          .doc(userId)
          .collection('empcategories')
          .get();

      if (empCategoriesSnapshot.docs.isEmpty) {
        print("❌ المستخدم $userId ليس لديه أي كاتيجوري في empcategories");
      } else {
        print(
            "✅ المستخدم $userId لديه ${empCategoriesSnapshot.docs.length} كاتيجوري في empcategories");
      }

      for (var empCategoryDoc in empCategoriesSnapshot.docs) {
        Map<String, dynamic> categoryData =
            empCategoryDoc.data() as Map<String, dynamic>;

        if (!categoryData.containsKey('categories')) {
          print(
              "⚠️ تحذير: الوثيقة ${empCategoryDoc.id} في `empcategories` لا تحتوي على حقل 'categories'");
          continue;
        }

        List<dynamic> categoryNames = categoryData['categories'] ?? [];

        if (categoryNames.isEmpty) {
          print("⚠️ تحذير: قائمة الكاتيجوري فارغة للمستخدم $userId");
          continue;
        }

        // التكرار على كل الكاتيجوري التي ينتمي إليها العامل
        for (String categoryName in categoryNames) {
          categoryName = categoryName.trim(); // إزالة أي مسافات زائدة

          print("🔍 المستخدم $userId ينتمي إلى الكاتيجوري: $categoryName");

          // البحث عن كاتيجوري بهذا الاسم في القائمة
          for (var categoryDoc in categoriesSnapshot.docs) {
            Map<String, dynamic> categoryDocData =
                categoryDoc.data() as Map<String, dynamic>;

            String categoryDocName =
                categoryDocData['name']?.toString().trim() ?? '';

            if (categoryDocName == categoryName) {
              String categoryId = categoryDoc.id;
              categoryWorkerCount[categoryId] =
                  (categoryWorkerCount[categoryId] ?? 0) + 1;
              print(
                  "✅ تم إضافة المستخدم $userId إلى الكاتيجوري $categoryDocName (ID: $categoryId)");
            }
          }
        }
      }
    }

    // طباعة النتائج للتحقق من التعداد
    print("🔹 عدد العمال لكل كاتيجوري: $categoryWorkerCount");

    // تحديث كل كاتيجوري بعدد العمال المرتبطين بها
    for (var entry in categoryWorkerCount.entries) {
      await firestore.collection('categories').doc(entry.key).update({
        'empNum': entry.value,
      });
    }

    print("✅ تم تحديث أعداد العمال لكل كاتيجوري بنجاح!");
  }

  Future<void> _checkUserLocation() async {
    await Future.delayed(const Duration(seconds: 10)); // الانتظار لمدة 10 ثوانٍ

    // افترض أن لديك Firebase API تتحقق من الموقع
    final isLocationSaved = await FirebaseApi().isUserLocationSaved(userId!);
    debugPrint(isLocationSaved.toString());

    if (!isLocationSaved) {
      // تحويل المستخدم إلى صفحة الموقع باستخدام GetX
      await Get.to(() => const LocationPage());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      extendBody: true, // Allows content to extend behind the navigation bar
      appBar: AppBar(
        automaticallyImplyLeading: false,
        iconTheme: const IconThemeData(
          color: Colors.white, // Set the color of the menu icon
        ),
        backgroundColor: AppColors().orange,
        centerTitle: true,
        // actions: [
        //   IconButton(
        //     onPressed: () {
        //       Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (context) => const CusNotificationsPage(),
        //         ),
        //       );
        //     },
        //     icon: const Icon(Icons.notifications),
        //     color: AppColors().white,
        //   )
        // ],
        title: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Hi $_userName',
                      style: GoogleFonts.montserratAlternates(
                        fontSize: 20,
                        color: AppColors().white,
                      ),
                    ),
                    RichText(
                        text: TextSpan(
                      style: GoogleFonts.montserratAlternates(
                        fontSize: 16,
                        color: AppColors().navy, // Default color
                      ),
                    )),
                  ],
                ),
                Image.asset(
                  'lib/assets/images/logo_white_brown_shadow.PNG',
                  width: 50, // Bigger logo for better visibility
                  height: 50,
                ),
              ],
            ),
          ],
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.only(
            bottom: kBottomNavigationBarHeight), // Adds space for the navbar
        child: Column(children: [
          PreferredSize(
            preferredSize: const Size.fromHeight(100),
            child: Container(
              color: AppColors().orange,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 15),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const SearchAndFilter()),
                        );
                      },
                      child: AbsorbPointer(
                        // Prevents the `TextField` from handling taps
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Search for "Indoor Cleaning"',
                            hintStyle: GoogleFonts.montserratAlternates(
                              textStyle: TextStyle(
                                fontSize: 16,
                                color: AppColors().grey,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            border: InputBorder.none,
                            prefixIcon: Icon(
                              Icons.search,
                              color: AppColors().grey,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const Column(
            children: [
              CustomCarouselIndicator(),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 14),
            child: Column(
              children: [
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Browse all categories',
                      style: GoogleFonts.montserratAlternates(
                        textStyle: TextStyle(
                          fontSize: 15,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => const ViewAllCategoriesPage(),
                          ),
                        );
                      },
                      child: Text(
                        'View all >',
                        style: GoogleFonts.montserratAlternates(
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors().orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const CategoryWidget(),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Popular Categories on Hire Harmony',
                      style: GoogleFonts.montserratAlternates(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ViewAllPopularServicesPage(),
                          ),
                        );
                      },
                      child: Text(
                        'View all >',
                        style: GoogleFonts.montserratAlternates(
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors().orange,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const PopulerService(),
                const SizedBox(height: 24),
                Container(
                  width: 400,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors().orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Invite your friends!',
                        style: GoogleFonts.montserratAlternates(
                          textStyle: TextStyle(
                            fontSize: 15,
                            color: AppColors().white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Introduce your friends to the easiest way to find and hire professionals for your needs.',
                        style: GoogleFonts.montserratAlternates(
                          textStyle: TextStyle(
                            fontSize: 13,
                            color: AppColors().white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              Theme.of(context).colorScheme.surface,
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                        ),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) {
                              return const InviteLinkDialog(
                                link:
                                    "https://your-invite-link.com", // رابط الدعوة
                              );
                            },
                          );

                          // Add your button action here
                        },
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Copy link',
                              style: GoogleFonts.montserratAlternates(
                                textStyle: TextStyle(
                                  fontSize: 14,
                                  color: Theme.of(context).colorScheme.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Icon(
                              Icons.link_outlined,
                              size: 16,
                              color: AppColors().orange,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Best Worker Profile',
                      style: GoogleFonts.montserratAlternates(
                        textStyle: TextStyle(
                          fontSize: 14,
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const BestWorker(),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
