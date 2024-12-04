import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PinpointMap extends StatefulWidget {
  final String teamId;
  PinpointMap({required this.teamId});

  @override
  _PinpointMapState createState() => _PinpointMapState();
}

class _PinpointMapState extends State<PinpointMap> {
  final List<Map<String, dynamic>> _markers = [];
  LatLng? _currentPin;
  bool _isAddingPin = false;
  TextEditingController _textController = TextEditingController();

  String? _selectedHazardType;
  String? _selectedAlertLevel;

  final List<String> hazardTypes = [
    'Mine Fire',
    'Ventilation',
    'Blasting',
    'Flooding',
    'Collapse of Roof',
    'Equipment Failure',
    'Toxic Gas Leak',
    'Worker Safety',
    'Electrical Hazards',
    'Explosions',
    'Chemical Spills',
    'Overloading',
    'Dust Explosion',
    'Heat Stress',
    'Water Ingress',
  ];

  final List<String> alertLevels = ['Low', 'Medium', 'High'];

  final LatLngBounds imageBounds = LatLngBounds(
    LatLng(-90, -180),
    LatLng(90, 180),
  );

  @override
  void initState() {
    super.initState();
    _loadHazardPins();
  }

  Future<void> _loadHazardPins() async {
    try {
      DocumentSnapshot teamDoc = await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .get();

      if (teamDoc.exists) {
        List<dynamic> alertIds = teamDoc['Alerts'] ?? [];

        for (String alertId in alertIds) {
          DocumentSnapshot hazardDoc = await FirebaseFirestore.instance
              .collection('hazard_reports')
              .doc(alertId)
              .get();

          if (hazardDoc.exists) {
            setState(() {
              _markers.add({
                'id': hazardDoc.id,
                'point': LatLng(hazardDoc['latitude'], hazardDoc['longitude']),
                'text': hazardDoc['note'] ?? "No description",
                'hazardType': hazardDoc['hazardType'] ?? "Unknown",
                'alertLevel': hazardDoc['alertLevel'] ?? "Low",
                'createdBy': hazardDoc['createdBy'] ?? "Unknown",
              });
            });
          }
        }
      }
    } catch (e) {
      print("Error loading hazard pins: $e");
    }
  }

  Future<void> _deleteHazard(String id) async {
    try {
      await FirebaseFirestore.instance
          .collection('hazard_reports')
          .doc(id)
          .delete();

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
        'Alerts': FieldValue.arrayRemove([id]),
      });

      setState(() {
        _markers.removeWhere((marker) => marker['id'] == id);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Hazard point deleted successfully.")),
      );
    } catch (e) {
      print("Error deleting hazard: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error deleting hazard. Please try again.")),
      );
    }
  }

  void _showHazardDetailsDialog(Map<String, dynamic> marker) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user signed in.");
      return;
    }

    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String? fullName;
    if (userSnapshot.exists) {
      fullName =
          '${userSnapshot['firstName']} ${userSnapshot['middleName'] ?? ''} ${userSnapshot['lastName']}';
    } else {
      fullName = '';
    }
    bool canDelete = fullName == marker['createdBy'];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Hazard Details'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hazard Type: ${marker['hazardType']}'),
                Text('Alert Level: ${marker['alertLevel']}'),
                Text('Description: ${marker['text']}'),
                Text('Created By: ${marker['createdBy']}'),
              ],
            ),
          ),
          actions: [
            if (canDelete)
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  _deleteHazard(marker['id']);
                },
                child: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
              ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmPin(LatLng point) async {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      print("No user signed in.");
      return;
    }
    DocumentSnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();

    String? fullName;
    if (userSnapshot.exists) {
      fullName =
          '${userSnapshot['firstName']} ${userSnapshot['middleName'] ?? ''} ${userSnapshot['lastName']}';
    } else {
      fullName = '';
    }

    try {
      DocumentReference hazardRef =
          await FirebaseFirestore.instance.collection('hazard_reports').add({
        'createdBy': fullName,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'note': _textController.text,
        'hazardType': _selectedHazardType,
        'alertLevel': _selectedAlertLevel,
        'createdAt': FieldValue.serverTimestamp(),
      });

      await FirebaseFirestore.instance
          .collection('teams')
          .doc(widget.teamId)
          .update({
        'Alerts': FieldValue.arrayUnion([hazardRef.id]),
      });

      setState(() {
        _markers.add({
          'id': hazardRef.id,
          'point': point,
          'text': _textController.text,
          'hazardType': _selectedHazardType,
          'alertLevel': _selectedAlertLevel,
          'createdBy': fullName,
        });
        _currentPin = null;
        _isAddingPin = false;
        _textController.clear();
      });
    } catch (e) {
      print("Error adding pin: $e");
    }
  }

  void _showPinNoteDialog(LatLng point) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Add a Hazard Pin'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Enter a description for the location:'),
                TextField(
                  controller: _textController,
                  decoration: const InputDecoration(
                    hintText: "Enter text for this location",
                  ),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedHazardType,
                  hint: const Text("Select Hazard Type"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedHazardType = newValue;
                    });
                  },
                  items: hazardTypes.map((hazard) {
                    return DropdownMenuItem<String>(
                      value: hazard,
                      child: Text(hazard),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _selectedAlertLevel,
                  hint: const Text("Select Alert Level"),
                  onChanged: (String? newValue) {
                    setState(() {
                      _selectedAlertLevel = newValue;
                    });
                  },
                  items: alertLevels.map((level) {
                    return DropdownMenuItem<String>(
                      value: level,
                      child: Text(level),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _confirmPin(point);
                Navigator.of(context).pop();
              },
              child: const Text("Confirm"),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(0, 0),
              initialZoom: 2,
              maxZoom: 8,
              minZoom: 2,
              onTap: (tapPosition, point) {
                if (_isAddingPin && imageBounds.contains(point)) {
                  setState(() {
                    _currentPin = point;
                  });
                }
              },
            ),
            children: [
              OverlayImageLayer(
                overlayImages: [
                  OverlayImage(
                    bounds: imageBounds,
                    imageProvider: AssetImage('lib/assets/images/test.png'),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  if (_currentPin != null)
                    Marker(
                      point: _currentPin!,
                      width: 40.0,
                      height: 40.0,
                      child: const Icon(
                        Icons.warning, // Hazard icon
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                  ..._markers.map((hazard) {
                    return Marker(
                      point: hazard['point'],
                      width: 40.0,
                      height: 40.0,
                      child: GestureDetector(
                        onTap: () => _showHazardDetailsDialog(hazard),
                        child: const Icon(
                          Icons.warning, // Hazard icon for existing pins
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }).toList(),
                ],
              ),
            ],
          ),
          if (_isAddingPin && _currentPin != null)
            Positioned(
              bottom: 16.0,
              left: 16.0,
              child: ElevatedButton(
                onPressed: () {
                  if (_currentPin != null) {
                    _showPinNoteDialog(_currentPin!);
                  }
                },
                child: const Text('Confirm Pin'),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          setState(() {
            _isAddingPin = !_isAddingPin;
            _currentPin = null;
          });
        },
        child: Icon(
          _isAddingPin ? Icons.cancel : Icons.add_alert,
          color: Colors.white,
        ),
      ),
    );
  }
}
