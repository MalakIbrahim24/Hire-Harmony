import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:hire_harmony/view_models/cubit/auth_cubit.dart';
import 'package:hire_harmony/views/pages/employee/emp_profile_edit_page.dart';
import 'package:hire_harmony/views/pages/map_page.dart';
import 'package:hire_harmony/views/pages/settings_page.dart';
import 'package:hire_harmony/views/widgets/customer/state_item.dart';
import 'package:hire_harmony/views/widgets/employee/emp_build_menu_container.dart';
import 'package:hire_harmony/views/widgets/main_button.dart';

class EmpProfilePage extends StatefulWidget {
  const EmpProfilePage({super.key});

  @override
  State<EmpProfilePage> createState() => _EmpProfilePageState();
}

class _EmpProfilePageState extends State<EmpProfilePage> {
  final AuthServices authServices = AuthServicesImpl();

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String? _imageUrl;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _fetchEmployeeData();
  }

  Future<void> _fetchEmployeeData() async {
    try {
      final User? user = _auth.currentUser; // Get the logged-in user
      if (user == null) return;

      // Fetch the employee's document from Firestore
      final DocumentSnapshot doc =
          await _firestore.collection('users').doc(user.uid).get();

      if (doc.exists) {
        setState(() {
          _nameController.text = doc['name'] ?? '';
          _emailController.text = doc['email'] ?? '';
          _imageUrl = doc['img'] ??
              'https://via.placeholder.com/150'; // Placeholder if no image
        });
      }
    } catch (e) {
      debugPrint('Error fetching employee data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final authCubit = BlocProvider.of<AuthCubit>(context);

    return BlocConsumer<AuthCubit, AuthState>(
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
        return SafeArea(
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              automaticallyImplyLeading: false,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              centerTitle: true,
              actions: [
                IconButton(
                  icon: Icon(Icons.edit, color: AppColors().orange),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EmpProfileEditPage(),
                      ),
                    ).then(
                        (_) => _fetchEmployeeData()); // Refresh data on return
                  },
                ),
              ],
            ),
            body: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 20),
                CircleAvatar(
                  radius: 50,
                  backgroundImage: NetworkImage(
                    _imageUrl ??
                        'https://via.placeholder.com/150', // Placeholder if no image
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _nameController.text,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Text(
                  _emailController.text,
                  style: const TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors().grey,
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      StatItem(label: 'Orders \n Completed', value: '20'),
                      StatItem(label: 'Tickets', value: '2'),
                      StatItem(label: 'Pending \n Requests', value: '5'),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(children: [
                      EmpBuildMenuContainer(
                        title: 'Profile',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.pushNamed(
                              context,
                              AppRoutes
                                  .empProfileInfoPage); // Refresh data on return
                        },
                      ),
                      EmpBuildMenuContainer(
                        title: 'Map',
                        icon: Icons.person,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => MapPage(),
                            ),
                          );
                        },
                      ),
                      EmpBuildMenuContainer(
                        title: 'Contact us',
                        icon: Icons.contact_page,
                        onTap: () {
                          Navigator.pushNamed(context, AppRoutes.contactUsPage);
                        },
                      ),
                      EmpBuildMenuContainer(
                        title: 'Delete Account',
                        icon: Icons.info,
                        onTap: () {
                          Navigator.pushNamed(
                              context, AppRoutes.accountDeletionScreen);
                        },
                      ),
                      EmpBuildMenuContainer(
                        title: 'Setting',
                        icon: Icons.settings,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => const SettingsPage(),
                            ),
                          );
                        },
                      ),
                      EmpBuildMenuContainer(
                        title: 'Logout',
                        icon: Icons.logout,
                        onTap: () async {
                          await authCubit.signOut();
                        },
                      ),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
