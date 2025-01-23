import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart' as supabase;

class AddServicePage extends StatefulWidget {
  const AddServicePage({super.key});

  @override
  State<AddServicePage> createState() => _AddServicePageState();
}

class _AddServicePageState extends State<AddServicePage> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  File? _selectedImage;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _uploadService() async {
    if (_selectedImage == null ||
        _titleController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please fill all fields and select an image.')),
      );
      return;
    }

    try {
      final fileName =
          '${DateTime.now().millisecondsSinceEpoch}_${_selectedImage!.path.split('/').last}';

      // Upload image to Supabase
      final String filePath = await supabase.Supabase.instance.client.storage
          .from('serviceImages')
          .upload('services/$fileName', _selectedImage!);

      // Get public URL
      final imageUrl = supabase.Supabase.instance.client.storage
          .from('serviceImages')
          .getPublicUrl(filePath.replaceFirst('serviceImages/', ''));

      // Save advertisement details in Firestore
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('services')
            .add({
          'name': _titleController.text,
          'description': _descriptionController.text,
          'image': imageUrl,
        });

        // ignore: use_build_context_synchronously
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Service added successfully!')),
        );
        // ignore: use_build_context_synchronously
        Navigator.pop(context);
      }
    } catch (e) {
      debugPrint('Error uploading service: $e');
      // ignore: use_build_context_synchronously
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to upload seervice.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors().white,
      appBar: AppBar(
        title: const Text("Add Service"),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: _selectedImage == null
                    ? Container(
                        height: 150,
                        width: double.infinity,
                        color: Colors.grey.shade200,
                        child: const Icon(Icons.add_a_photo, size: 50),
                      )
                    : Image.file(
                        _selectedImage!,
                        height: 150,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Title'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description'),
                maxLines: 3,
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: _uploadService,
                child: const Text("Add Service"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
