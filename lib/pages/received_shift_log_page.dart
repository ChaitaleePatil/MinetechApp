// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'dart:async';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'shiftlog.dart'; // Ensure this file exists and is properly implemented.
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth
import 'package:url_launcher/url_launcher.dart';
import 'package:open_file/open_file.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:just_audio/just_audio.dart';
import 'webViewScreen.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class ReceiveShiftLogPage extends StatefulWidget {
  final String teamId;

  const ReceiveShiftLogPage({required this.teamId});

  @override
  _ReceiveShiftLogPageState createState() => _ReceiveShiftLogPageState();
}

class _ReceiveShiftLogPageState extends State<ReceiveShiftLogPage> {
  final audioPlayer = AudioPlayer();
  DateTime currentDateTime = DateTime.now();
  TextEditingController additionalTextController = TextEditingController();
  List<Map<String, dynamic>> sentShiftLogs = [];
  List<Map<String, dynamic>> receivedShiftLogs = [];
  List<Map<String, dynamic>> filteredShiftLogs = [];
  TextEditingController dateController = TextEditingController();
  bool isPlaying = false;

  Timer? _timer;

  // Logged-in user's first name
  String? currentUserFirstName;

  @override
  void initState() {
    super.initState();
    currentDateTime = DateTime.now();
    _startTimer();
    _fetchCurrentUserFirstName(); // Fetch the current user's first name
  }

