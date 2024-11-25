import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Correct import for FirebaseAuth
import 'home_page.dart'; // Assuming you have a HomePage

class TeamListPage extends StatefulWidget {
  @override
  _TeamListPageState createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Teams')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(FirebaseAuth
                .instance.currentUser!.uid) // Correct reference to FirebaseAuth
            .get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          } else if (snapshot.hasData && snapshot.data!.exists) {
            List teams = snapshot.data!['teams'];

            if (teams.isEmpty) {
              return Center(child: Text('You have not joined any teams.'));
            }

            return ListView.builder(
              itemCount: teams.length,
              itemBuilder: (context, index) {
                var team = teams[index];
                // Fetch the team details from the teams collection
                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('teams')
                      .doc(team[
                          'teamId']) // Assuming 'teamId' is stored in the user document
                      .get(),
                  builder: (context, teamSnapshot) {
                    if (teamSnapshot.connectionState ==
                        ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    } else if (teamSnapshot.hasError) {
                      return Center(
                          child: Text('Error: ${teamSnapshot.error}'));
                    } else if (teamSnapshot.hasData &&
                        teamSnapshot.data!.exists) {
                      var teamData =
                          teamSnapshot.data!.data() as Map<String, dynamic>;
                      return Card(
                        margin:
                            EdgeInsets.symmetric(vertical: 10, horizontal: 15),
                        child: ListTile(
                          title: Text(teamData['name'] ?? 'Unnamed Team'),
                          subtitle: Text('Role: ${team['role']}'),
                          trailing: IconButton(
                            icon: Icon(Icons.info_outline),
                            onPressed: () {
                              _showTeamDetails(context, teamData);
                            },
                          ),
                          onTap: () {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                  builder: (context) =>
                                      HomePage()), // Redirect to HomePage
                            );
                          },
                        ),
                      );
                    } else {
                      return Center(child: Text('Team not found.'));
                    }
                  },
                );
              },
            );
          } else {
            return Center(child: Text('No teams found.'));
          }
        },
      ),
    );
  }

  // Function to show team details in a dialog
  void _showTeamDetails(BuildContext context, Map<String, dynamic> teamData) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(teamData['name'] ?? 'Unnamed Team'),
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                  'Description: ${teamData['description'] ?? 'No description available'}'),
              SizedBox(height: 10),
              // Fetch and display the full name of the admin
              FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(teamData['adminId']) // Fetching admin by adminId
                    .get(),
                builder: (context, adminSnapshot) {
                  if (adminSnapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (adminSnapshot.hasError) {
                    return Text('Error: ${adminSnapshot.error}');
                  } else if (adminSnapshot.hasData &&
                      adminSnapshot.data!.exists) {
                    var adminData =
                        adminSnapshot.data!.data() as Map<String, dynamic>;
                    String fullName =
                        '${adminData['firstName']} ${adminData['middleName']} ${adminData['lastName']}';
                    return Text('Admin: $fullName');
                  } else {
                    return Text('Admin details not found.');
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Close'),
            ),
          ],
        );
      },
    );
  }
}
