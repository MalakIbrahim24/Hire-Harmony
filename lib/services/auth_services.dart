import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:hire_harmony/services/firestore_services.dart';
import 'package:hire_harmony/utils/route/api_paths.dart';

abstract class AuthServices {
    User? getCurrentUser();

  Future<bool> signInWithEmailAndPassword(String email, String password);
  Future<bool> cusSignInWithEmailAndPassword(String email, String password);
  Future<bool> empSignInWithEmailAndPassword(String email, String password);

  Future<bool> signUpWithEmailAndPassword(String email, String password);

  Future<void> signOut();
  Future<User?> currentUser();
  Future<bool> isSignIn();
}

class AuthServicesImpl implements AuthServices {
  final firebaseAuth = FirebaseAuth.instance;
  final firestoreService = FirestoreService.instance;
  final _firestore =FirebaseFirestore.instance;
@override
User? getCurrentUser(){
  return firebaseAuth.currentUser;
}
  @override
  Future<bool> signInWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password, // Use raw password directly
      );
     
      return userCredential.user != null;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> signUpWithEmailAndPassword(String email, String password) async {
    try {
      final userCredential = await firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password, // Use raw password here
      );


      User? user = userCredential.user;
      if (user != null) {
        // Save user info (without password) in Firestore
        await firestoreService.setData(path: ApiPaths.user(user.uid), data: {
          'email': email,
          'uid': user.uid,
          'role': 'customer', // Default role for sign-up
        });
        return true;
      }
    } catch (e) {
      return false;
    }
    return false;
  }

  @override
  Future<void> signOut() async {
    await firebaseAuth.signOut();
  }

  @override
  Future<User?> currentUser() async {
    return firebaseAuth.currentUser;
  }

  @override
  Future<bool> isSignIn() async {
    return firebaseAuth.currentUser != null;
  }

  @override
  Future<bool> cusSignInWithEmailAndPassword(
      String email, String password) async {
    return await signInWithEmailAndPassword(email, password);
  }

  @override
  Future<bool> empSignInWithEmailAndPassword(
      String email, String password) async {
    return await signInWithEmailAndPassword(email, password);
  }
}

