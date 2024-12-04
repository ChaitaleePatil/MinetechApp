import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SMPDetailScreen extends StatefulWidget {
  final DocumentSnapshot smp;

  const SMPDetailScreen({super.key, required this.smp});

  @override
  _SMPDetailScreenState createState() => _SMPDetailScreenState();
}

class _SMPDetailScreenState extends State<SMPDetailScreen> {
  bool isAdmin = false; // Track if the user is an admin

  @override
  void initState() {
    super.initState();
    _checkAdminRole(); // Check if the current user is an admin
  }

  // Function to check if the current user is an admin in the correct team
  Future<void> _checkAdminRole() async {
  try {
    final currentUser = FirebaseAuth.instance.currentUser;

    if (currentUser != null) {
      // Fetch the user document from Firestore to check their teams and roles
      final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(currentUser.uid) // Get the current user document
          .get();

      if (userSnapshot.exists) {
        // Get the list of teams associated with the user
        List<dynamic> teams = userSnapshot['teams'] ?? [];

        // Fetch the SMP document to get the teamId
        final teamId = widget.smp['team_id']; // Get teamId from SMP request document

        // Check if the user is in the correct team with role 'admin'
        setState(() {
          isAdmin = teams.any((team) =>
              team['teamId'] == teamId && team['role'] == 'admin'); // Match teamId and role
        });
      } else {
        print('User document does not exist.');
      }
    }
  } catch (e) {
    print('Error checking admin role: $e');
  }
}

  // Function to approve the SMP
  Future<void> _approveSMP(BuildContext context) async {
    try {
      // Update the status in the `smp_requests` collection
      await FirebaseFirestore.instance
          .collection('smp_requests')
          .doc(widget.smp.id)
          .update({'status': 'approved'});

      // Add the SMP to the `smp_approval` collection
      await FirebaseFirestore.instance
          .collection('smp_approval')
          .doc(widget.smp.id)
          .set(widget.smp.data() as Map<String, dynamic>);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('SMP approved and added to the approval list!')),
      );

      // Navigate back or refresh the parent screen
      Navigator.pop(context, 'approved');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error approving SMP: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Debugging line
    print('SMP Detail Screen Loaded. Status: ${widget.smp['status']}');
    print('Is Admin: $isAdmin'); // Debugging line

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          title: const Text('SMP Details'),
          backgroundColor: Colors.white,
          elevation: 0,
          titleTextStyle: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0),
            child: Container(
              color: Colors.black,
              height: 1.0,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white,
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoText('Exact Hazard:', widget.smp['exact_hazard'] ?? 'Not provided'),
              _buildInfoText('Hazard Category:', widget.smp['hazard_category'] ?? 'Not provided'),
              _buildInfoText('Mitigation Days:', widget.smp['mitigation_days']?.toString() ?? 'Not provided'),
              _buildInfoText('Risk Score:', widget.smp['risk_score']?.toString() ?? 'Not provided'),
              const SizedBox(height: 16),
              const Text(
                'Steps:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              (widget.smp['steps'] ?? []).isEmpty
                  ? const Text(
                      'No steps provided.',
                      style: TextStyle(fontSize: 16, color: Colors.black),
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        (widget.smp['steps'] ?? []).length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '${index + 1}. ${widget.smp['steps'][index]}',
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
              const Divider(color: Colors.grey, height: 32),
              _buildInfoText('Manager:', widget.smp['manager'] ?? 'Not provided'),
              _buildInfoText(
                'Timestamp:',
                widget.smp['timestamp'] != null ? widget.smp['timestamp'].toDate().toString() : 'Not provided',
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: widget.smp['status'] == 'Pending' && isAdmin
          ? Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton(
                onPressed: () => _approveSMP(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 16.0),
                  textStyle: const TextStyle(fontSize: 18),
                ),
                child: const Text('Approve'),
              ),
            )
          : null,
    );
  }

  Widget _buildInfoText(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Text(
            '$label ',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.black,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
