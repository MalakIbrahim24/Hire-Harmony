import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/customer/view_emp_profile_page.dart';

class FavoritesPage extends StatefulWidget {
  const FavoritesPage({super.key});

  @override
  State<FavoritesPage> createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  final String? loggedInUserId = FirebaseAuth.instance.currentUser?.uid;

  Stream<List<Map<String, dynamic>>> _fetchFavorites() async* {
    if (loggedInUserId == null) {
      throw Exception('No user is currently signed in.');
    }

    yield* FirebaseFirestore.instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('favourites')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> _toggleFavorite(String favoriteId) async {
    if (loggedInUserId == null) return;

    final favoriteRef = FirebaseFirestore.instance
        .collection('users')
        .doc(loggedInUserId)
        .collection('favourites')
        .doc(favoriteId);

    try {
      final doc = await favoriteRef.get();
      if (doc.exists) {
        // If it exists, remove it
        await favoriteRef.delete();
      }
    } catch (e) {
      debugPrint('Error toggling favorite: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        centerTitle: true, // Center the title
        title: Text(
          'Favorites',
          style: GoogleFonts.montserratAlternates(
            color: Theme.of(context).colorScheme.primary,
          ),
        ),
      backgroundColor: Theme.of(context).colorScheme.surface,
        elevation: 0,
        iconTheme: IconThemeData(color: AppColors().navy),
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _fetchFavorites(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(
              child: Text(
                'Error loading favorites: ${snapshot.error}',
                style: const TextStyle(color: Colors.red),
              ),
            );
          } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                'No favorites added yet!',
                style: GoogleFonts.montserratAlternates(
                color: Theme.of(context).colorScheme.primary,

                ),
              ),
            );
          }

          final favorites = snapshot.data!;

          return ListView.builder(
            itemCount: favorites.length,
            itemBuilder: (context, index) {
              final favorite = favorites[index];
              final favoriteId = favorite['uid'];

              return Card(
                margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
                child: ListTile(
                  onTap: () {
                    if (favoriteId != null && favoriteId is String) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ViewEmpProfilePage(
                            employeeId: favoriteId, // Pass the employee ID
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('This favorite item is invalid.'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  leading: CircleAvatar(
                    backgroundImage: NetworkImage(
                      favorite['img'] ?? 'https://via.placeholder.com/150',
                    ),
                  ),
                  title: Text(favorite['name'] ?? 'Unnamed Employee'),
                  subtitle: Text(favorite['location'] ?? 'Unknown location'),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.favorite,
                      color: Colors.red,
                    ),
                    onPressed: () {
                      if (favoriteId != null && favoriteId is String) {
                        _toggleFavorite(favoriteId);
                      }
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
