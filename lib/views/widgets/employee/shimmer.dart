import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
class ShimmerPage extends StatefulWidget {
  const ShimmerPage({super.key});

  @override
  State<ShimmerPage> createState() => _ShimmerPageState();
}
class _ShimmerPageState extends State<ShimmerPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
              width: double.infinity,
              height: double.infinity,
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Shimmer.fromColors(
                    baseColor: Colors.grey[300]!,
                    highlightColor: Colors.grey[100]!,
                    child: Container(
                      height: 20,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: 8, 
                      itemBuilder: (context, index) {
                        return Shimmer.fromColors(
                          baseColor: Colors.grey[300]!,
                          highlightColor: Colors.grey[100]!,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                               
                                Container(
                                  width: 50,
                                  height: 50,
                                  decoration: BoxDecoration(
                                    color: Colors.grey[400],
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                const SizedBox(width: 12),

                                // ✅ تفاصيل الموظف الوهمية
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        height: 10,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 8,
                                        width: double.infinity,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Container(
                                        height: 6,
                                        width: 100,
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius:
                                              BorderRadius.circular(4),
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
                    ),
                  ),
                ],
              ),
            );
  }
}