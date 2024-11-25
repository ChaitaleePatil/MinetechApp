import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class JoinTeamDialog extends StatefulWidget {
  @override
  _JoinTeamDialogState createState() => _JoinTeamDialogState();
}

class _JoinTeamDialogState extends State<JoinTeamDialog> {
  final TextEditingController teamCodeController = TextEditingController();
  String? selectedPosition;
  String? selectedShiftTiming;

  final List<String> positions = [
    'Manager',
    'Shift Incharge',
    'Mine Sardar',
    'Miner'
  ];
  final List<String> shiftTimings = ['Morning', 'Evening', 'Night'];

  void submitJoinRequest() async {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final teamCode = teamCodeController.text.trim();

    if (teamCode.isEmpty ||
        selectedPosition == null ||
        selectedShiftTiming == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      // Validate team code
      final teamSnapshot = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamCode)
          .get();

      if (!teamSnapshot.exists) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Invalid team code')),
        );
        return;
      }

      // Add request to teamRequests collection
      await FirebaseFirestore.instance.collection('teamRequests').add({
        'teamId':
            FirebaseFirestore.instance.collection('teams').doc(teamCode).path,
        'userId':
            FirebaseFirestore.instance.collection('users').doc(userId).path,
        'position': selectedPosition,
        'shiftTiming': selectedShiftTiming,
        'status': 'pending',
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join request sent successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending join request: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Join Team'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: teamCodeController,
            decoration: InputDecoration(labelText: 'Enter Team Code'),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedPosition,
            hint: Text('Select Position'),
            items: positions.map((position) {
              return DropdownMenuItem<String>(
                value: position,
                child: Text(position),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedPosition = value;
              });
            },
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedShiftTiming,
            hint: Text('Select Shift Timing'),
            items: shiftTimings.map((shift) {
              return DropdownMenuItem<String>(
                value: shift,
                child: Text(shift),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                selectedShiftTiming = value;
              });
            },
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: submitJoinRequest,
          child: Text('Request to Join'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancel'),
        ),
      ],
    );
  }
}
