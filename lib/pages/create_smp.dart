// ignore_for_file: avoid_print, use_build_context_synchronously, unused_local_variable

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class CreateSMP extends StatefulWidget {
  const CreateSMP({super.key});

  @override
  State<CreateSMP> createState() => _CreateSMPState();
}

class _CreateSMPState extends State<CreateSMP> {
  String hazardCategory = '';
  String exactHazard = '';
  List<String> steps = [''];
  String mitigationDays = '';
  String manager = '';
  int consequence = 1;
  int exposure = 1;
  int probability = 1;
  int riskScore = 0;
  bool isLoadingManagers = true;
  List<String> managerNames = [];
  List<String> filteredManagerNames = [];

  final List<String> hazardCategories = [
    'Mine Fire',
    'Ventilation',
    'Blasting',
    'Flooding',
    'Collapse of Roof',
    'Equipment Failure',
    'Toxic Gas Leak',
    'Worker Safety Equipment Failure',
    'Electrical Hazards',
    'Explosions',
    'Chemical Spills',
    'Overloading',
    'Dust Explosion',
    'Heat Stress',
    'Water Ingress',
  ];

  @override
  void initState() {
    super.initState();
    fetchManagers();
  }

  // Fetch managers from Firestore
  void fetchManagers() async {
    try {
      final QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .get(); // Get all users

      if (mounted) {
        setState(() {
          managerNames = userSnapshot.docs
              .map((doc) => doc['firstName'] as String)
              .toList();
          filteredManagerNames = List.from(managerNames);
          isLoadingManagers = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          isLoadingManagers = false;
        });
      }
      print('Error fetching users: $e');
    }
  }

  // Filter managers based on search query
  void filterManagers(String query) async {
    setState(() {
      if (query.isEmpty) {
        // If query is empty, show all manager names
        filteredManagerNames = List.from(managerNames);
      } else {
        // If query is not empty, filter the manager names
        filteredManagerNames = managerNames
            .where((name) => name.toLowerCase().contains(query.toLowerCase()))
            .toList();
      }
    });

    // Optionally, query Firestore for more efficient searching when the query is not empty.
    if (query.isNotEmpty) {
      final QuerySnapshot managerSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where('firstName', isGreaterThanOrEqualTo: query)
          .where('firstName', isLessThanOrEqualTo: '$query\uf8ff')
          .get();

      setState(() {
        filteredManagerNames = managerSnapshot.docs
            .map((doc) => doc['firstName'] as String)
            .toList();
      });
    }
  }

  // Calculate risk score
  void calculateRiskScore() {
    setState(() {
      riskScore = consequence * exposure * probability;
    });
  }

