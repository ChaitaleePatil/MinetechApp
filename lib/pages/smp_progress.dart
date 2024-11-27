// ignore_for_file: use_build_context_synchronously, avoid_print, sized_box_for_whitespace

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class SMPProgressScreen extends StatefulWidget {
  final DocumentSnapshot smp;

  const SMPProgressScreen({super.key, required this.smp});

  @override
  State<SMPProgressScreen> createState() => _SMPProgressScreenState();
}

class _SMPProgressScreenState extends State<SMPProgressScreen> {
  // Steps and their completion status
  late List<Map<String, dynamic>> steps; // List of steps and their completion status

  @override
  void initState() {
    super.initState();

    // Ensure 'steps' is properly fetched and has the correct type
    var stepsData = widget.smp['steps'] ?? [];

    if (stepsData is List) {
      steps = stepsData.map((step) {
        if (step is String) {
          return {
            'name': step,  // The step name is the string itself
            'completed': false,  // Initialize completion status as false
          };
        } else {
          return {'name': 'Invalid step', 'completed': false};
        }
      }).toList();
    } else {
      steps = []; // Default to an empty list if steps data is invalid
    }
  }

  // Function to calculate the completion percentage
  double calculateCompletionProgress() {
    int completedSteps = steps.where((step) => step['completed'] == true).length;
    return completedSteps / steps.length;
  }

  // Function to update the step completion status
  void updateStepCompletion(int index, bool isCompleted) {
    setState(() {
      steps[index]['completed'] = isCompleted;
    });

    // Check if all steps are completed
    if (steps.every((step) => step['completed'] == true)) {
      // Update the Firestore document to reflect completion
      _markSMPCompleted();
    }
  }

  // Function to update Firestore status to "Completed"
  void _markSMPCompleted() async {
    try {
      await FirebaseFirestore.instance
          .collection('smp_requests')
          .doc(widget.smp.id)  // Get the document by ID
          .update({'status': 'Completed'}); // Update status to "Completed"

      // Optionally, you can show a confirmation snackbar or message to the user
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Safety Management Plan marked as completed')),
      );
    } catch (e) {
      print('Error updating SMP status: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to mark SMP as completed')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = calculateCompletionProgress();

    return Scaffold(
      backgroundColor: Colors.white, // Ensure the entire Scaffold background is white
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0), // Adjust the AppBar height
        child: AppBar(
          title: const Text('SMP Progress'),
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
      body: SingleChildScrollView(  // Wrap the entire body in SingleChildScrollView
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Display the progress wheel with increased size
              Center(
                child: Container(
                  width: 200.0,  // Increased width for the progress wheel
                  height: 200.0, // Increased height for the progress wheel
                  child: CircularProgressIndicator(
                    value: progress,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1 ? Colors.green : Colors.red),
                    strokeWidth: 15.0,  // Increased stroke width for larger wheel
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Display details of the SMP
              Text(
                'Exact Hazard: ${widget.smp['exact_hazard'] ?? 'Not provided'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Hazard Category: ${widget.smp['hazard_category'] ?? 'Not provided'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Mitigation Days: ${widget.smp['mitigation_days'] ?? 'Not provided'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 8),
              Text(
                'Risk Score: ${widget.smp['risk_score'] ?? 'Not provided'}',
                style: const TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),

              // Display the steps with checkboxes
              const Text('Steps:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),

              // Add a Scrollbar widget to the ListView
              Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,  // Allow the ListView to take up only the necessary space
                  physics: const NeverScrollableScrollPhysics(),  // Disable ListView scrolling
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    return CheckboxListTile(
                      title: Text('${index + 1}. ${steps[index]['name']}'), // Numbering the steps
                      value: steps[index]['completed'],
                      onChanged: (bool? value) {
                        if (value != null) {
                          updateStepCompletion(index, value);
                        }
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
