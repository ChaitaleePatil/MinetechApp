import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:math';
import '../pages/home_page.dart'; // Import the HomePage

class CreateTeamDialog extends StatefulWidget {
  @override
  _CreateTeamDialogState createState() => _CreateTeamDialogState();
}

class _CreateTeamDialogState extends State<CreateTeamDialog> {
  final TextEditingController teamNameController = TextEditingController();
  final TextEditingController teamDescriptionController =
      TextEditingController();

  String? selectedPosition;
  String? selectedShiftTiming;

  // List of positions and shift timings
  final List<String> positions = [
    "Miner",
    "Roof Bolter",
    "Shuttle Car Operator",
    "Beltman",
    "Electrician",
    "Mechanic",
    "Ventilation Technician",
    "Surveyor",
    "Mining Engineer",
    "Geologist",
    "Environmental Specialist",
    "Safety Inspector",
    "Equipment Operator",
    "Maintenance Technician",
    "Truck Driver",
    "Office Staff",
    "Shift Supervisor",
    "Mine Manager"
  ];

  final List<String> shiftTimings = ["Morning", "Evening", "Night"];

  Future<String> generateUniqueTeamCode() async {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    Random random = Random();
    String teamCode;

    do {
      teamCode = String.fromCharCodes(Iterable.generate(
          6, (_) => chars.codeUnitAt(random.nextInt(chars.length))));
    } while (await FirebaseFirestore.instance
        .collection('teams')
        .doc(teamCode)
        .get()
        .then((doc) => doc.exists));

    return teamCode;
  }

  void createTeam() async {
    final teamName = teamNameController.text.trim();
    final teamDescription = teamDescriptionController.text.trim();
    final userId = FirebaseAuth.instance.currentUser!.uid;

    if (teamName.isEmpty ||
        teamDescription.isEmpty ||
        selectedPosition == null ||
        selectedShiftTiming == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final teamCode = await generateUniqueTeamCode();

      // Create team in Firestore with an empty 'requests' array and 'members' array with the admin
      await FirebaseFirestore.instance.collection('teams').doc(teamCode).set({
        'name': teamName,
        'description': teamDescription,
        'adminId': userId, // Store admin's user ID
        'members': [
          userId
        ], // Add the user as the first member with the admin role
        'requests': [], // Initialize the 'requests' array as an empty array
      });

      // Update the user's teams array with the current team info
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'teams': FieldValue.arrayUnion([
          {
            'teamId': teamCode, // Store teamId (teamCode)
            'jobTitle': selectedPosition, // Store position as jobTitle
            'workHours': selectedShiftTiming, // Store shift timing as workHours
            'role': 'admin', // Admin role
          }
        ]),
      });

      // Navigate to the HomePage with the teamId (teamCode)
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) =>
              HomePage(teamId: teamCode), // Pass teamId to HomePage
        ),
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Team created successfully!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Create Team'),
      titleTextStyle: TextStyle(
          color: Colors.blue[400], fontSize: 25, fontWeight: FontWeight.w700),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Team Name
            TextField(
              controller: teamNameController,
              decoration: InputDecoration(
                labelText: 'Team Name',
                labelStyle: TextStyle(
                    color: Colors.blue[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w300), // Changed to blue
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.blue[400]!), // Bottom border color
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors
                          .blue[600]!), // Bottom border color when focused
                ),
              ),
            ),
            // Team Description
            TextField(
              controller: teamDescriptionController,
              decoration: InputDecoration(
                labelText: 'Team Description',
                labelStyle: TextStyle(
                    color: Colors.blue[400],
                    fontSize: 16,
                    fontWeight: FontWeight.w300), // Changed to blue
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.blue[400]!), // Bottom border color
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors
                          .blue[600]!), // Bottom border color when focused
                ), // Changed to blue
              ),
            ),
            // Position Dropdown
            DropdownButtonFormField<String>(
              value: selectedPosition,
              hint: Text(
                'Select Your Position',
                style: TextStyle(
                    color: Colors.blue[400],
                    fontWeight: FontWeight.w300), // Set text color here
              ),
              items: positions.map((position) {
                return DropdownMenuItem<String>(
                  value: position,
                  child: Text(
                    position,
                    style: TextStyle(
                        color: Colors.blue[400]), // Set text color here
                  ),
                );
              }).toList(),
              onChanged: (value) {
                // Handle change
                setState(() {
                  selectedPosition = value;
                });
              },
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.blue[400]!), // Bottom border color
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors
                          .blue[600]!), // Bottom border color when focused
                ),
              ),
              style: TextStyle(color: Colors.blue[400]),
            ),
            // Shift Timing Dropdown
            DropdownButtonFormField<String>(
              value: selectedShiftTiming,
              hint: Text(
                'Select Your Shift Timing',
                style: TextStyle(
                    color: Colors.blue[400],
                    fontWeight: FontWeight.w300), // Hint text color
              ),
              items: shiftTimings.map((shift) {
                return DropdownMenuItem<String>(
                  value: shift,
                  child: Text(
                    shift,
                    style:
                        TextStyle(color: Colors.blue[400]), // Item text color
                  ),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  selectedShiftTiming = value;
                });
              },
              decoration: InputDecoration(
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors.blue[400]!), // Bottom border color
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                      color: Colors
                          .blue[600]!), // Bottom border color when focused
                ),
              ),
              style: TextStyle(color: Colors.blue[400]), // Default text color
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: createTeam,
          child: Text(
            'Create',
            style: TextStyle(
              color: Colors.blue[400],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(
            'Cancel',
            style: TextStyle(
              color: Colors.blue[400],
              fontSize: 16,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ],
    );
  }
}
