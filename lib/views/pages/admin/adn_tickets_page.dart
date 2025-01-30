import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:hire_harmony/utils/app_colors.dart';
import 'package:hire_harmony/views/pages/admin/tickets_response_page.dart';

class AdnTicketsPage extends StatelessWidget {
  const AdnTicketsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        extendBodyBehindAppBar: true,
        appBar: AppBar(
          automaticallyImplyLeading: false,
          backgroundColor: AppColors().transparent,
          title: Text(
            'Tickets',
            style: GoogleFonts.montserratAlternates(
              fontSize: 26,
              color: AppColors().white,
              fontWeight: FontWeight.w500,
            ),
          ),
          centerTitle: true,
          bottom: TabBar(
            dividerColor: AppColors().transparent,
            labelColor: AppColors().navy,
            unselectedLabelColor: Colors.white,
            indicatorColor: AppColors().navy,
            labelStyle: const TextStyle(
              fontSize: 16, // Text size for selected tabs
              fontWeight: FontWeight.bold,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14, // Text size for unselected tabs
              fontWeight: FontWeight.normal,
            ),
            tabs: const [
              Tab(text: 'Unresolved'),
              Tab(text: 'Resolved'),
            ],
          ),
        ),
        body: Stack(
          children: [
            // Background Image
            Positioned.fill(
              child: Image.asset(
                'lib/assets/images/notf.jpg',
                fit: BoxFit.cover,
              ),
            ),

            // Blur Filter
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 17.0, sigmaY: 17.0),
                child: Container(
                  color: AppColors().navy.withAlpha(77),
                ),
              ),
            ),

            // Tickets List Tabs
            const TabBarView(
              children: [
                // Unresolved Tickets
                TicketsList(state: 'unresolved', isResolved: false),
                // Resolved Tickets
                TicketsList(state: 'resolved', isResolved: true),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class TicketsList extends StatelessWidget {
  final String state;
  final bool isResolved;

  const TicketsList({super.key, required this.state, required this.isResolved});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('ticketsSent')
          .where('state', isEqualTo: state) // Filter by state
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Text(
              'No ${state == 'resolved' ? 'resolved' : 'unresolved'} tickets found.',
              style: GoogleFonts.montserratAlternates(
                fontSize: 16,
                color: AppColors().white,
                fontWeight: FontWeight.w500,
              ),
            ),
          );
        }

        final tickets = snapshot.data!.docs;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15.0, vertical: 50),
          child: SafeArea(
            child: ListView.builder(
              itemCount: tickets.length,
              padding: const EdgeInsets.all(8.0),
              itemBuilder: (context, index) {
                final ticket = tickets[index];
                final ticketData = ticket.data() as Map<String, dynamic>;

                return Card(
                  elevation: 3,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: ListTile(
                    title: Text(
                      ticketData['description'] ?? 'No description',
                      style: GoogleFonts.montserratAlternates(
                        fontSize: 18,
                        color: AppColors().navy,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "State: ${ticketData['state'] ?? 'Unknown'}",
                          style: GoogleFonts.montserratAlternates(
                            fontSize: 13,
                            color: AppColors().grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Name: ${ticketData['name'] ?? 'Anonymous'}",
                          style: GoogleFonts.montserratAlternates(
                            fontSize: 13,
                            color: AppColors().grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          "Timestamp: ${ticketData['timestamp'] ?? 'N/A'}",
                          style: GoogleFonts.montserratAlternates(
                            fontSize: 13,
                            color: AppColors().grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    trailing:
                        isResolved ? null : const Icon(Icons.arrow_forward_ios),
                    onTap: isResolved
                        ? null
                        : () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => TicketResponsePage(
                                  ticketId: ticket.id,
                                  ticketData: ticketData,
                                ),
                              ),
                            );
                          },
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
