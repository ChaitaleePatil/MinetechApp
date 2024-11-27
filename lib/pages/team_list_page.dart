import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Correct import for FirebaseAuth
import 'home_page.dart'; // Assuming you have a HomePage
import '../dialogue/create_team.dart'; // Import CreateTeamDialog
import '../dialogue/join_team.dart'; // Import JoinTeamDialog

class TeamListPage extends StatefulWidget {
  @override
  _TeamListPageState createState() => _TeamListPageState();
}

class _TeamListPageState extends State<TeamListPage> {
  void showCreateTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return CreateTeamDialog();
      },
    );
  }

  void showJoinTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        return JoinTeamDialog();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Your Teams')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                ElevatedButton(
                  onPressed: () => showCreateTeamDialog(context),
                  child: Text(
                    'Create Team',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => showJoinTeamDialog(context),
                  child: Text(
                    'Join Team',
                    style: TextStyle(
                      color: Colors.blue[400],
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ),
              ],
            ),
            Expanded(
              child: FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!
                        .uid) // Correct reference to FirebaseAuth
                    .get(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(child: CircularProgressIndicator());
                  } else if (snapshot.hasError) {
                    return Center(child: Text('Error: ${snapshot.error}'));
                  } else if (snapshot.hasData && snapshot.data!.exists) {
                    List teams = snapshot.data!['teams'];

                    if (teams.isEmpty) {
                      return Center(
                          child: Text('You have not joined any teams.'));
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
                              var teamData = teamSnapshot.data!.data()
                                  as Map<String, dynamic>;
                              return Card(
                                margin: EdgeInsets.symmetric(
                                    vertical: 10, horizontal: 15),
                                child: ListTile(
                                  title:
                                      Text(teamData['name'] ?? 'Unnamed Team'),
                                  subtitle: Text('Role: ${team['role']}'),
                                  trailing: IconButton(
                                    icon: Icon(Icons.info_outline),
                                    onPressed: () {
                                      _showTeamDetails(context, teamData);
                                    },
                                  ),
                                  onTap: () {
                                    print('Clicked teamId: ${team['teamId']}');
                                    // Pass the teamId to HomePage
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                          builder: (context) =>
                                              HomePage(teamId: team['teamId'])),
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
            ),
          ],
        ),
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
