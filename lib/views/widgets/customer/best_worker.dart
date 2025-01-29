import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';

class BestWorker extends StatelessWidget {
  const BestWorker({super.key});

  Future<Map<String, dynamic>> fetchUserInfo(String userId) async {
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(userId).get();
    if (userDoc.exists) {
      return userDoc.data()!;
    }
    return {};
  }

  @override
  Widget build(BuildContext context) {
    final Stream<List<Map<String, dynamic>>> bestWorkersStream =
        FirebaseFirestore.instance
            .collection('bestworker')
            .snapshots()
            .map((snapshot) {
      return snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'data': doc.data(),
        };
      }).toList();
    });

    return SizedBox(
      height: 250, // 🔹 ارتفاع مناسب
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: bestWorkersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No best workers found'));
          }
          final bestWorkers = snapshot.data!;
          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bestWorkers.length,
            itemBuilder: (context, index) {
              final bestWorker = bestWorkers[index];
              final bestWorkerId = bestWorker['id'];

              return FutureBuilder<Map<String, dynamic>>(
                future: fetchUserInfo(bestWorkerId),
                builder: (context, userSnapshot) {
                  if (userSnapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (userSnapshot.hasError ||
                      userSnapshot.data == null ||
                      userSnapshot.data!.isEmpty) {
                    return const Center(
                        child: Text('Error fetching user details'));
                  }

                  final userInfo = userSnapshot.data!;
                  final workerName = userInfo['name'] ?? 'Unknown Worker';
                  final workerImg = userInfo['img'] ?? '';
                  final workerServNum = bestWorker['data']['servNum'] ?? '0';
                  final double rating = double.tryParse(userInfo['rating']?.toString() ?? '0.0') ?? 0.0;
                  final int reviewsNum = int.tryParse(userInfo['reviewsNum']?.toString() ?? '0') ?? 0;

                  return InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewEmpProfilePage(
                            employeeId: bestWorkerId,
                          ),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      width: 200,
                      height: 220, // 🔹 تم تقليل الارتفاع لحذف الفراغ
                      margin: const EdgeInsets.symmetric(horizontal: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(15),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(100),
                            blurRadius: 10,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min, // 🔹 منع التمدد غير الضروري
                        children: [
                          // 🔹 الجزء العلوي: خلفية برتقالية مع صورة العامل
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors().orange,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(15)),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                children: [
                                  const SizedBox(height: 8),
                                  Center(
                                    child: CircleAvatar(
                                      radius: 35,
                                      backgroundColor: Colors.white,
                                      backgroundImage: workerImg.isNotEmpty
                                          ? NetworkImage(workerImg)
                                          : null,
                                      child: workerImg.isEmpty
                                          ? Icon(Icons.person, size: 35, color: Colors.grey[600])
                                          : null,
                                    ),
                                  ),
                                  const SizedBox(height: 5),
                                  Text(
                                    workerName,
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.montserratAlternates(
                                      textStyle: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: AppColors().white,
                                      ),
                                    ),
                                  ),
                                  Text(
                                    'Services: $workerServNum',
                                    style: GoogleFonts.montserratAlternates(
                                      textStyle: const TextStyle(
                                        fontSize: 12,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 8), // 🔹 تحسين التباعد بين القسمين

                          // 🔹 عدد التقييمات والمراجعات
                          Container(
                            height: 60, // 🔹 تحديد ارتفاع مناسب لمنع الفراغ
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min, // 🔹 منع التمدد غير الضروري
                                    children: [
                                      Text(
                                        rating.toStringAsFixed(1),
                                        style: GoogleFonts.montserratAlternates(
                                          textStyle: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors().navy,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        "Rating",
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                                Flexible(
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min, // 🔹 منع التمدد غير الضروري
                                    children: [
                                      Text(
                                        reviewsNum.toString(),
                                        style: GoogleFonts.montserratAlternates(
                                          textStyle: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: AppColors().navy,
                                          ),
                                        ),
                                      ),
                                      const Text(
                                        "Reviews",
                                        style: TextStyle(fontSize: 12, color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
