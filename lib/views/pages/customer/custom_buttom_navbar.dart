import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/chat_list_page.dart';
import 'package:hire_harmony/views/pages/customer/community.dart';
import 'package:hire_harmony/views/pages/customer/cus_home_page.dart';
import 'package:hire_harmony/views/pages/customer/cus_profile_page.dart';
import 'package:hire_harmony/views/pages/customer/order_page.dart';

class CustomButtomNavbar extends StatefulWidget {
  const CustomButtomNavbar({super.key});

  @override
  State<CustomButtomNavbar> createState() => _CustomButtomNavbarState();
}

class _CustomButtomNavbarState extends State<CustomButtomNavbar> {
  int currentPageIndex = 2;

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      extendBody: true,
      bottomNavigationBar: size.width >= 800
          ? null
          : NavigationBarTheme(
              data: NavigationBarThemeData(
                labelTextStyle: WidgetStateProperty.all(
                  GoogleFonts.montserratAlternates(
                    textStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors().navy,
                    ),
                  ),
                ),
              ),
              child: NavigationBar(
                onDestinationSelected: (int index) {
                  setState(() {
                    currentPageIndex = index;
                  });
                },
                backgroundColor: AppColors().white.withValues(alpha: 0.85),
                indicatorColor: AppColors().orange,
                selectedIndex: currentPageIndex,
                elevation: 0,
                destinations: <Widget>[
                  NavigationDestination(
                    selectedIcon: Icon(
                      Icons.message,
                      color: AppColors().white,
                    ),
                    icon: Icon(
                      Icons.message_outlined,
                      color: AppColors().navy,
                    ),
                    label: 'Messages',
                  ),
                  NavigationDestination(
                    selectedIcon: Icon(Icons.list, color: AppColors().white),
                    icon:
                        Icon(Icons.list_alt_outlined, color: AppColors().navy),
                    label: 'My Order',
                  ),
                  NavigationDestination(
                    selectedIcon: Icon(
                      Icons.home,
                      color: AppColors().white,
                    ),
                    icon: Icon(
                      Icons.home_outlined,
                      color: AppColors().navy,
                    ),
                    label: 'Home',
                  ),
                  NavigationDestination(
                    selectedIcon: Icon(
                      Icons.living,
                      color: AppColors().white,
                    ),
                    icon: Icon(
                      Icons.living_outlined,
                      color: AppColors().navy,
                    ),
                    label: 'Community',
                  ),
                  NavigationDestination(
                    selectedIcon: Icon(
                      Icons.person,
                      color: AppColors().white,
                    ),
                    icon: Icon(
                      Icons.person_2_outlined,
                      color: AppColors().navy,
                    ),
                    label: 'Profile',
                  ),
                ],
              ),
            ),
      body: <Widget>[
        /*  BlocProvider(
          create: (context) {
            final cubit = ChatCubit();
            cubit.getMessages();
            return cubit;
          },
          child: const ChatPage(reciverEmail: 'moe@gmail.com',),
        ),
        */
        const ChatListPage(),
        const OrderPage(),
        const CusHomePage(),
        const Community(),
        const CusProfilePage(),
      ][currentPageIndex],
    );
  }
}
