import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:hire_harmony/view_models/cubit/adnhome_cubit.dart';
import 'package:hire_harmony/view_models/cubit/auth_cubit.dart';
import 'package:hire_harmony/views/pages/admin/ad_management_page.dart';
import 'package:hire_harmony/views/pages/admin/admin_activity_page.dart';
import 'package:hire_harmony/views/pages/admin/admin_settings_page.dart';
import 'package:hire_harmony/views/pages/admin/adn_home_page.dart' as admin;
import 'package:hire_harmony/views/pages/admin/adn_navbar.dart';
import 'package:hire_harmony/views/pages/admin/adn_notifications_page.dart';
import 'package:hire_harmony/views/pages/admin/adn_personal_info_page.dart';
import 'package:hire_harmony/views/pages/admin/category_management_page.dart';
import 'package:hire_harmony/views/pages/admin/deleted_acounts.dart';
import 'package:hire_harmony/views/pages/admin/edit_services_page.dart';
import 'package:hire_harmony/views/pages/admin/edited_services_page.dart';
import 'package:hire_harmony/views/pages/admin/employees_maintenance.dart';
import 'package:hire_harmony/views/pages/admin/user_management_page.dart';
import 'package:hire_harmony/views/pages/chat_page.dart';
import 'package:hire_harmony/views/pages/customer/account_deletion_page.dart';
import 'package:hire_harmony/views/pages/customer/view_all_popular_services.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';
import 'package:hire_harmony/views/pages/employee/contact_us_page.dart';
import 'package:hire_harmony/views/pages/employee/emp_navbar.dart';
import 'package:hire_harmony/views/pages/employee/emp_notifications_page.dart';
import 'package:hire_harmony/views/pages/employee/emp_profile_info_page.dart';
//import 'package:hire_harmony/views/pages/forms/emp_sign_up_form.dart';
import 'package:hire_harmony/views/pages/signup/sign_up_page.dart';
import 'package:hire_harmony/views/pages/customer/cus_verification_success_page.dart';
import 'package:hire_harmony/views/pages/customer/cus_messages_page.dart';
import 'package:hire_harmony/views/pages/customer/cus_notifications_page.dart';
import 'package:hire_harmony/views/pages/customer/custom_buttom_navbar.dart';
import 'package:hire_harmony/views/pages/customer/cus_home_page.dart';
import 'package:hire_harmony/views/pages/employee/emp_verification_success_page.dart';
import 'package:hire_harmony/views/pages/employee/emp_home_page.dart';
import 'package:hire_harmony/views/pages/signup/forgot_password_page.dart';
import 'package:hire_harmony/views/pages/login/login_page.dart';
import 'package:hire_harmony/views/pages/employee/emp_id_verification_page.dart';
//import 'package:hire_harmony/views/pages/employee/emp_phone_page.dart';
import 'package:hire_harmony/views/pages/signup/phone_page.dart';
import 'package:hire_harmony/views/pages/signup/sign_up_choice.dart';
import 'package:hire_harmony/views/pages/welcome_page.dart';
import 'package:hire_harmony/views/widgets/customer/view_all_best_workers_page.dart';
import 'package:hire_harmony/views/widgets/customer/view_all_categories.dart';

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.welcomePage:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) {
              final cubit = AuthCubit();
              return cubit;
            },
            child: const WelcomePage(),
          ),
          settings: settings,
        );
      case AppRoutes.loginPage:
        return MaterialPageRoute(
          builder: (_) => const LoginPage(),
          settings: settings,
        );
      case AppRoutes.signUpPage:
        return MaterialPageRoute(
          builder: (_) => const SignUpPage(),
          settings: settings,
        );
      // case AppRoutes.empSignupForm:
      //   return MaterialPageRoute(
      //     builder: (_) => const EmpSignupForm(),
      //     settings: settings,
      //   );
      case AppRoutes.empNavbar:
        return MaterialPageRoute(
          builder: (_) => const EmpNavbar(),
          settings: settings,
        );
      case AppRoutes.cushomePage:
        return MaterialPageRoute(
          builder: (_) => const CusHomePage(),
          settings: settings,
        );
      case AppRoutes.cusMessagesPage:
        return MaterialPageRoute(
          builder: (_) => const CusMessagesPage(),
          settings: settings,
        );
      case AppRoutes.cusNotificationsPage:
        return MaterialPageRoute(
          builder: (_) => const CusNotificationsPage(),
          settings: settings,
        );
      case AppRoutes.customButtomNavbarPage:
        return MaterialPageRoute(
          builder: (_) => const CustomButtomNavbar(),
          settings: settings,
        );
      case AppRoutes.viewAllCategoriesPage:
        return MaterialPageRoute(
          builder: (_) => const ViewAllCategoriesPage(),
          settings: settings,
        );
      case AppRoutes.viewAllPopularServicesPage:
        return MaterialPageRoute(
          builder: (_) => const ViewAllPopularServicesPage(),
          settings: settings,
        );
      case AppRoutes.viewAllBestWorkersPage:
        return MaterialPageRoute(
          builder: (_) => const ViewAllBestWorkersPage(),
          settings: settings,
        );
      case AppRoutes.viewEmpProfilePage:
        return MaterialPageRoute(
          builder: (_) => ViewEmpProfilePage(
              employeeId: FirebaseAuth.instance.currentUser!.uid),
          settings: settings,
        );
      case AppRoutes.emphomePage:
        return MaterialPageRoute(
          builder: (_) => const EmpHomePage(),
          settings: settings,
        );
      case AppRoutes.empNotificationsPage:
        return MaterialPageRoute(
          builder: (_) => const EmpNotificationsPage(),
          settings: settings,
        );
      // case AppRoutes.empphonePage:
      //   return MaterialPageRoute(
      //     builder: (_) => const EmpPhonePage(),
      //     settings: settings,
      //   );
      case AppRoutes.empVerificationSuccessPage:
        return MaterialPageRoute(
          builder: (_) => const EmpVerificationSuccessPage(
              notificationTitle: 'Success!',
              notificationMessage:
                  'User verified successfully,\nShare your skills and experience with everyone!'),
          settings: settings,
        );

    /*  case AppRoutes.empidverificationPage:
        return MaterialPageRoute(
          builder: (_) => const EmpIdVerificationPage(),
          settings: settings,
        );
*/
      case AppRoutes.empProfileInfoPage:
        return MaterialPageRoute(
          builder: (_) => const EmpProfileInfoPage(),
          settings: settings,
        );
      case AppRoutes.accountDeletionScreen:
        return MaterialPageRoute(
          builder: (_) => const AccountDeletionScreen(),
          settings: settings,
        );
      case AppRoutes.contactUsPage:
        return MaterialPageRoute(
          builder: (_) => const ContactUsPage(),
          settings: settings,
        );
      case AppRoutes.adnhomePage:
        return MaterialPageRoute(
          builder: (_) => const admin.AdnHomePage(),
          settings: settings,
        );
      case AppRoutes.adnnavPage:
        return MaterialPageRoute(
          builder: (_) => const AdnNavbar(),
          settings: settings,
        );
      case AppRoutes.editServicesPage:
        return MaterialPageRoute(
          builder: (_) => const EditServicesPage(),
          settings: settings,
        );
      case AppRoutes.userManagementPage:
        return MaterialPageRoute(
          builder: (_) => const UserManagementPage(),
          settings: settings,
        );
      case AppRoutes.adManagementPage:
        return MaterialPageRoute(
          builder: (_) => const AdManagementPage(),
          settings: settings,
        );
      case AppRoutes.categoryManagementPage:
        return MaterialPageRoute(
          builder: (_) => const CategoryManagementPage(),
          settings: settings,
        );

      case AppRoutes.adnnpersonalinfoPage:
        return MaterialPageRoute(
          builder: (_) => const AdnPersonalInfoPage(),
          settings: settings,
        );
      case AppRoutes.signupChoicePage:
        return MaterialPageRoute(
          builder: (_) => const SignUpChoice(),
          settings: settings,
        );
        case AppRoutes.employeesmaintenance:
        return MaterialPageRoute(
          builder: (_) => const EmployeesMaintenance(),
          settings: settings,
        );
      case AppRoutes.adnsettingsPage:
        return MaterialPageRoute(
          builder: (_) => const AdminSettingsPage(),
          settings: settings,
        );
      case AppRoutes.adnnotificationsPage:
        return MaterialPageRoute(
          builder: (_) => BlocProvider(
            create: (context) {
              final cubit = AdnHomeCubit();
              return cubit;
            },
            child: const AdnNotificationsPage(),
          ),
          settings: settings,
        );
      case AppRoutes.deletedAccounts:
        return MaterialPageRoute(
          builder: (_) =>
              DeletedAcounts(uid: FirebaseAuth.instance.currentUser!.uid),
          settings: settings,
        );
      case AppRoutes.editedServicesPage:
        return MaterialPageRoute(
          builder: (_) =>
              EditedServicesPage(uid: FirebaseAuth.instance.currentUser!.uid),
          settings: settings,
        );
      case AppRoutes.adnactivityPage:
        return MaterialPageRoute(
          builder: (_) =>
              AdminActivityPage(uid: FirebaseAuth.instance.currentUser!.uid),
          settings: settings,
        );
      case AppRoutes.forgotPasswordPage:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordPage(),
          settings: settings,
        );
      case AppRoutes.phonePage:
        return MaterialPageRoute(
          builder: (_) => const PhonePage(),
          settings: settings,
        );
      case AppRoutes.cusVerificationSuccessPage:
        return MaterialPageRoute(
          builder: (_) => const CusVerificationSuccessPage(
            notificationTitle: 'Phone verification success',
            notificationMessage:
                'You have successfully verified that you are using a valid phone number,\nEnjoy our services!',
          ),
          settings: settings,
        );
      case AppRoutes.chat:
        return MaterialPageRoute(
          builder: (_) => const ChatPage(reciverEmail: 'moe@gmail.com',),
          settings: settings,
        );

      default:
        return MaterialPageRoute(
          builder: (_) => const Scaffold(
            body: Center(child: Text('NError page')),
          ),
        );
    }
  }
}
