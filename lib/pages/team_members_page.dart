import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamMembersScreen extends StatelessWidget {
  final String teamId;

  TeamMembersScreen({required this.teamId});

  // Function to fetch team members using both the team document and user documents
  Future<List<Map<String, dynamic>>> _fetchTeamMembers() async {
    try {
      DocumentSnapshot teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();

      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      List<dynamic> memberIds = teamDoc['members'] ?? [];
      QuerySnapshot userSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .where(FieldPath.documentId, whereIn: memberIds)
          .get();

      List<Map<String, dynamic>> members = [];
      for (var userDoc in userSnapshot.docs) {
        final data = userDoc.data() as Map<String, dynamic>;
        final teams = data['teams'] as List<dynamic>? ?? [];
        final teamData = teams.firstWhere(
          (team) => team['teamId'] == teamId,
          orElse: () => null,
        );

        if (teamData != null) {
          members.add({
            'fullName':
                '${data['firstName']} ${data['middleName'] ?? ''} ${data['lastName']}',
            'jobtitle': teamData['jobTitle'],
            'workinghours': teamData['workHours'],
            'userId': userDoc.id, // Add userId to identify the user
          });
        }
      }

      return members;
    } catch (e) {
      print('Error fetching team members: $e');
      return [];
    }
  }

  // Function to accept the join request
  Future<void> _acceptRequest(String requestId, String userId) async {
    try {
      // Fetch the request document
      DocumentSnapshot requestDoc = await FirebaseFirestore.instance
          .collection('teamRequests')
          .doc(requestId)
          .get();

      if (!requestDoc.exists) {
        throw Exception('Request not found');
      }

      // Get request details
      final requestData = requestDoc.data() as Map<String, dynamic>;
      final position = requestData['position'];
      final shiftTiming = requestData['shiftTiming'];

      // Update the team document to add the userId to the members array
      await FirebaseFirestore.instance.collection('teams').doc(teamId).update({
        'members': FieldValue.arrayUnion(
            [userId]), // Add userId to the team members array
        'requests': FieldValue.arrayRemove(
            [requestId]) // Remove the requestId from the requests array
      });

      // Update the user's teams array
      await FirebaseFirestore.instance.collection('users').doc(userId).update({
        'teams': FieldValue.arrayUnion([
          {
            'jobTitle': position,
            'role': 'member', // Set role to 'member'
            'teamId': teamId,
            'workHours': shiftTiming,
          }
        ])
      });

      // Show success message
      print('Request accepted successfully!');
    } catch (e) {
      print('Error accepting request: $e');
    }
  }

  // Function to fetch join requests
  Future<List<Map<String, dynamic>>> _fetchJoinRequests() async {
    try {
      DocumentSnapshot teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(teamId)
          .get();

      if (!teamDoc.exists) {
        throw Exception('Team not found');
      }

      List<dynamic> requestIds = teamDoc['requests'] ?? [];
      QuerySnapshot requestSnapshot = await FirebaseFirestore.instance
          .collection('teamRequests')
          .where(FieldPath.documentId, whereIn: requestIds)
          .get();

      List<Map<String, dynamic>> requests = [];
      for (var requestDoc in requestSnapshot.docs) {
        final requestData = requestDoc.data() as Map<String, dynamic>;
        final userId = requestData['userId'];
        final position = requestData['position'];
        final shiftTiming = requestData['shiftTiming'];

        // Fetch the requesting user's details
        DocumentSnapshot userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;
          requests.add({
            'userId': userId,
            'fullName':
                '${userData['firstName']} ${userData['middleName'] ?? ''} ${userData['lastName']}',
            'position': position,
            'shiftTiming': shiftTiming,
            'userDocId': requestDoc.id // Store the request document ID
          });
        }
      }

      return requests;
    } catch (e) {
      print('Error fetching join requests: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: Text('Team Members'),
          bottom: TabBar(
            tabs: [
              Tab(text: 'Members'),
              Tab(text: 'Join Requests'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Team members tab
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchTeamMembers(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No members found for this team.'));
                }

                final members = snapshot.data!;
                return ListView.builder(
                  itemCount: members.length,
                  itemBuilder: (context, index) {
                    final member = members[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(member['fullName']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Job Title: ${member['jobtitle']}'),
                            Text('Working Hours: ${member['workinghours']}'),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),

            // Join requests tab
            FutureBuilder<List<Map<String, dynamic>>>(
              future: _fetchJoinRequests(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                } else if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                  return Center(child: Text('No join requests.'));
                }

                final requests = snapshot.data!;
                return ListView.builder(
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final request = requests[index];
                    return Card(
                      margin: EdgeInsets.all(8),
                      child: ListTile(
                        contentPadding: EdgeInsets.all(16),
                        title: Text(request['fullName']),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Position: ${request['position']}'),
                            Text('Shift Timing: ${request['shiftTiming']}'),
                          ],
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            IconButton(
                              icon: Icon(Icons.check),
                              onPressed: () async {
                                await _acceptRequest(
                                    request['userDocId'], request['userId']);
                              },
                            ),
                            IconButton(
                              icon: Icon(Icons.cancel),
                              onPressed: () async {
                                // Handle rejection (not implemented)
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
