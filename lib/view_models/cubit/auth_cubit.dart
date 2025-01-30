import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/utils/route/app_routes.dart';
import 'package:hire_harmony/utils/theme_provider.dart';
import 'package:provider/provider.dart';

part 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit() : super(AuthInitial());

  final AuthServices authServices = AuthServicesImpl();
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _fireS = FirestoreService.instance;

  String getFriendlyErrorMessage(String firebaseErrorCode) {
    switch (firebaseErrorCode) {
      case 'user-not-found':
        return 'No account found with this email.';
      case 'wrong-password':
        return 'Incorrect password.';
      case 'invalid-email':
        return 'Invalid email address.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'too-many-requests':
        return 'Too many attempts. Try again later.';
      default:
        return 'An error occurred. Please try again.';
    }
  }

  Future<void> signInWithEmailAndPassword(String email, String password) async {
    emit(AuthLoading());
    try {
      final result =
          await authServices.signInWithEmailAndPassword(email, password);

      if (result) {
        final user = await authServices.currentUser();

        if (user != null) {
          String role = await _fireS.getUserRoleByUid(user.uid);

          if (role == "admin") {
            emit(AuthSuccess());
          } else if (role == "customer") {
            emit(AuthCusSuccess());
          } else if (role == "employee") {
            emit(AuthEmpSuccess());
          } else {
            emit(AuthFailure(
                "Account role not recognized. Please contact support."));
          }
        } else {
          emit(AuthFailure("Unable to fetch user data. Try again later."));
        }
      } else {
        emit(
            AuthFailure("Login failed. Check your credentials and try again."));
      }
    } on FirebaseAuthException catch (firebaseAuthException) {
      emit(AuthFailure(getFriendlyErrorMessage(firebaseAuthException.code)));
    } catch (e) {
      emit(AuthFailure("An unexpected error occurred. Try again later."));
    }
  }

  Future<void> signUpWithEmailAndPassword(
      String email, String password, String role) async {
    emit(AuthLoading());
    try {
      UserCredential userCredential =
          await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password, // Raw password
      );

      // Store the user role and other details in Firestore
      await _firestore.collection('users').doc(userCredential.user!.uid).set({
        'email': email,
        'role': role, // "customer", "employee", "admin"
      });

      emit(AuthSuccess());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // Future<void> cusSignInWithEmailAndPassword(
  //     String email, String password) async {
  //   emit(AuthLoading());
  //   try {
  //     final result =
  //         await authServices.cusSignInWithEmailAndPassword(email, password);
  //     if (result) {
  //       emit(AuthCusSuccess());
  //     } else {
  //       emit(AuthFailure('Failed to  sign in'));
  //     }
  //   } catch (e) {
  //     emit(AuthFailure(e.toString()));
  //   }
  // }

  // Future<void> empSignInWithEmailAndPassword(
  //     String email, String password) async {
  //   emit(AuthLoading());
  //   try {
  //     final result =
  //         await authServices.empSignInWithEmailAndPassword(email, password);
  //     if (result) {
  //       emit(AuthEmpSuccess());
  //     } else {
  //       emit(AuthFailure('Failed to  sign in'));
  //     }
  //   } catch (e) {
  //     emit(AuthFailure(e.toString()));
  //   }
  // }
 /* Future<void> signOut() async {
    emit(AuthLoading());
    try {
      await authServices.signOut();
      
      emit(AuthInitial());
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }*/
 Future<void> signOut(BuildContext context) async {
  emit(AuthLoading());
  try {
    await authServices.signOut();

    // التأكد من أن السياق لا يزال متاحًا قبل إعادة تعيين الثيم
    if (context.mounted) {
      Provider.of<ThemeProvider>(context, listen: false).resetTheme();
    }

    emit(AuthInitial());
  } catch (e) {
    emit(AuthFailure(e.toString()));
  }
}


  Future<void> getCurrentUser() async {
    emit(AuthLoading());
    try {
      final user = await authServices.currentUser();
      if (user != null) {
        emit(AuthSuccess());
      } else {
        emit(AuthInitial());
      }
    } catch (e) {
      emit(AuthFailure(e.toString()));
    }
  }

  // Future<void> getCurrentUser() async {
  //   emit(AuthLoading());
  //   try {
  //     final user = await authServices.currentUser();
  //     final signIn = await authServices.isSignIn();
  //     //log('$user');
  //     if (signIn) {
  //       String role = await _fireS.getUserRoleByUid(user!.uid);
  //     //  log(role);
  //       if (role == 'admin') {
  //         emit(AuthSuccess());
  //       } else if (role == 'customer') {
  //         emit(AuthCusSuccess());
  //       } else if (role == 'employee') {
  //         emit(AuthEmpSuccess());
  //       }
  //     } else {
  //       emit(AuthInitial());
  //     }
  //   } catch (e) {
  //     emit(AuthFailure(e.toString()));
  //   }
  // }

  // Fetch the role of the user
}