  // Fetch the current logged-in user's first name
  Future<void> _fetchCurrentUserFirstName() async {
    try {
      User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        DocumentSnapshot userDoc =
            await _firestore.collection('users').doc(user.uid).get();
        setState(() {
          currentUserFirstName = userDoc[
              'firstName']; // Assume firstName field exists in the 'users' collection
        });
        _fetchShiftLogsFromFirestore(); // Fetch shift logs once the first name is fetched
      }
    } catch (e) {
      print("Error fetching user info: $e");
    }
  }

  @override
  void dispose() {
    // Cancel the timer when the widget is disposed
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        currentDateTime = DateTime.now();
      });
    });
  }

  Future<void> _fetchShiftLogsFromFirestore() async {
    User? user = FirebaseAuth.instance.currentUser; // Get the current user
    if (user == null || currentUserFirstName == null) return;

    try {
      // Query Firestore for shift logs that match the teamId
      QuerySnapshot snapshot = await _firestore
          .collection('ShiftLogs')
          .where('teamID', isEqualTo: widget.teamId) // Filter by teamId
          .get();

      // Use `Future.wait` to handle async calls for sender and recipient
      List<Map<String, dynamic>> fetchedLogs = await Future.wait(
        snapshot.docs.map((doc) async {
          Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

          try {
            // Fetch sender and recipient details from the 'users' collection
            DocumentSnapshot senderSnapshot = await _firestore
                .collection('users')
                .doc(data['createdBy'])
                .get();
            DocumentSnapshot recipientSnapshot = await _firestore
                .collection('users')
                .doc(data['recipient'])
                .get();

            Map<String, dynamic> senderData =
                senderSnapshot.data() as Map<String, dynamic>;
            Map<String, dynamic> recipientData =
                recipientSnapshot.data() as Map<String, dynamic>;

            // Explicitly return a Map<String, dynamic>
            return {
              'senderName':
                  "${senderData['firstName'] ?? ''} ${senderData['middleName'] ?? ''} ${senderData['lastName'] ?? ''}"
                      .trim(),
              'recipientName':
                  "${recipientData['firstName'] ?? ''} ${recipientData['middleName'] ?? ''} ${recipientData['lastName'] ?? ''}"
                      .trim(),
              'recipientId': data['recipient'], // Assuming recipientId exists
              'createdBy': data['createdBy'], // Assuming createdBy exists
              'date': (data['timestamp'] as Timestamp)
                  .toDate()
                  .toIso8601String()
                  .split('T')[0],
              'audioUrl': data['audioURL'], // Store the audio URL from Firebase
              'pdfUrl': data['pdfURL'], // Store the PDF URL from Firebase
              'message': data['textMessage'],
            } as Map<String,
                dynamic>; // Explicitly cast to Map<String, dynamic>
          } catch (e) {
            print("Error fetching user data: $e");
            return <String, dynamic>{}; // Return an empty map in case of error
          }
        }).toList(),
      );

      setState(() {
        // Filter received logs where recipientId matches the current user's ID
        receivedShiftLogs = fetchedLogs.where((log) {
          return log['recipient'] == user.uid;
        }).toList();

        // Filter sent logs where createdBy matches the current user's ID
        sentShiftLogs = fetchedLogs.where((log) {
          return log['createdBy'] == user.uid;
        }).toList();

        // Default to showing received logs
        filteredShiftLogs = List.from(receivedShiftLogs);
      });
    } catch (e) {
      print("Error fetching shift logs: $e");
    }
  }

  Future<void> requestPermission() async {
    if (await Permission.manageExternalStorage.request().isGranted) {
      // You now have permission to access external storage
      print('Permission granted');
    } else {
      print('Permission denied');
    }
  }

  Future<void> _openPdf(BuildContext context, String url) async {
    try {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => PdfWebViewScreen(pdfUrl: url),
        ),
      );
    } catch (e) {
      print('Error opening PDF: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  void _filterShiftLogs(String type, String value) {
    setState(() {
      if (value.isEmpty) {
        filteredShiftLogs = List.from(receivedShiftLogs);
      } else {
        filteredShiftLogs = receivedShiftLogs.where((log) {
          switch (type) {
            case 'date':
              return log['date'] == value;
            case 'person':
              return log['recipientName']?.contains(value) ?? false;
            case 'position':
              return log['position']?.contains(value) ?? false;
            default:
              return false;
          }
        }).toList();
      }
    });
  }

  void _showShiftLogDetails(Map<String, dynamic> shiftLog) {
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text(
                'Shift Log Details',
                style: TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.blue,
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name: ${shiftLog['senderName'] ?? shiftLog['recipientName']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                  Text('Position: ${shiftLog['position']}',
                      style: const TextStyle(color: Colors.white)),
                  Text('Date: ${shiftLog['date']}',
                      style: const TextStyle(color: Colors.white)),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      if (isPlaying) {
                        // Stop playback
                        await audioPlayer.stop();
                        setState(() {
                          isPlaying = false;
                        });
                      } else {
                        // Start playback
                        final String url = shiftLog['audioUrl'];
                        try {
                          await audioPlayer.setUrl(url);
                          audioPlayer.play();
                          setState(() {
                            isPlaying = true;
                          });
                        } catch (e) {
                          print('Error playing audio: $e');
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Error playing audio: $e')),
                          );
                        }
                      }
                    },
                    child: Text(
                      isPlaying ? 'Stop Audio' : 'Play Audio',
                      style: const TextStyle(color: Colors.blue),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                    onPressed: () async {
                      final String? url = shiftLog['pdfUrl'];
                      if (url != null) {
                        await _openPdf(context, url);
                      } else {
                        print('Could not find PDF URL');
                      }
                    },
                    child: const Text(
                      'View PDF',
                      style: TextStyle(color: Colors.blue),
                    ),
                  ),
                  Text(
                    'Message: ${shiftLog['message']}',
                    style: const TextStyle(color: Colors.white),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    audioPlayer.stop(); // Stop audio if playing
                    Navigator.pop(context);
                  },
                  child: const Text('Close',
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _launchUrl(String url) async {
    final Uri uri = Uri.parse(url);
    print('Attempting to launch: $uri');

    try {
      if (await canLaunchUrl(uri)) {
        // Attempt to launch the URL
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        print('Cannot launch URL: $url');
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Unable to open PDF.')));
      }
    } catch (e) {
      print('Error launching URL: $e');
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: currentDateTime,
      firstDate: DateTime(2000),
      lastDate: DateTime(2101),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Colors.blue,
              onPrimary: Colors.white,
              onSurface: Colors.blue,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate != null && pickedDate != currentDateTime) {
      setState(() {
        currentDateTime = pickedDate;
        dateController.text = "${pickedDate.toLocal()}".split(' ')[0];
        _filterShiftLogs('date', dateController.text);
      });
    }
  }

  // Function to navigate to the create shift log page
  void _navigateToCreateShiftLogPage() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (context) => ShiftLogScreen(
                teamId: widget.teamId,
              )),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shift Logs'),
        backgroundColor: Colors.blue,
        elevation: 4.0,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter by: ',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      _buildFilterTextField(
                          'Date', 'Filter by Date (YYYY-MM-DD)', (value) {
                        _filterShiftLogs('date', value);
                      }),
                      const SizedBox(width: 12),
                      _buildFilterTextField('Person', 'Filter by Person',
                          (value) {
                        _filterShiftLogs('person', value);
                      }),
                      const SizedBox(width: 12),
                      _buildFilterTextField('Position', 'Filter by Position',
                          (value) {
                        _filterShiftLogs('position', value);
                      }),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Sent Logs Section
                  _buildSectionTitle('Sent Logs:'),
                  const SizedBox(height: 10),
                  _buildShiftLogsList(sentShiftLogs),

                  const SizedBox(height: 20),

                  // Received Logs Section
                  _buildSectionTitle('Received Logs:'),
                  const SizedBox(height: 10),
                  _buildShiftLogsList(receivedShiftLogs),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateShiftLogPage,
        child: const Icon(Icons.add),
        backgroundColor: Colors.blue,
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.blue,
      ),
    );
  }

  Widget _buildFilterTextField(
      String label, String hintText, Function(String) onChanged) {
    return Expanded(
      child: TextField(
        controller: label == 'Date' ? dateController : additionalTextController,
        decoration: InputDecoration(
          labelText: label,
          hintText: hintText,
          border: OutlineInputBorder(),
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildShiftLogsList(List<Map<String, dynamic>> logs) {
    return ListView.builder(
      shrinkWrap: true,
      itemCount: logs.length,
      itemBuilder: (context, index) {
        final shiftLog = logs[index];
        return Card(
          color: Colors.blue[50],
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(
              '${shiftLog['senderName']}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text('Date: ${shiftLog['date']}'),
            trailing: IconButton(
              icon: const Icon(Icons.info),
              onPressed: () => _showShiftLogDetails(shiftLog),
            ),
          ),
        );
      },
    );
  }
}
