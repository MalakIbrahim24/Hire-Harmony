import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/cus_notifications_page.dart';
import 'package:hire_harmony/views/pages/customer/search_and_filter.dart';
import 'package:hire_harmony/views/pages/customer/view_all_popular_services.dart';
import 'package:hire_harmony/views/widgets/customer/best_worker.dart';
import 'package:hire_harmony/views/widgets/customer/category_widget.dart';
import 'package:hire_harmony/views/widgets/customer/custom_carousel_indicator.dart';
import 'package:hire_harmony/views/widgets/customer/invite_link_dialog.dart';
import 'package:hire_harmony/views/widgets/customer/populer_service.dart';
import 'package:hire_harmony/views/widgets/customer/view_all_best_workers_page.dart';
import 'package:hire_harmony/views/widgets/customer/view_all_categories.dart';

class CusHomePage extends StatelessWidget {
  const CusHomePage({super.key});

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
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CusNotificationsPage(),
                ),
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
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0, horizontal: 14),
            child: Column(
              children: [
                const CustomCarouselIndicator(),
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
                      'Popular Services on Hire Harmony',
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
                            color: AppColors().navy,
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
                            color: AppColors().navy,
                            fontWeight: FontWeight.w400,
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
                              Icons.arrow_forward,
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
