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
      MineMapTab(),
      ProfileTab(), // Profile Tab with the Logout button
    ];

    return Scaffold(
      appBar: AppBar(title: Text('Home')),
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
class HomeTab extends StatelessWidget {
  final String teamId; // Receive the teamId

  HomeTab({required this.teamId});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Welcome to your Home Page!', style: TextStyle(fontSize: 20)),
          Text(
            'The Team joining code is $teamId',
            style: TextStyle(color: Colors.amber[800]),
          ),
          SizedBox(height: 20),
          Card(
            elevation: 5,
            child: ListTile(
              leading: Icon(Icons.group),
              title: Text('View Team'),
              trailing: Icon(Icons.arrow_forward),
              onTap: () async {
                try {
                  // Fetch the current user's team details from Firestore
                  final userId = FirebaseAuth.instance.currentUser!.uid;
                  DocumentSnapshot userDoc = await FirebaseFirestore.instance
                      .collection('users')
                      .doc(userId)
                      .get();

                  // Ensure the user is part of at least one team
                  if (userDoc.exists &&
                      userDoc['teams'] != null &&
                      userDoc['teams'].isNotEmpty) {
                    List<dynamic> teams = userDoc['teams'] ?? [];

                    // Find the team object matching the passed teamId
                    var team = teams.firstWhere(
                      (t) => t['teamId'] == teamId,
                      orElse: () => null,
                    );

                    if (team != null) {
                      // Navigate to the Team Members Page
                      print(teamId);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamMembersScreen(
                            teamId: teamId,
                          ),
                        ),
                      );
                    } else {
                      // Show a message if the teamId is not found
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Team not found.')),
                      );
                    }
                  } else {
                    // Show a message if the user is not part of any team
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('You are not part of any team.')),
                    );
                  }
                } catch (e) {
                  // Handle errors if any
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
                print(teamId);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => SafetyManagementScreen(
                      teamId: teamId,
                    ), // Navigate to CreateSMP screen
                  ),
                );
              },
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
  @override
  Widget build(BuildContext context) {
    return PinpointMap();
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
                // Handle any errors during logout
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error logging out: $e')),
                );
              }
            },
            child: Text('Logout'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white, // Corrected color property
              padding: EdgeInsets.symmetric(horizontal: 40, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
