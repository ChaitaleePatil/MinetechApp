import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SMPProgressScreen extends StatefulWidget {
  final DocumentSnapshot smp;

  const SMPProgressScreen({super.key, required this.smp});

  @override
  State<SMPProgressScreen> createState() => _SMPProgressScreenState();
}

class _SMPProgressScreenState extends State<SMPProgressScreen> {
  late List<Map<String, dynamic>> steps;
  bool isAdmin = false;
  String? teamId;
  TextEditingController notesController = TextEditingController(); // Controller for notes field

  @override
  void initState() {
    super.initState();

    var stepsData = widget.smp['steps'] ?? [];
    if (stepsData is List) {
      steps = stepsData.map((step) {
        if (step is String) {
          return {
            'name': step,
            'completed': false,
            'completion_date': null, // Initialize with null
            'notes': '',  // Initialize notes as an empty string
          };
        } else if (step is Map) {
          return {
            'name': step['name'] ?? 'Unnamed Step',
            'completed': step['completed'] ?? false,
            'completion_date': step['completion_date'],
            'notes': step['notes'] ?? '', // Safely handle notes
          };
        } else {
          return {'name': 'Invalid step', 'completed': false, 'completion_date': null, 'notes': ''};
        }
      }).toList();
    } else {
      steps = [];
    }

    _checkAdminRole();
    _fetchStepCompletion();
  }

  Future<void> _checkAdminRole() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(currentUser.uid)
            .get();

        if (userSnapshot.exists) {
          List<dynamic> teams = userSnapshot['teams'] ?? [];
          final teamId = widget.smp['team_id'];
          setState(() {
            isAdmin = teams.any((team) =>
                team['teamId'] == teamId && team['role'] == 'admin');
          });
        } else {
          print('User document does not exist.');
        }
      }
    } catch (e) {
      print('Error checking admin role: $e');
    }
  }

  Future<void> _fetchStepCompletion() async {
    try {
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null) {
        final smpId = widget.smp.id;
        final completionDoc = await FirebaseFirestore.instance
            .collection('smp_progress')
            .doc(smpId)
            .get();

        if (completionDoc.exists) {
          final completedSteps = completionDoc['steps'] ?? [];
          setState(() {
            for (int i = 0; i < steps.length; i++) {
              steps[i]['completed'] = completedSteps[i]['completed'] ?? false;
              steps[i]['completion_date'] = completedSteps[i]['completion_date'];
              steps[i]['notes'] = completedSteps[i]['notes'] ?? '';
            }
          });
        }
      }
    } catch (e) {
      print('Error fetching step completion: $e');
    }
  }

  double calculateCompletionProgress() {
    if (steps.isEmpty) return 0;
    int completedSteps = steps.where((step) => step['completed'] == true).length;
    return completedSteps / steps.length;
  }

  void updateStepCompletion(int index, bool isCompleted) {
    setState(() {
      steps[index]['completed'] = isCompleted;
      if (!isCompleted) {
        steps[index]['completion_date'] = null;  // Clear date if uncompleted
      }
    });

    _saveStepCompletion();
  }

  Future<void> _saveStepCompletion() async {
    try {
      final smpId = widget.smp.id;
      final completedSteps = steps.map((step) {
        return {
          'completed': step['completed'],
          'completion_date': step['completion_date'],
          'notes': step['notes'],
        };
      }).toList();

      await FirebaseFirestore.instance
          .collection('smp_progress')
          .doc(smpId)
          .set({
            'steps': completedSteps,
          }, SetOptions(merge: true));

    } catch (e) {
      print('Error saving step completion: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = calculateCompletionProgress();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80.0),
        child: AppBar(
          title: const Text('SMP Progress'),
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
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Circular Progress Indicator
              Center(
                child: Container(
                  width: 200.0,
                  height: 200.0,
                  child: CircularProgressIndicator(
                    value: progress,
                    valueColor: AlwaysStoppedAnimation<Color>(
                        progress == 1 ? Colors.green : Colors.red),
                    strokeWidth: 15.0,
                    backgroundColor: Colors.grey[200],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              // Display SMP details
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
              // Display steps with checkboxes
              const Text('Steps:', style: TextStyle(fontSize: 18)),
              const SizedBox(height: 10),

              // List of steps with checkboxes
              Scrollbar(
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: steps.length,
                  itemBuilder: (context, index) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CheckboxListTile(
                          title: Text('${index + 1}. ${steps[index]['name']}'),
                          value: steps[index]['completed'],
                          onChanged: isAdmin ? (bool? value) {
                            if (value != null) {
                              updateStepCompletion(index, value);
                            }
                          } : null, // Disable interaction if not admin
                        ),
                        const SizedBox(height: 10),
                        // Notes text field for each step
                        TextField(
                          controller: TextEditingController(text: steps[index]['notes']),
                          decoration: const InputDecoration(
                            labelText: 'Add Notes',
                            border: OutlineInputBorder(),
                          ),
                          onChanged: (value) {
                            setState(() {
                              steps[index]['notes'] = value;  // Update the notes for the step
                            });
                          },
                          maxLines: 3, // Allows multiple lines for notes
                        ),
                        const SizedBox(height: 20),
                      ],
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
