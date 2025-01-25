import 'dart:ui';

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
            // Navigator.of(context).pop();
            // root navigator is better to use here because of the bottom navBar
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
                        image: const DecorationImage(
                          image:
                              AssetImage('lib/assets/images/adminmalak.jpeg'),
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Malak Ibrahim',
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
                            icon: Icons.logout_outlined,
                            title: 'Logout',
                            onTap: () async {
                              await authCubit.signOut();
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
