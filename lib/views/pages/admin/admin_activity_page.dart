import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/admin_service.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/widgets/admin/adn_profile_container.dart';
import 'package:intl/intl.dart';

class AdminActivityPage extends StatefulWidget {
  final String uid;
  const AdminActivityPage({super.key, required this.uid});

  @override
  State<AdminActivityPage> createState() => _AdminActivityPageState();
}

class _AdminActivityPageState extends State<AdminActivityPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent, // Fully transparent
        elevation: 0,
        iconTheme: const IconThemeData(
          color: Colors.white, // Makes the back arrow white
        ), // No shadow
        centerTitle: true,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(
                    alpha:
                        0.5), // Transparent gradient to improve text visibility
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      body: Stack(children: [
        Positioned.fill(
          child: Image.asset(
            'lib/assets/images/notf.jpg',
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 17.0, sigmaY: 17.0),
            child: Container(
              color: AppColors().navy.withValues(alpha: 0.3),
            ),
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Static Header Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const SizedBox(
                    height: 80,
                  ),
                  Text(
                    "Activity Logs",
                    style: GoogleFonts.montserratAlternates(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: AppColors().white),
                  ),
                  const SizedBox(
                    height: 40,
                  ),
                  const SizedBox(
                    height: 15,
                  ),
                ],
              ),
            ),

            // StreamBuilder for Activity Logs (Scrollable Section)
            Expanded(
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: AdminService.instance.getActivityLogs(widget.uid),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return const Center(child: Text("Error loading logs"));
                  }
                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return const Center(child: Text("No activity logs found"));
                  }

                  final logs = snapshot.data!;

                  return ListView.builder(
                    padding: const EdgeInsets.all(10.0),
                    itemCount: logs.length,
                    itemBuilder: (context, index) {
                      final log = logs[index];
                      final action = log['action'] ?? 'Unknown Action';
                      final device = log['device'] ?? 'Unknown Device';
                      final timestamp =
                          (log['timestamp'] as Timestamp).toDate();
                      final formattedTime =
                          DateFormat('yyyy-MM-dd HH:mm:ss').format(timestamp);

                      return AdnProfileContainer(
                        icon: Icons.access_time_outlined,
                        title:
                            '$action \nDevice: $device \nTime: $formattedTime',
                        onTap: () {},
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ]),
    );
  }
}
