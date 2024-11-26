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

      // Add request to teamRequests collection with only teamId and userId (IDs only)
      final requestDocRef =
          await FirebaseFirestore.instance.collection('teamRequests').add({
        'teamId': teamCode, // Just the team ID, not the full path
        'userId': userId, // Just the user ID, not the full path
        'position': selectedPosition,
        'shiftTiming': selectedShiftTiming,
        'status': 'pending',
      });

      // Log request creation for debugging
      print('Request document created with ID: ${requestDocRef.id}');

      // Add the request document ID to the team's 'requests' list
      await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamCode)
          .update({
        'requests':
            FieldValue.arrayUnion([requestDocRef.id]), // Add the request doc ID
      }).then((_) {
        print('Request ID added to team $teamCode requests array.');
      }).catchError((error) {
        print('Error adding request ID to requests array: $error');
        throw error;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Join request sent successfully!')),
      );
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error sending join request: $e')),
      );
      print('Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Join Team'),
      titleTextStyle: TextStyle(
          color: Colors.blue[400], fontSize: 25, fontWeight: FontWeight.w700),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: teamCodeController,
            decoration: InputDecoration(
              labelText: 'Enter Team Code',
              labelStyle: TextStyle(
                  color: Colors.blue[400],
                  fontSize: 16,
                  fontWeight: FontWeight.w300), // Changed to blue
              enabledBorder: UnderlineInputBorder(
                borderSide:
                    BorderSide(color: Colors.blue[400]!), // Bottom border color
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color:
                        Colors.blue[600]!), // Bottom border color when focused
              ),
            ),
            style: TextStyle(color: Colors.blue[400]),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedPosition,
            hint: Text(
              'Select Position',
              style: TextStyle(
                  color: Colors.blue[400],
                  fontWeight: FontWeight.w300), // Set text color here
            ),
            items: positions.map((position) {
              return DropdownMenuItem<String>(
                value: position,
                child: Text(
                  position,
                  style:
                      TextStyle(color: Colors.blue[400]), // Set text color here
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
                borderSide:
                    BorderSide(color: Colors.blue[400]!), // Bottom border color
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color:
                        Colors.blue[600]!), // Bottom border color when focused
              ),
            ),
            style: TextStyle(color: Colors.blue[400]),
          ),
          SizedBox(height: 10),
          DropdownButtonFormField<String>(
            value: selectedShiftTiming,
            hint: Text(
              'Select Shift Timing',
              style: TextStyle(
                  color: Colors.blue[400],
                  fontWeight: FontWeight.w300), // Hint text color
            ),
            items: shiftTimings.map((shift) {
              return DropdownMenuItem<String>(
                value: shift,
                child: Text(
                  shift,
                  style: TextStyle(color: Colors.blue[400]), // Item text color
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
                borderSide:
                    BorderSide(color: Colors.blue[400]!), // Bottom border color
              ),
              focusedBorder: UnderlineInputBorder(
                borderSide: BorderSide(
                    color:
                        Colors.blue[600]!), // Bottom border color when focused
              ),
            ),
            style: TextStyle(color: Colors.blue[400]), // Default text color
          ),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: submitJoinRequest,
          child: Text(
            'Request to Join',
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
