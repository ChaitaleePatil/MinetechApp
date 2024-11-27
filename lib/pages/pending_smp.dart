import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SMPDetailScreen extends StatelessWidget {
  final DocumentSnapshot smp;

  const SMPDetailScreen({super.key, required this.smp});

  @override
  Widget build(BuildContext context) {
    // Extract necessary data from the DocumentSnapshot with type checks
    final exactHazard = smp['exact_hazard'] ?? 'Not provided';
    final hazardCategory = smp['hazard_category'] ?? 'Not provided';

    // If mitigation_days and risk_score are integers or doubles, convert them to string
    final mitigationDays = smp['mitigation_days']?.toString() ?? 'Not provided';
    final riskScore = smp['risk_score']?.toString() ?? 'Not provided';

    // Ensure that steps is a list of strings, using an empty list as fallback
    final steps = List<String>.from(smp['steps'] ?? []);

    return Scaffold(
      backgroundColor: Colors.white, // Ensure the entire Scaffold background is white
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0), // Adjust the AppBar height
        child: AppBar(
          title: const Text('SMP Details'),
          backgroundColor: Colors.white, // White background for AppBar
          elevation: 0, // No shadow
          titleTextStyle: const TextStyle(
            color: Colors.black, // Black text color for AppBar title
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(1.0), // Border thickness
            child: Container(
              color: Colors.black, // Black border at the bottom of AppBar
              height: 1.0,
            ),
          ),
        ),
      ),
      body: Container(
        color: Colors.white, // Ensure the body container background is white
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView( // Ensures content scrolls if it's too long
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildInfoText('Exact Hazard:', exactHazard),
              _buildInfoText('Hazard Category:', hazardCategory),
              _buildInfoText('Mitigation Days:', mitigationDays),
              _buildInfoText('Risk Score:', riskScore),
              const SizedBox(height: 16),
              const Text(
                'Steps:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
              ),
              const SizedBox(height: 8),
              // Display steps if any, otherwise show "No steps provided"
              steps.isEmpty
                  ? const Text('No steps provided.', style: TextStyle(fontSize: 16, color: Colors.black))
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(
                        steps.length,
                        (index) => Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Text(
                            '${index + 1}. ${steps[index]}', // Numbering steps
                            style: const TextStyle(fontSize: 16, color: Colors.black),
                          ),
                        ),
                      ),
                    ),
              const Divider(color: Colors.grey, height: 32),
              _buildInfoText('Manager:', smp['manager'] ?? 'Not provided'),
              _buildInfoText('Timestamp:', 
                  smp['timestamp'] != null
                      ? smp['timestamp'].toDate().toString()
                      : 'Not provided'),
            ],
          ),
        ),
      ),
    );
  }

  // Helper function to build key-value pairs of information
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
              overflow: TextOverflow.ellipsis, // Handles long text gracefully
            ),
          ),
        ],
      ),
    );
  }
}
