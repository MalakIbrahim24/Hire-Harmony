import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:hire_harmony/view_models/cubit/auth_cubit.dart';
import 'package:hire_harmony/views/widgets/admin/adn_profile_container.dart';
import 'package:hire_harmony/views/widgets/main_button.dart';

class AdnProfilePage extends StatefulWidget {
  const AdnProfilePage({super.key});

  @override
  State<AdnProfilePage> createState() => _AdnProfilePageState();
}

class _AdnProfilePageState extends State<AdnProfilePage> {
  final AuthServices authServices = AuthServicesImpl();
  String? adminImageUrl;
  String adminName = "Admin";

  @override
  void initState() {
    super.initState();
    fetchAdminData();
  }

  Future<void> fetchAdminData() async {
    try {
      final String adminUid = authServices.getCurrentUser()?.uid ?? '';
      if (adminUid.isEmpty) return;

      final DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .get();

      if (adminSnapshot.exists) {
        final adminData = adminSnapshot.data() as Map<String, dynamic>;
        setState(() {
          adminImageUrl = adminData['img'] as String? ?? '';
          adminName = adminData['name'] as String? ?? 'Admin';
        });
      }
    } catch (e) {
      debugPrint('Error fetching admin data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);

    return Center(
      child: BlocConsumer<AuthCubit, AuthState>(
        bloc: authCubit,
        listenWhen: (previous, current) =>
            current is AuthFailure || current is AuthInitial,
        listener: (context, state) {
          if (state is AuthFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors().red,
              ),
            );
          } else if (state is AuthInitial) {
            Navigator.of(context, rootNavigator: true)
                .pushReplacementNamed(AppRoutes.loginPage);
          }
        },
        buildWhen: (previous, current) =>
            current is AuthLoading || current is AuthFailure,
        builder: (context, state) {
          if (state is AuthLoading) {
            return const MainButton(
              child: CircularProgressIndicator.adaptive(),
            );
          }

          return Scaffold(
            backgroundColor: Colors.white,
            body: Stack(children: [
              Positioned.fill(
                child: Image.asset(
                  'lib/assets/images/notf.jpg',
                  fit: BoxFit.cover,
                ),
              ),
              // Blur Filter
              Positioned.fill(
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
                  child: Container(
                    color: AppColors().navy.withValues(alpha: 0.3),
                  ),
                ),
              ),
              Column(
                children: [
                  Center(
                    child: Container(
                      width: 250,
                      height: 400,
                      decoration: BoxDecoration(
                        color: AppColors().orange2.withValues(alpha: 0.3),
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(180),
                        ),
                        image: adminImageUrl != null &&
                                adminImageUrl!.isNotEmpty
                            ? DecorationImage(
                                image: NetworkImage(adminImageUrl!),
                                fit: BoxFit.cover,
                              )
                            : const DecorationImage(
                                image:
                                    AssetImage('lib/assets/images/noimg.jpg'),
                                fit: BoxFit.cover,
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    adminName,
                    style: GoogleFonts.montserratAlternates(
                      fontSize: 28,
                      color: AppColors().white,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
                          AdnProfileContainer(
                            icon: Icons.person_outline,
                            title: 'Personal Information',
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.adnnpersonalinfoPage);
                            },
                          ),
                          AdnProfileContainer(
                            icon: Icons.warning_amber_outlined,
                            title: 'Complaints',
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.complaintsPage);
                            },
                          ),
                          AdnProfileContainer(
                            icon: Icons.account_tree_outlined,
                            title: 'Employee Maintenance',
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.employeesmaintenance);
                            },
                          ),
                          AdnProfileContainer(
                            icon: Icons.settings_outlined,
                            title: 'Settings and Privacy',
                            onTap: () {
                              Navigator.pushNamed(
                                  context, AppRoutes.adnsettingsPage);
                            },
                          ),
                          AdnProfileContainer(
                            title: 'Logout',
  icon: Icons.logout,
  onTap: () async {
    await authCubit.signOut(context);
  },
                          ),
                          const SizedBox(
                            height: 80,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ]),
          );
        },
      ),
    );
  }
}
