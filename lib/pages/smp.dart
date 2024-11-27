// ignore_for_file: avoid_print, sort_child_properties_last

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'create_smp.dart';
import 'pending_smp.dart'; // Import the SMPDetailScreen (Pending status)
import 'smp_progress.dart'; // Import the SMPProgressScreen (Approved status)

class SafetyManagementScreen extends StatefulWidget {
  const SafetyManagementScreen({super.key});

  @override
  State<SafetyManagementScreen> createState() => _SafetyManagementScreenState();
}

class _SafetyManagementScreenState extends State<SafetyManagementScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Lists to store the SMPs for each status
  List<DocumentSnapshot> pendingSMPs = [];
  List<DocumentSnapshot> approvedSMPs = [];
  List<DocumentSnapshot> completedSMPs = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    fetchSMPs(); // Fetch SMPs when the screen is initialized
  }

  Future<void> fetchSMPs() async {
    try {
      final QuerySnapshot smpSnapshot =
          await FirebaseFirestore.instance.collection('smp_requests').get();

      setState(() {
        // Clear the lists before adding new data
        pendingSMPs = [];
        approvedSMPs = [];
        completedSMPs = [];

        // Sort SMPs into their respective categories based on status
        for (var doc in smpSnapshot.docs) {
          print('Document ID: ${doc.id}, Data: ${doc.data()}');

          if (doc.exists && doc.data() != null) {
            var status = doc['status'];
            var riskScore = doc['risk_score'];

            if (status != null && status is String && riskScore is num) {
              if (status == 'Pending') {
                pendingSMPs.add(doc);
              } else if (status == 'Approved') {
                approvedSMPs.add(doc);
              } else if (status == 'Completed') {
                completedSMPs.add(doc);
              }
            } else {
              print('Invalid data for document ID: ${doc.id}');
            }
          } else {
            print('Document ${doc.id} does not exist or has no data');
          }
        }

        pendingSMPs.sort((a, b) => (b['risk_score'] ?? 0).compareTo(a['risk_score'] ?? 0));
        approvedSMPs.sort((a, b) => (b['risk_score'] ?? 0).compareTo(a['risk_score'] ?? 0));
        completedSMPs.sort((a, b) => (b['risk_score'] ?? 0).compareTo(a['risk_score'] ?? 0));
      });
    } catch (e) {
      print('Error fetching SMPs: $e');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Set the entire screen background to white
      appBar: AppBar(
        title: const Text('Safety Management Plans'),
        backgroundColor: Colors.white, // Set AppBar background to white
        foregroundColor: Colors.black, // Set AppBar text color to black
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pending'),
            Tab(text: 'Approved'),
            Tab(text: 'Completed'),
          ],
          labelColor: Colors.black, // Color for the label of selected tab
          unselectedLabelColor: Colors.black, // Color for unselected tabs
          indicatorColor: Colors.black,
          
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Pending tab
          _buildTabView(pendingSMPs, 'No pending safety plans.', Icons.hourglass_empty, Colors.orange),

          // Approved tab
          _buildTabView(approvedSMPs, 'No approved safety plans.', Icons.check_circle, Colors.green),

          // Completed tab
          _buildTabView(completedSMPs, 'No completed safety plans.', Icons.done_all, Colors.blue),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateSMP()),
          );
        },
        tooltip: 'Create New SMP',
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.black,
      ),
    );
  }

  // Function to build tab view with pull-to-refresh functionality
  Widget _buildTabView(List<DocumentSnapshot> smps, String emptyMessage, IconData icon, Color color) {
    return RefreshIndicator(
      onRefresh: () async {
        await fetchSMPs(); // Re-fetch SMPs when the user pulls to refresh
      },
      child: smps.isEmpty
          ? ListView(
              // Add a ListView to allow pull-to-refresh even when the list is empty
              children: [
                Center(
                  heightFactor: 10, // To center the content vertically
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 80, color: color),
                      const SizedBox(height: 10),
                      Text(emptyMessage, style: const TextStyle(fontSize: 16)),
                    ],
                  ),
                ),
              ],
            )
          : ListView.builder(
              itemCount: smps.length,
              itemBuilder: (context, index) {
                final smp = smps[index];
                return Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.black), // Add a border between SMPs
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ListTile(
                    title: Text(smp['hazard_category'] ?? 'No category'),
                    subtitle: Text('Status: ${smp['status']}'),
                    onTap: () {
                      if (smp['status'] == 'Approved') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SMPProgressScreen(smp: smp),
                          ),
                        );
                      } else {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SMPDetailScreen(smp: smp),
                          ),
                        );
                      }
                    },
                  ),
                );
              },
            ),
    );
  }
}
