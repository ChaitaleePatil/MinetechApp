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

    if (teamName.isEmpty || teamDescription.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill in all fields')),
      );
      return;
    }

    try {
      final teamCode = await generateUniqueTeamCode();

      // Create team in Firestore
      await FirebaseFirestore.instance.collection('teams').doc(teamCode).set({
        'name': teamName,
        'description': teamDescription,
        'adminId': userId, // Store admin's user ID, not reference
        'members': [userId], // Store user ID as a member
      });

      // Add the team to the user's teams array
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'teams': FieldValue.arrayUnion([
          {
            'teamId': teamCode,
            'jobTitle': 'Admin',
            'workHours': 'N/A',
            'role': 'admin',
          }
        ])
      });

      // Navigate to the Home Page after successful team creation
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => HomePage()),
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: teamNameController,
              decoration: InputDecoration(labelText: 'Team Name'),
            ),
            TextField(
              controller: teamDescriptionController,
              decoration: InputDecoration(labelText: 'Team Description'),
            ),
          ],
        ),
      ),
      actions: [
        ElevatedButton(
          onPressed: createTeam,
          child: Text('Create'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
