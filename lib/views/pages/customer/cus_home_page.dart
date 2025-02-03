import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/api/firebase_api.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/cus_notifications_page.dart';
import 'package:hire_harmony/views/pages/customer/search_and_filter.dart';
import 'package:hire_harmony/views/pages/customer/view_all_popular_services.dart';
import 'package:hire_harmony/views/pages/location_page.dart';
import 'package:hire_harmony/views/pages/near_page.dart';
import 'package:hire_harmony/views/widgets/customer/best_worker.dart';
import 'package:hire_harmony/views/widgets/customer/category_widget.dart';
import 'package:hire_harmony/views/widgets/customer/custom_carousel_indicator.dart';
import 'package:hire_harmony/views/widgets/customer/invite_link_dialog.dart';
import 'package:hire_harmony/views/widgets/customer/populer_service.dart';
import 'package:hire_harmony/views/widgets/customer/view_all_best_workers_page.dart';
import 'package:hire_harmony/views/widgets/customer/view_all_categories.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:cloud_firestore/cloud_firestore.dart';
class CusHomePage extends StatefulWidget {
  const CusHomePage({super.key});

  @override
  State<CusHomePage> createState() => _CusHomePageState();
}

class _CusHomePageState extends State<CusHomePage> {
  final String? userId = FirebaseAuth.instance.currentUser?.uid;
List<String> categoriesToUpdate = [
    "Plumbers, Pipefitters, and Steamfitters",
    "Makeup Artists, Theatrical and Performance",
    "Tutors"
  ];
  @override
  void initState() {
    super.initState();
    _checkUserLocation();
   /* getUserCategories('A2oGAPpXlBOOqKlR6jgC3xUK3003');*/
    /*updateSpecificCategoriesWithWorkers(categoriesToUpdate);*/
  }
 

void fetchAndPrintUserLocation(String userId) async {
  Map<String, String>? location = await getCityAndCountry(userId);
  if (location != null) {
    print("المدينة: ${location['city']}, الدولة: ${location['country']}");
  } else {
    print("لم يتم العثور على الموقع.");
  }
}

Future<Map<String, String>?> getCityAndCountry(String userId) async {
  try {
    // 1️⃣ Fetch user data from Firebase
    DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(userId)
        .get();

    if (!userDoc.exists) {
      print("❌ The user does not exist in the database.");
      return null;
    }

    // 2️⃣ Check if the document has data
    Map<String, dynamic>? userData = userDoc.data() as Map<String, dynamic>?;

    if (userData == null || !userData.containsKey('location')) {
      print("❌ 'location' field does not exist for this user.");
      return null;
    }

    Map<String, dynamic> locationData = userData['location'];

    if (!locationData.containsKey('latitude') || !locationData.containsKey('longitude')) {
      print("❌ 'latitude' or 'longitude' is missing in location data.");
      return null;
    }

    // 3️⃣ Convert latitude and longitude to double
    double latitude;
    double longitude;
    try {
      latitude = double.parse(locationData['latitude']);
      longitude = double.parse(locationData['longitude']);
    } catch (e) {
      print("❌ Error converting latitude/longitude to double: $e");
      return null;
    }

    print("📍 Coordinates: Latitude = $latitude, Longitude = $longitude");

    // 4️⃣ Call Google Geocoding API
    final response = await http.get(
      Uri.parse(
          'https://maps.googleapis.com/maps/api/geocode/json?latlng=$latitude,$longitude&key=AIzaSyCyl4pNb6FhDky0Rad3z8GKDt4Un42ccP4'),
    );

    if (response.statusCode == 200) {
      Map<String, dynamic> data = jsonDecode(response.body);

      if (data['status'] == 'OK') {
        List<dynamic> results = data['results'];

        for (var result in results) {
          List<dynamic> addressComponents = result['address_components'];

          String? city;
          String? country;

          for (var component in addressComponents) {
            List types = component['types'];
            if (types.contains('locality')) {
              city = component['long_name'];
            } else if (types.contains('country')) {
              country = component['long_name'];
            }
          }

          if (city != null && country != null) {
            return {'city': city, 'country': country};
          }
        }
      } else {
        print("❌ Google API error: ${data['status']}");
      }
    } else {
      print("❌ Failed to fetch from Google Geocoding API: ${response.statusCode}");
    }
  } catch (e) {
    print("❌ Error fetching data: $e");
  }

  return null;
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



/*
Future<void> updateSpecificCategoriesWithWorkers(List<String> categoryNames) async {
  try {
    final FirebaseFirestore firestore = FirebaseFirestore.instance;

    for (String categoryName in categoryNames) {
      print("🔍 Processing category: $categoryName");

      // 🔹 1. البحث عن الكاتيجوري في كوليكشن `categories`
      QuerySnapshot categorySnapshot = await firestore
          .collection('categories')
          .where('name', isEqualTo: categoryName)
          .get();

      if (categorySnapshot.docs.isEmpty) {
        print("⚠ No category found with name: $categoryName");
        continue; // تخطي الكاتيجوري غير الموجودة
      }

      DocumentReference categoryRef = categorySnapshot.docs.first.reference;

      List<String> workerIds = [];

      // 🔹 2. جلب المستخدمين الذين لديهم `role = employee`
      QuerySnapshot usersSnapshot = await firestore
          .collection('users')
          .where('role', isEqualTo: 'employee') // ✅ جلب الموظفين فقط
          .get();

      for (var userDoc in usersSnapshot.docs) {
        // 🔹 البحث داخل `empcategories` لكل مستخدم
        QuerySnapshot empCategoriesSnapshot = await userDoc.reference.collection('empcategories').get();

        for (var empCategoryDoc in empCategoriesSnapshot.docs) {
          List<dynamic> categories = empCategoryDoc['categories'] ?? [];

          if (categories.contains(categoryName)) {
            workerIds.add(userDoc.id);
            print("✅ User ${userDoc.id} belongs to category: $categoryName");
            break; // ✅ إذا وجدناه، لا داعي لمتابعة البحث داخل نفس المستخدم
          }
        }
      }

      if (workerIds.isEmpty) {
        print("⚠ No workers found for category: $categoryName. Skipping update.");
        continue;
      }

      // 🔹 3. تحديث `workers` في `categories`
      await categoryRef.update({
        'workers': workerIds,
      });

      print("✅ Updated category: $categoryName with ${workerIds.length} workers.");
    }

    print("🎯 All specified categories updated successfully with workers.");
  } catch (e) {
    print("❌ Error updating categories: $e");
  }
}
*/

  Future<void> _checkUserLocation() async {
    await Future.delayed(const Duration(seconds: 5)); // الانتظار لمدة 10 ثوانٍ

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
        actions: [
          IconButton(
            onPressed: () {
            /*  Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CusNotificationsPage(),
                ),
                
              );*/
              Navigator.push(
  context,
  MaterialPageRoute(builder: (context) => const NearestUsersPage()), // ✅ الصحيح
);

            },
            icon: const Icon(Icons.notifications),
            color: AppColors().white,
          )
        ],
        title: Column(
          children: [
            Row(
              children: [
                Icon(
                  Icons.location_on,
                  color: AppColors().white,
                ),
                Text('Qalqiliya , palestine',
                    style: GoogleFonts.montserratAlternates(
                        color: AppColors().white, fontSize: 16)),
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
                          backgroundColor: AppColors().white,
                          foregroundColor: AppColors().navy,
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
                                  color: AppColors().navy,
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
                    InkWell(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                const ViewAllBestWorkersPage(),
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
