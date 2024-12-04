import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:minetech_project/pages/create_smp.dart';
import 'package:minetech_project/pages/guidelines_page.dart';
import 'package:minetech_project/pages/map.dart';
import 'package:minetech_project/pages/received_shift_log_page.dart';
import 'package:minetech_project/pages/smp.dart';
import 'team_members_page.dart'; // Import the Team Members Page
import 'login_page.dart'; // Import the Login Page
import 'shiftlog.dart';
import 'package:intl/intl.dart';

// HomePage Widget
class HomePage extends StatefulWidget {
  String teamId; // Make teamId mutable to update it on team switch

  HomePage({required this.teamId});

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  // Method to update the current team ID
  void _switchTeam(String newTeamId) {
    setState(() {
      widget.teamId = newTeamId;
      _currentIndex = 0; // Reset to HomeTab when switching teams
    });
  }

  @override
  Widget build(BuildContext context) {
    // Define the pages for each tab
    final List<Widget> _pages = [
      HomeTab(teamId: widget.teamId), // Pass the current teamId to HomeTab
      ReceivedLogsTab(
        teamId: widget.teamId,
      ),
      ShiftLogScreen(teamId: widget.teamId),
      MineMapTab(
          teamId: widget.teamId), // Pass the current teamId to MineMapTab
      ProfileTab(
        currentTeamId: widget.teamId, // Pass the current teamId to ProfileTab
        onTeamSwitch: _switchTeam, // Pass the callback to handle team switch
      ),
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
            icon: Icon(Icons.create), // Icon for Shift Log
            label: 'Shift Log',
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
  String? _greetingMessage;
  String? _userName;
  String? _dayName;

  @override
  void initState() {
    super.initState();
    _fetchUserDetails();
    _fetchAlerts();
    _setGreetingAndDay();
  }

  // Fetch user details from Firebase Auth and Firestore
  Future<void> _fetchUserDetails() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userName = userDoc['firstName'] ?? 'User';
        });
      }
    } catch (e) {
      print("Error fetching user details: $e");
    }
  }

  // Set greeting message and day name
  void _setGreetingAndDay() {
    final hour = DateTime.now().hour;
    final dayName = DateFormat('EEEE').format(DateTime.now()); // Get day name

    String greeting;
    if (hour < 12) {
      greeting = "Good Morning";
    } else if (hour < 18) {
      greeting = "Good Afternoon";
    } else {
      greeting = "Good Evening";
    }

    setState(() {
      _greetingMessage = greeting;
      _dayName = dayName;
    });
  }

  // Fetch alerts (existing function remains unchanged)
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
            setState(() {
              _alerts.add({
                'id': hazardDoc.id,
                'hazardType': hazardDoc['hazardType'] ?? 'Unknown Hazard Type',
                'alertLevel': hazardDoc['alertLevel'] ?? 'Low',
                'createdBy': hazardDoc['createdBy'] ?? 'Unknown Creator',
                'createdAt': hazardDoc['createdAt'] != null
                    ? (hazardDoc['createdAt'] as Timestamp).toDate()
                    : DateTime.now(),
                'latitude': hazardDoc['latitude'] ?? 0.0,
                'longitude': hazardDoc['longitude'] ?? 0.0,
                'note': hazardDoc['note'] ?? 'No additional notes provided',
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
    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: 80),
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                "$_greetingMessage, ${_userName ?? 'User'}!",
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          SizedBox(height: 5),
          Align(
              alignment: Alignment.centerLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 16.0),
                child: Text(
                  "Today is $_dayName",
                  style: TextStyle(fontSize: 18, color: Colors.grey[700]),
                ),
              )),
          SizedBox(height: 20),
          // Other widgets like the cards and alerts
          Align(
            alignment: Alignment.centerLeft,
            child: Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: Text(
                'The Team joining code is ${widget.teamId}',
                style: TextStyle(
                  color: Colors.amber[800],
                ),
              ),
            ),
          ),
          SizedBox(height: 30),
          // Your other ListTile and Card widgets remain here

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
                    builder: (context) => CreateSMP(
                        teamId: widget.teamId), // Navigate to CreateSMP screen
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
          Card(
            elevation: 5,
            child: ListTile(
              leading: Icon(Icons.book),
              title: Text('DGMS Guideline'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        GuidelinesPage(), // Navigate to GuidelinesPage
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
                  height: 240,
                  // Fixed height for the alert card
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
  final String teamId;
  const ReceivedLogsTab({required this.teamId});
  @override
  Widget build(BuildContext context) {
    return ReceiveShiftLogPage(
      teamId: teamId,
    ); // Call the ReceiveShiftLogPage class
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

class ProfileTab extends StatefulWidget {
  final String currentTeamId; // Receive the current teamId
  final Function(String) onTeamSwitch; // Callback to switch the team

  ProfileTab({required this.currentTeamId, required this.onTeamSwitch});

  @override
  _ProfileTabState createState() => _ProfileTabState();
}

class _ProfileTabState extends State<ProfileTab> {
  Map<String, dynamic>? _userData;
  List<dynamic> _teams = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  // Fetch user details from Firestore
  Future<void> _fetchUserData() async {
    try {
      final userId = FirebaseAuth.instance.currentUser!.uid;
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .get();

      if (userDoc.exists) {
        setState(() {
          _userData = userDoc.data();
          _teams = _userData?['teams'] ?? [];
          _isLoading = false;
        });
      }
    } catch (e) {
      print("Error fetching user data: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_userData == null) {
      return Center(
        child: Text(
          'Failed to load user data.',
          style: TextStyle(fontSize: 16, color: Colors.red),
        ),
      );
    }

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            height: 50,
          ),
          // Display user details
          Text(
            "Profile Details",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _buildProfileDetail('Name',
              "${_userData?['firstName'] ?? ''} ${_userData?['middleName'] ?? ''} ${_userData?['lastName'] ?? ''}"),
          _buildProfileDetail('Email', _userData?['email'] ?? 'Not Available'),
          SizedBox(height: 20),

          // Display user's teams
          Text(
            "Your Teams",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 10),
          _teams.isEmpty
              ? Text("You are not part of any teams.")
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: _teams.length,
                  itemBuilder: (context, index) {
                    final team = _teams[index];

                    return FutureBuilder<DocumentSnapshot>(
                      future: FirebaseFirestore.instance
                          .collection('teams')
                          .doc(team['teamId'])
                          .get(),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          // Show a loading spinner while fetching data
                          return Center(child: CircularProgressIndicator());
                        } else if (snapshot.hasError) {
                          // Handle errors
                          return Center(
                              child: Text('Error: ${snapshot.error}'));
                        } else if (!snapshot.hasData ||
                            !snapshot.data!.exists) {
                          // Handle case where no data is found
                          return Center(child: Text('Team data not found'));
                        } else {
                          // Data fetched successfully
                          final teamDoc = snapshot.data!;
                          final teamName = teamDoc['name'] ?? 'Unknown Team';

                          return Card(
                            child: ListTile(
                              title: Text(teamName),
                              subtitle: Text("Team ID: ${team['teamId']}"),
                              trailing: widget.currentTeamId == team['teamId']
                                  ? Icon(Icons.check, color: Colors.green)
                                  : null,
                              onTap: () {
                                if (widget.currentTeamId != team['teamId']) {
                                  widget.onTeamSwitch(team['teamId']);
                                }
                              },
                            ),
                          );
                        }
                      },
                    );
                  },
                ),
          SizedBox(height: 20),

          // Logout button
          ElevatedButton(
            onPressed: () async {
              try {
                await FirebaseAuth.instance.signOut();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (context) => LoginPage()),
                );
              } catch (e) {
                print("Error signing out: $e");
              }
            },
            child: Text("Logout"),
          ),
        ],
      ),
    );
  }

  // Helper method to display profile details
  Widget _buildProfileDetail(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Text("$title: ", style: TextStyle(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}
