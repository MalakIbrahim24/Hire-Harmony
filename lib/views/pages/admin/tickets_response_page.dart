import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/services/auth_services.dart';
import 'package:hire_harmony/utils/app_colors.dart';

class TicketResponsePage extends StatefulWidget {
  final String ticketId;
  final Map<String, dynamic> ticketData;

  const TicketResponsePage({
    super.key,
    required this.ticketId,
    required this.ticketData,
  });

  @override
  State<TicketResponsePage> createState() => _TicketResponsePageState();
}

class _TicketResponsePageState extends State<TicketResponsePage> {
  final TextEditingController _responseController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitResponse() async {
    if (_responseController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response cannot be empty')),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final response = _responseController.text.trim();
      final AuthServices authServices = AuthServicesImpl();
      final String adminUid = authServices.getCurrentUser()?.uid ?? '';
      if (adminUid.isEmpty) return;

      final DocumentSnapshot adminSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(adminUid)
          .get();

      // Update the ticket document with the response and state
      await FirebaseFirestore.instance
          .collection('ticketsSent')
          .doc(widget.ticketId)
          .update({
        'response': response,
        'hero': adminSnapshot['name'],
        'state': 'resolved',
      });
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Response submitted successfully!')),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error submitting response: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'Respond to Ticket',
          style: GoogleFonts.montserratAlternates(
            fontSize: 20,
            color: AppColors().navy,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(
                height: 20,
              ),
              Text(
                "Ticket Details",
                style: GoogleFonts.montserratAlternates(
                  fontSize: 17,
                  color: AppColors().grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Description: ${widget.ticketData['description']}",
                style: GoogleFonts.montserratAlternates(
                  fontSize: 15,
                  color: AppColors().grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Name: ${widget.ticketData['name']}",
                style: GoogleFonts.montserratAlternates(
                  fontSize: 15,
                  color: AppColors().grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "State: ${widget.ticketData['state']}",
                style: GoogleFonts.montserratAlternates(
                  fontSize: 15,
                  color: AppColors().grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Timestamp: ${widget.ticketData['timestamp']}",
                style: GoogleFonts.montserratAlternates(
                  fontSize: 15,
                  color: AppColors().grey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 200),
              TextField(
                controller: _responseController,
                decoration: InputDecoration(
                  labelText: "Enter your response",
                  labelStyle: GoogleFonts.montserratAlternates(
                    fontSize: 14,
                    color: AppColors().navy,
                    fontWeight: FontWeight.w500,
                  ),
                  border: InputBorder.none,
                ),
                style: GoogleFonts.montserratAlternates(
                  fontSize: 14,
                  color: AppColors().navy,
                  fontWeight: FontWeight.w500,
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Center(
                child: ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStateProperty.all(AppColors().orange),
                  ),
                  onPressed: _isLoading ? null : _submitResponse,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : Text(
                          "Submit Response",
                          style: GoogleFonts.montserratAlternates(
                            fontSize: 14,
                            color: AppColors().white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