  // Handle SMP submission
  void handleSubmit() async {
    print(
        'Submitting SMP: $hazardCategory, $exactHazard, $steps, $riskScore, $mitigationDays, $manager');
    try {
      await FirebaseFirestore.instance.collection('smp_requests').add({
        'hazard_category': hazardCategory,
        'exact_hazard': exactHazard,
        'steps': steps,
        'risk_score': riskScore,
        'mitigation_days': mitigationDays,
        'manager': manager,
        'status': 'Pending',
        'timestamp': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("SMP sent for approval")),
      );
      Navigator.pop(context); // Go back to the previous screen after submission
    } catch (e) {
      print('Error submitting SMP: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Failed to submit SMP")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Adjusting padding and font sizes based on screen size
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;
    double fontSize = screenWidth < 600 ? 14 : 16;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Create SMP'),
        backgroundColor: Colors.white,
      ),
      backgroundColor: Colors.white,
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.05), // Dynamic padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DropdownButtonFormField<String>(
              value: hazardCategory.isEmpty ? null : hazardCategory,
              decoration: InputDecoration(
                labelText: 'Hazard Category',
                labelStyle: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black,
                ),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.black), // Black border when not focused
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.black), // Black border when focused
                ),
              ),
              dropdownColor: Colors.white,
              items: hazardCategories.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(category, style: TextStyle(fontSize: fontSize)),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  hazardCategory = value ?? '';
                });
              },
            ),
            const SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: 'Exact Hazard',
                labelStyle: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black,
                ),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.black), // Black border when not focused
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.black), // Black border when focused
                ),
              ),
              onChanged: (value) => setState(() => exactHazard = value),
            ),
            const SizedBox(height: 15),
            const Text('Steps to mitigate hazard:',
                style: TextStyle(fontSize: 16)),
            for (int i = 0; i < steps.length; i++)
              Padding(
                padding: const EdgeInsets.symmetric(
                    vertical: 8.0), // Add vertical spacing
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          labelText: 'Step ${i + 1}',
                          labelStyle: TextStyle(
                            fontSize: fontSize,
                            color: Colors.black,
                          ),
                          border: const OutlineInputBorder(),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors
                                    .black), // Black border when not focused
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    Colors.black), // Black border when focused
                          ),
                        ),
                        onChanged: (value) {
                          setState(() {
                            steps[i] = value;
                          });
                        },
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Color.fromARGB(255, 234, 24, 9)),
                      onPressed: () => setState(() => steps.removeAt(i)),
                    ),
                  ],
                ),
              ),
            Center(
              child: ElevatedButton(
                onPressed: () => setState(() => steps.add('')),
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Makes the button rectangular
                  ),
                  backgroundColor: const Color.fromARGB(255, 16, 105,
                      179), // Sets the button's background color to blue
                  foregroundColor: Colors.white, // Sets the text color to white
                ),
                child: const Text('Add Step'),
              ),
            ),
            const SizedBox(height: 15),
            const Text(
              'Risk Matrix',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: consequence,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Consequence',
                      labelStyle: TextStyle(
                        fontSize: fontSize,
                        color: Colors.black,
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.black), // Black border when not focused
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.black), // Black border when focused
                      ),
                    ),
                    items: List.generate(10, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text((index + 1).toString(),
                            style: TextStyle(fontSize: fontSize)),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        consequence = value ?? 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: exposure,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Exposure',
                      labelStyle: TextStyle(
                        fontSize: fontSize,
                        color: Colors.black,
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.black), // Black border when not focused
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.black), // Black border when focused
                      ),
                    ),
                    items: List.generate(10, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text((index + 1).toString(),
                            style: TextStyle(fontSize: fontSize)),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        exposure = value ?? 1;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: probability,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.white,
                      labelText: 'Probability',
                      labelStyle: TextStyle(
                        fontSize: fontSize,
                        color: Colors.black,
                      ),
                      border: const OutlineInputBorder(),
                      enabledBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color:
                                Colors.black), // Black border when not focused
                      ),
                      focusedBorder: const OutlineInputBorder(
                        borderSide: BorderSide(
                            color: Colors.black), // Black border when focused
                      ),
                    ),
                    items: List.generate(10, (index) {
                      return DropdownMenuItem(
                        value: index + 1,
                        child: Text((index + 1).toString(),
                            style: TextStyle(fontSize: fontSize)),
                      );
                    }),
                    onChanged: (value) {
                      setState(() {
                        probability = value ?? 1;
                      });
                    },
                  ),
                ),
              ],
            ),
            Center(
              child: ElevatedButton(
                onPressed: calculateRiskScore,
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.zero, // Makes the button rectangular
                  ),
                  backgroundColor: const Color.fromARGB(255, 16, 105,
                      179), // Sets the button's background color to blue
                  foregroundColor: Colors.white, // Sets the text color to white
                ),
                child: const Text('Calculate Risk Score'),
              ),
            ),
            if (riskScore > 0)
              Text(
                'Risk Score: $riskScore',
                style:
                    const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
            const SizedBox(height: 15),
            TextField(
              decoration: InputDecoration(
                labelText: 'Number of days required for mitigation',
                labelStyle: TextStyle(
                  fontSize: fontSize,
                  color: Colors.black,
                ),
                border: const OutlineInputBorder(),
                enabledBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.black), // Black border when not focused
                ),
                focusedBorder: const OutlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.black), // Black border when focused
                ),
              ),
              keyboardType: TextInputType.number,
              onChanged: (value) => setState(() => mitigationDays = value),
            ),
            const SizedBox(height: 15),
            isLoadingManagers
                ? const CircularProgressIndicator()
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        decoration: InputDecoration(
                          labelText: 'Search Manager/Supervisor',
                          labelStyle: TextStyle(
                            fontSize: fontSize,
                            color: Colors.black,
                          ),
                          border: const OutlineInputBorder(),
                          enabledBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color: Colors
                                    .black), // Black border when not focused
                          ),
                          focusedBorder: const OutlineInputBorder(
                            borderSide: BorderSide(
                                color:
                                    Colors.black), // Black border when focused
                          ),
                        ),
                        onChanged: filterManagers,
                      ),
                      const SizedBox(height: 10),
                      filteredManagerNames.isNotEmpty
                          ? DropdownButtonFormField<String>(
                              value: manager.isEmpty ? null : manager,
                              decoration: InputDecoration(
                                labelText: 'Manager/Supervisor for approval',
                                labelStyle: TextStyle(fontSize: fontSize),
                                border: const OutlineInputBorder(),
                              ),
                              items: filteredManagerNames.map((name) {
                                return DropdownMenuItem(
                                  value: name,
                                  child: Text(name,
                                      style: TextStyle(fontSize: fontSize)),
                                );
                              }).toList(),
                              onChanged: (value) {
                                setState(() {
                                  manager = value ?? '';
                                });
                              },
                            )
                          : const Text('No managers found'),
                    ],
                  ),
            const SizedBox(height: 20),
            Center(
              child: ElevatedButton(
                onPressed: handleSubmit,
                style: ElevatedButton.styleFrom(
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.zero, // Rectangular button
                  ),
                  backgroundColor: Colors.black, // Black background
                  foregroundColor: Colors.white, // White text color
                  minimumSize:
                      const Size(200, 50), // Increase the height of the button
                  fixedSize: const Size(
                      300, 50), // Make the width bigger than the other buttons
                ),
                child: const Text('Request Approval'),
              ),
            )
          ],
        ),
      ),
    );
  }
}
