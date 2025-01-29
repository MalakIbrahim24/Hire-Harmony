import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReviewPage extends StatefulWidget {
  final String orderId;
  final String employeeId;
  final String employeeName;

  const ReviewPage({
    required this.orderId,
    required this.employeeId,
    required this.employeeName,
    super.key,
  });

  @override
  State<ReviewPage> createState() => _ReviewPageState();
}

class _ReviewPageState extends State<ReviewPage> {
  final TextEditingController _reviewController = TextEditingController();
  double rating = 0.0;
  bool isSubmitting = false;
  final _firestore = FirebaseFirestore.instance;

  Future<void> _submitReview() async {
    if (_reviewController.text.trim().isEmpty || rating == 0.0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please provide a rating and a review.')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      String userId = FirebaseAuth.instance.currentUser!.uid;

      // **التحقق مما إذا كان هناك مراجعة موجودة لنفس الطلب من نفس المستخدم**
      QuerySnapshot existingReview = await _firestore
          .collection('users')
          .doc(widget.employeeId)
          .collection('reviews')
          .where('orderId', isEqualTo: widget.orderId)
          .where('customerId', isEqualTo: userId)
          .get();

      if (existingReview.docs.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('You have already reviewed this order.')),
        );
        setState(() {
          isSubmitting = false;
        });
        return;
      }

      // **جلب بيانات المستخدم والعامل**
      DocumentSnapshot userDoc =
          await _firestore.collection('users').doc(userId).get();
      DocumentSnapshot empDoc =
          await _firestore.collection('users').doc(widget.employeeId).get();

      if (!userDoc.exists || !empDoc.exists) {
        debugPrint('Error: User or Employee document does not exist.');
        return;
      }

      String userName = userDoc['name'] ?? 'Anonymous';
      String reviewId = _firestore.collection('reviews').doc().id;

      final reviewData = {
        'reviewId': reviewId,
        'customerId': userId,
        'employeeId': widget.employeeId,
        'orderId': widget.orderId,
        'name': userName,
        'review': _reviewController.text.trim(),
        'rating':
            rating.toStringAsFixed(1), // تخزين الريتينج كنص بفاصلة عشرية واحدة
        'date': FieldValue.serverTimestamp(),
      };

      debugPrint('Submitting Review Data: $reviewData');

      // **إضافة الريفيو الجديد**
      await _firestore
          .collection('users')
          .doc(widget.employeeId)
          .collection('reviews')
          .doc(reviewId)
          .set(reviewData);

      await _firestore
          .collection('users')
          .doc(userId)
          .collection('completedOrders')
          .doc(widget.orderId)
          .update({
        'reviewed': true, // ✅ تحديث حالة الطلب ليصبح مراجعًا
      });

      await _firestore
          .collection('users')
          .doc(widget.employeeId)
          .collection('completedOrders')
          .doc(widget.orderId)
          .update({
        'reviewed': true, // ✅ تحديث حالة الطلب ليصبح مراجعًا
      });

      // **تحويل `reviewsNum` و `rating` إلى أرقام وإعادة حساب المتوسط**
      int totalReviews =
          int.tryParse(empDoc['reviewsNum']?.toString() ?? '0') ?? 0;
      double currentRating =
          double.tryParse(empDoc['rating']?.toString() ?? '0.0') ?? 0.0;
      double newReviewRating = rating;

      // **حساب متوسط التقييم الجديد**
      totalReviews += 1;
      double newAverageRating =
          ((currentRating * (totalReviews - 1)) + newReviewRating) /
              totalReviews;

      // **التأكد من أن القيم يتم تحديثها بشكل صحيح**
      await _firestore.collection('users').doc(widget.employeeId).set(
          {
            'reviewsNum': totalReviews.toString(), // تخزين العدد كنص
            'rating': newAverageRating
                .toStringAsFixed(1), // تخزين الريتينج بفاصلة عشرية واحدة كنص
          },
          SetOptions(
              merge: true)); // **استخدام `merge` لتجنب فقدان البيانات الأخرى**

      debugPrint('Updated reviewsNum: ${totalReviews.toString()}');
      debugPrint('Updated rating: ${newAverageRating.toStringAsFixed(1)}');

      debugPrint('Review submitted successfully!');
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Review submitted successfully!')),
      );
    } catch (e) {
      debugPrint('Firestore Error: ${e.toString()}');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Firestore Error: ${e.toString()}')),
      );
    }

    setState(() {
      isSubmitting = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: Text(
          'Leave a Review',
          style: GoogleFonts.montserratAlternates(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            Text(
              'Review for ${widget.employeeName}',
              style: GoogleFonts.montserratAlternates(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.inversePrimary,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rate your experience:',
              style: GoogleFonts.montserratAlternates(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                5,
                (index) => IconButton(
                  icon: Icon(
                    index < rating.toInt() ? Icons.star : Icons.star_border,
                    color: AppColors().orange,
                    size: 32,
                  ),
                  onPressed: () {
                    setState(() {
                      rating = index + 1.0;
                    });
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _reviewController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write your review...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: isSubmitting ? null : _submitReview,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors().orange,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                child: isSubmitting
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(
                        'Submit Review',
                        style: GoogleFonts.montserratAlternates(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
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
