import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:intl/intl.dart';

class ReviewsTapView extends StatelessWidget {
  final String employeeId;

  const ReviewsTapView({super.key, required this.employeeId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(employeeId)
          .collection('reviews')
          .orderBy('date', descending: true) // ترتيب حسب الأحدث
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No reviews available",
              style: TextStyle(color: Colors.grey, fontSize: 16),
            ),
          );
        }

        final reviews = snapshot.data!.docs;
        debugPrint("Total reviews: ${reviews.length}");

        return ListView.builder(

          padding: const EdgeInsets.all(10),
          itemCount: reviews.length,
          itemBuilder: (context, index) {
            final data = reviews[index].data() as Map<String, dynamic>;
            final reviewerName = data['name'] ?? 'Anonymous';
            final reviewText = data['review'] ?? '';
            final double rating = double.tryParse(data['rating']?.toString() ?? '0.0') ?? 0.0;

            // تحويل Timestamp إلى تاريخ مقروء
            final Timestamp? timestamp = data['date'] as Timestamp?;
            final String formattedDate = timestamp != null
                ? DateFormat('dd MMM, yyyy').format(timestamp.toDate())
                : 'Unknown Date';

            return Card(
              elevation: 2,
              margin: const EdgeInsets.symmetric(vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 🔹 اسم المراجع + التاريخ
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: AppColors().lightblue,
                              child: Text(
                                reviewerName.isNotEmpty
                                    ? reviewerName[0].toUpperCase()
                                    : 'A', // عرض أول حرف من الاسم
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(
                              reviewerName,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        Text(
                          formattedDate,
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    // 🔹 تقييم النجوم
                    Row(
                      children: List.generate(
                        5,
                        (starIndex) => Icon(
                          starIndex < rating.round()
                              ? Icons.star
                              : Icons.star_border,
                          color: AppColors().orange,
                          size: 18,
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // 🔹 نص التقييم
                    Text(
                      reviewText,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
