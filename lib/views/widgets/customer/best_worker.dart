import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';
import 'package:lucide_icons/lucide_icons.dart';

class BestWorker extends StatefulWidget {
  const BestWorker({super.key});

  @override
  State<BestWorker> createState() => _BestWorkerState();
}

class _BestWorkerState extends State<BestWorker> {
  @override
  Stream<List<Map<String, dynamic>>> fetchTopWorkers() {
    return FirebaseFirestore.instance
        .collection('users')
        .where('role', isEqualTo: 'employee') // 🔥 جلب فقط الموظفين
        .orderBy('completedOrdersCount',
            descending: true) // ترتيب تنازلي حسب الطلبات المكتملة
        .limit(5)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;

        return {
          'id': doc.id,
          'name': data.containsKey('name') ? data['name'] : 'Unknown',
          'img': data.containsKey('img') && data['img'].toString().isNotEmpty
              ? data['img']
              : 'https://via.placeholder.com/150', // صورة افتراضية
          'completedOrdersCount': data.containsKey('completedOrdersCount')
              ? (data['completedOrdersCount'] is int
                  ? data['completedOrdersCount']
                  : int.tryParse(data['completedOrdersCount'].toString()) ?? 0)
              : 0, // 🔥 تأكد أنه int
          'rating': data.containsKey('rating')
              ? (data['rating'] is double
                  ? data['rating']
                  : double.tryParse(data['rating'].toString()) ?? 0.0)
              : 0.0, // 🔥 تأكد أنه double
          'reviewsNum': data.containsKey('reviewsNum')
              ? (data['reviewsNum'] is int
                  ? data['reviewsNum']
                  : int.tryParse(data['reviewsNum'].toString()) ?? 0)
              : 0, // 🔥 تأكد أنه int
        };
      }).toList();
    });
  }

  Widget build(BuildContext context) {
    final Stream<List<Map<String, dynamic>>> bestWorkersStream =fetchTopWorkers();

    return SizedBox(
      height: 300,
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: bestWorkersStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(child: Text('No top workers found'));
          }

          final bestWorkers = snapshot.data!;

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: bestWorkers.length,
            itemBuilder: (context, index) {
              final worker = bestWorkers[index];

              return WorkerCard(worker: worker);
            },
          );
        },
      ),
    );
  }
}

class WorkerCard extends StatelessWidget {
  final Map<String, dynamic> worker;

  const WorkerCard({super.key, required this.worker});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ViewEmpProfilePage(
              employeeId: worker['id'], // ✅ تمرير ID العامل
            ),
          ),
        );
      },
      child: Container(
        width: 220,
        height: 270, // 🔹 تثبيت ارتفاع البطاقة
        margin: const EdgeInsets.symmetric(horizontal: 12,vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(70),
              blurRadius: 12,
              spreadRadius: 2,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // 🔹 صورة البروفايل والخلفية
            Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors().orange,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                ),
                Positioned(
                  top: 25,
                  left: 50,
                  right: 50,
                  child: CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    backgroundImage: worker['img'] != null
                        ? NetworkImage(worker['img'])
                        : null,
                    child: worker['img'] == null
                        ? Icon(Icons.person, size: 35, color: Colors.grey[600])
                        : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 35),

            // 🔹 اسم العامل
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Text(
                worker['name'] ?? 'Unknown Worker',
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.montserratAlternates(
                  textStyle: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors().navy,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 5),

            // 🔹 عدد الطلبات المكتملة
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 16),
                  const SizedBox(width: 4),
                  Text(
                    'Completed: ${worker['completedOrdersCount']}',
                    style: GoogleFonts.montserratAlternates(
                      textStyle:
                          const TextStyle(fontSize: 14, color: Colors.green),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // 🔹 التقييم والمراجعات
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        worker['rating'].toStringAsFixed(1),
                        style: GoogleFonts.montserratAlternates(
                          textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors().navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      const Icon(Icons.message,
                          color: Colors.blueGrey, size: 18),
                      const SizedBox(width: 5),
                      Text(
                        worker['reviewsNum'].toString(),
                        style: GoogleFonts.montserratAlternates(
                          textStyle: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors().navy,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 5),

            // 🔹 زر عرض الملف الشخصي
            SizedBox(
              width: 140,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().navy,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ViewEmpProfilePage(
                        employeeId: worker['id'], // ✅ تمرير ID العامل
                      ),
                    ),
                  );
                },
                child: Text(
                  'View Profile',
                  style: GoogleFonts.montserratAlternates(
                    textStyle: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
