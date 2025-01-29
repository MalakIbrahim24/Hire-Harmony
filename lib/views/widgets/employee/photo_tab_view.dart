import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PhotoTabView extends StatefulWidget {
  final String employeeId;

  const PhotoTabView({super.key, required this.employeeId});

  @override
  State<PhotoTabView> createState() => _PhotoTabViewState();
}

class _PhotoTabViewState extends State<PhotoTabView> {
  File? selectedImage;

  @override
  void initState() {
    super.initState();
    debugPrint("PhotoTabView initialized with employeeId: ${widget.employeeId}");
  }

  Future<void> _addPhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(source: ImageSource.gallery);

    if (image != null) {
      setState(() {
        selectedImage = File(image.path);
      });

      _showAddPhotoDialog();
    }
  }

  void _showAddPhotoDialog() {
    final TextEditingController titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Add Photo"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selectedImage != null)
                Image.file(selectedImage!, height: 120, fit: BoxFit.cover), // Smaller preview
              const SizedBox(height: 10),
              TextField(
                controller: titleController,
                decoration: const InputDecoration(
                  labelText: "Title",
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final String title = titleController.text.trim();
                if (title.isEmpty || selectedImage == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please select an image and provide a title.")),
                  );
                  return;
                }

                final String? imageUrl = await _uploadToSupabase(selectedImage!);
                if (imageUrl != null) {
                  await FirebaseFirestore.instance
                      .collection('users')
                      .doc(widget.employeeId)
                      .collection('serviceImages')
                      .add({'url': imageUrl, 'title': title});

                  Navigator.pop(context);
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Failed to upload image.")),
                  );
                }
              },
              child: const Text("Upload"),
            ),
          ],
        );
      },
    );
  }

  Future<String?> _uploadToSupabase(File image) async {
    try {
      final String fileName = 'serviceImages/${DateTime.now().millisecondsSinceEpoch}_${image.path.split('/').last}';
      final SupabaseClient supabase = Supabase.instance.client;

      final storageResponse = await supabase.storage.from('serviceImages').upload(
            fileName,
            image,
            fileOptions: const FileOptions(cacheControl: '3600', upsert: true),
          );

      if (storageResponse.isNotEmpty) {
        final String publicUrl = supabase.storage.from('serviceImages').getPublicUrl(fileName);
        return publicUrl;
      } else {
        debugPrint('Upload failed: No file path returned.');
      }
    } catch (e) {
      debugPrint('Error uploading to Supabase: $e');
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    if (widget.employeeId.isEmpty) {
      return const Center(
        child: Text(
          "Error: Employee ID is missing!",
          style: TextStyle(color: Colors.red, fontSize: 16),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 15),
            Text(
              'Previous Work Photos',
              style: GoogleFonts.montserratAlternates(
                textStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors().grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 10),
            Expanded(
              child: Stack(
                children: [
                  _buildPhotoGallery(),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: FloatingActionButton(
                      onPressed: _addPhoto,
                      backgroundColor: AppColors().orange,
                      child: const Icon(Icons.add, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhotoGallery() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(widget.employeeId)
          .collection('serviceImages')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              "No photos added yet",
              style: TextStyle(color: Colors.grey),
            ),
          );
        }

        return SingleChildScrollView( // ✅ Better than ListView for horizontal images
          scrollDirection: Axis.horizontal,
          child: Row(
            children: snapshot.data!.docs.map((doc) {
              Map<String, dynamic>? data = doc.data() as Map<String, dynamic>?;

              String imageUrl = data?['url'] ??
                  'https://coffective.com/wp-content/uploads/2018/06/default-featured-image.png.jpg';
              String imageTitle = data?['title'] ?? 'Untitled';

              return WorkPhotoCard(
                imageUrl: imageUrl,
                title: imageTitle,
              );
            }).toList(),
          ),
        );
      },
    );
  }
}

// WorkPhotoCard widget
class WorkPhotoCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const WorkPhotoCard({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      width: 180, // ✅ Smaller width
      height: 180, // ✅ Smaller height
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(10),
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Image.network(
              imageUrl,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Text(
                    "Image not found",
                    style: TextStyle(color: Colors.red),
                  ),
                );
              },
            ),
          ),
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              color: Colors.black.withOpacity(0.6),
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
