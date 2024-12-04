import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'create_smp.dart';
import 'pending_smp.dart'; // Import the SMPDetailScreen (Pending status)
import 'smp_progress.dart'; // Import the SMPProgressScreen (Approved status)

class SafetyManagementScreen extends StatefulWidget {
  final String teamId;

  const SafetyManagementScreen({required this.teamId});

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
  bool isAdmin = false; // Track if the user is an admin

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    checkAdminRole(); // Check the user's role
    fetchSMPs(); // Fetch SMPs when the screen is initialized
  }

  Future<void> checkAdminRole() async {
    try {
      // Query Firestore to check if the current user is an admin for the team
      final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('team_id', isEqualTo: widget.teamId)
          .where('role', isEqualTo: 'admin')
          .get();

      // Debugging: Log user role results
      print("Admin check results: ${userSnapshot.docs}");

      setState(() {
        isAdmin = userSnapshot.docs.isNotEmpty;
      });

      print("Is Admin? $isAdmin for teamId ${widget.teamId}");
    } catch (e) {
      print('Error checking admin role: $e');
    }
  }

  Future<void> fetchSMPs() async {
    try {
      // Query Firestore for SMPs belonging to the user's team that are "Pending"
      final QuerySnapshot smpSnapshot = await FirebaseFirestore.instance
          .collection('smp_requests')
          .where('team_id', isEqualTo: widget.teamId)
          .where('status', isEqualTo: 'Pending')
          .get();

      // Query Firestore for SMPs in smp_approval
      final QuerySnapshot smpApprovalSnapshot = await FirebaseFirestore.instance
          .collection('smp_approval')
          .where('team_id', isEqualTo: widget.teamId)
          .get();

      // Query Firestore for SMPs in smp_completed
      final QuerySnapshot smpCompletedSnapshot = await FirebaseFirestore.instance
          .collection('smp_completed')
          .where('team_id', isEqualTo: widget.teamId)
          .get();

      // Create a set of approved SMP IDs to filter out from the pending SMPs
      final Set<String> approvedSmpIds =
          smpApprovalSnapshot.docs.map((doc) => doc.id).toSet();

      setState(() {
        // Clear the lists before adding new data
        pendingSMPs = [];
        approvedSMPs = [];
        completedSMPs = [];

        // Filter out approved SMPs from the pending list
        for (var doc in smpSnapshot.docs) {
          if (!approvedSmpIds.contains(doc.id)) {
            pendingSMPs.add(doc);
          }
        }

        // Fetch approved SMPs
        approvedSMPs = smpApprovalSnapshot.docs;

        // Fetch completed SMPs
        completedSMPs = smpCompletedSnapshot.docs;
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
          _buildTabView(
            pendingSMPs,
            'No pending safety plans.',
            Icons.hourglass_empty,
            Colors.orange,
          ),

          // Approved tab
          _buildTabView(
            approvedSMPs,
            'No approved safety plans.',
            Icons.check_circle,
            Colors.green,
            isApproved: true,
          ),

          // Completed tab
          _buildTabView(
            completedSMPs,
            'No completed safety plans.',
            Icons.done_all,
            Colors.blue,
            isCompleted: true,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => CreateSMP(teamId: widget.teamId),
            ),
          );
        },
        tooltip: 'Create New SMP',
        child: const Icon(Icons.add, color: Colors.white),
        backgroundColor: Colors.black,
      ),
    );
  }

  // Function to build tab view with pull-to-refresh functionality
  Widget _buildTabView(
    List<DocumentSnapshot> smps,
    String emptyMessage,
    IconData icon,
    Color color, {
    bool isApproved = false,
    bool isCompleted = false, // New flag for completed tab
  }) {
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
                    border: Border.all(color: Colors.black), // Add border
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: ListTile(
                    title: Text(smp['hazard_category'] ?? 'No category'),
                    subtitle: Text(smp['exact_hazard']),
                    trailing: isCompleted
                        ? null
                        : (isApproved
                            ? null
                            : (isAdmin
                                ? ElevatedButton(
                                    onPressed: () async {
                                      try {
                                        // Move to smp_approval collection
                                        await FirebaseFirestore.instance
                                            .collection('smp_approval')
                                            .doc(smp.id)
                                            .set(smp.data()
                                                as Map<String, dynamic>);

                                        // Remove from smp_requests
                                        await FirebaseFirestore.instance
                                            .collection('smp_requests')
                                            .doc(smp.id)
                                            .delete();

                                        setState(() {
                                          pendingSMPs.removeAt(index);
                                        });
                                      } catch (e) {
                                        print('Error moving SMP to approval: $e');
                                      }
                                    },
                                    child: const Text('Approve'),
                                  )
                                : null)),
                    onTap: () {
                      if (isCompleted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => SMPDetailScreen(smp: smp),
                          ),
                        );
                      } else if (isApproved) {
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
