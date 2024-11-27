import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:minetech_project/pages/create_smp.dart';
import 'package:minetech_project/pages/map.dart';
import 'package:minetech_project/pages/smp.dart';
import 'team_members_page.dart'; // Import the Team Members Page
import 'login_page.dart'; // Import the Login Page

// HomePage Widget
class HomePage extends StatefulWidget {
  final String
      teamId; // Accept teamId as a parameter in the HomePage constructor

  HomePage({required this.teamId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    // Define the pages for each tab
    final List<Widget> _pages = [
      HomeTab(teamId: widget.teamId), // Pass the teamId to HomeTab
      ReceivedLogsTab(),
      MineMapTab(teamId: widget.teamId),
      ProfileTab(), // Profile Tab with the Logout button
    ];

    return Scaffold(
      body: _pages[_currentIndex], // Display the selected page
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        backgroundColor: Colors.blue.shade50,
        selectedItemColor: Colors.blue[400],
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.receipt),
            label: 'Received Logs',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Mine Map',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

// HomeTab widget with a card that navigates to the Team Members Page
class HomeTab extends StatefulWidget {
  final String teamId; // Receive the teamId

  HomeTab({required this.teamId});

  @override
  _HomeTabState createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _alerts = []; // To store alert data

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  // Fetch alerts from the team document
  Future<void> _fetchAlerts() async {
    try {
      DocumentSnapshot teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();

      if (teamDoc.exists && teamDoc['Alerts'] != null) {
        List<dynamic> reportIds = teamDoc['Alerts']; // List of report IDs

        for (String reportId in reportIds) {
          DocumentSnapshot hazardDoc = await FirebaseFirestore.instance
              .collection('hazard_reports')
              .doc(reportId)
              .get();

          if (hazardDoc.exists) {
            // Handle missing fields gracefully
            setState(() {
              _alerts.add({
                'id': hazardDoc.id,
                'hazardType': hazardDoc['hazardType'] ??
                    'Unknown Hazard Type', // Default to a meaningful hazard type
                'alertLevel': hazardDoc['alertLevel'] ??
                    'Low', // Default to "Low" as a reasonable alert level
                'createdBy': hazardDoc['createdBy'] ??
                    'Unknown Creator', // Default to "Unknown Creator"
                'createdAt': hazardDoc['createdAt'] != null
                    ? (hazardDoc['createdAt'] as Timestamp).toDate()
                    : DateTime
                        .now(), // Default to current date and time if null
                'latitude': hazardDoc['latitude'] ??
                    0.0, // Default to 0.0 (on the equator/prime meridian) if null
                'longitude': hazardDoc['longitude'] ??
                    0.0, // Default to 0.0 (on the equator/prime meridian) if null
                'note': hazardDoc['note'] ??
                    'No additional notes provided', // Default to "No additional notes provided" if null
              });
            });
          }
        }
      }
    } catch (e) {
      print("Error fetching alerts: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(
            height: 150,
          ),
          Text('Welcome to your Home Page!', style: TextStyle(fontSize: 20)),
          Text(
            'The Team joining code is ${widget.teamId}',
            style: TextStyle(color: Colors.amber[800]),
          ),
          SizedBox(height: 30),
          Card(
            elevation: 5,
            child: ListTile(
              leading: Icon(Icons.group),
              title: Text('View Team'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () async {
                try {
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  DocumentSnapshot userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get();

                  if (userDoc.exists &&
                      userDoc['teams'] != null &&
                      userDoc['teams'].isNotEmpty) {
                    List<dynamic> teams = userDoc['teams'] ?? [];

                    var team = teams.firstWhere(
                      (t) => t['teamId'] == widget.teamId,
                      orElse: () => null,
                    );

                    if (team != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamMembersScreen(
                            teamId: widget.teamId,
                          ),
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Team not found.')),
                      );
                    }
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You are not part of any team.')),
                    );
                  }
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Failed to fetch team data: $e')),
                  );
                }
              },
            ),
          ),
          Card(
            elevation: 5,
            child: ListTile(
              leading: Icon(Icons.safety_check),
              title: Text('Create SMP'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        CreateSMP(), // Navigate to CreateSMP screen
                  ),
                );
              },
            ),
          ),
          Card(
            elevation: 5,
            child: ListTile(
              leading: Icon(Icons.safety_check),
              title: Text('SMP'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SafetyManagementScreen(
                      teamId: widget.teamId,
                    ), // Navigate to CreateSMP screen
                  ),
                );
              },
            ),
          ),
          SizedBox(
            height: 30,
          ),
          // The scrollable alerts card, always at the bottom
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: const EdgeInsets.all(8.0),
              child: Card(
                color: Colors.red.shade50, // Light red color for the card
                elevation: 5,
                child: Container(
                  height: 300,
                  width: 375, // Fixed height for the alert card
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Alerts",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                        SizedBox(height: 2),
                        _alerts.isEmpty
                            ? Center(
                                child: Text(
                                  "No Alerts",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.grey[700],
                                  ),
                                ),
                              )
                            : Expanded(
                                child: ListView.builder(
                                  shrinkWrap: true,
                                  itemCount: _alerts.length,
                                  itemBuilder: (context, index) {
                                    var alert = _alerts[index];
                                    return Card(
                                      color: Colors.red.shade100,
                                      elevation: 3,
                                      child: ListTile(
                                        leading:
                                            Icon(Icons.warning_amber_rounded),
                                        title: Text(alert['hazardType']),
                                        subtitle: Text(
                                            'Alert Level: ${alert['alertLevel']}'),
                                        trailing: Icon(Icons.arrow_forward),
                                        onTap: () {
                                          // Show more details in a dialog or navigate to a new screen
                                          showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return AlertDialog(
                                                title: Text('Alert Details'),
                                                content: Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                        'Created by: ${alert['createdBy']}'),
                                                    Text(
                                                        'Created at: ${alert['createdAt']}'),
                                                    Text(
                                                        'Hazard Type: ${alert['hazardType']}'),
                                                    Text(
                                                        'Alert Level: ${alert['alertLevel']}'),
                                                    Text(
                                                        'Latitude: ${alert['latitude']}'),
                                                    Text(
                                                        'Longitude: ${alert['longitude']}'),
                                                    Text(
                                                        'Note: ${alert['note']}'),
                                                  ],
                                                ),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () {
                                                      Navigator.of(context)
                                                          .pop();
                                                    },
                                                    child: Text('Close'),
                                                  ),
                                                ],
                                              );
                                            },
                                          );
                                        },
                                      ),
                                    );
                                  },
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Placeholder tabs
class ReceivedLogsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
        child: Text('Received Logs Page', style: TextStyle(fontSize: 20)));
  }
}

class MineMapTab extends StatelessWidget {
  final String teamId; // Receive the teamId

  MineMapTab({required this.teamId});
  @override
  Widget build(BuildContext context) {
    return PinpointMap(
      teamId: teamId,
    );
  }
}

class ProfileTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Profile Page', style: TextStyle(fontSize: 20)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () async {
              try {
                // Sign out the current user
                await FirebaseAuth.instance.signOut();

                // Navigate to the login page after logout
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              } catch (e) {
                print("Error signing out: $e");
              }
            },
            child: Text('Logout'),
          ),
        ],
      ),
    );
  }
}
