import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

class PinpointMap extends StatefulWidget {
  @override
  _PinpointMapState createState() => _PinpointMapState();
}

class _PinpointMapState extends State<PinpointMap> {
  final List<Map<String, dynamic>> _markers = [];
  LatLng? _draggingMarkerPosition;
  bool _isAddingPin = false;
  TextEditingController _textController = TextEditingController();
  bool _showConfirmButton = false;

  final LatLngBounds imageBounds = LatLngBounds(
    LatLng(-90, -180),
    LatLng(90, 180),
  );

  void _showBoundaryError() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Out of Bounds"),
          content: const Text(
              "You can only add markers within the image boundaries."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
    );
  }

  void _confirmPinLocation(LatLng point) {
    setState(() {
      _showConfirmButton = false;
      _markers.add({
        'point': point,
        'text': _textController.text,
      });
      _textController.clear();
    });
  }

  void _showPinNoteBottomSheet(LatLng point) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true, // Ensures the bottom sheet can adjust size
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Add a Note',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: _textController,
                decoration: const InputDecoration(
                  hintText: "Enter text for this location",
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () {
                      _confirmPinLocation(point);
                      Navigator.of(context).pop();
                    },
                    child: const Text("Confirm"),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset:
          true, // Allow resizing when the keyboard appears
      body: Stack(
        children: [
          // Full white background
          Container(
            color: Colors.white,
          ),
          // FlutterMap with OverlayImage
          FlutterMap(
            options: MapOptions(
              initialCenter: LatLng(0, 0),
              initialZoom: 1,
              maxZoom: 5,
              minZoom: 0,
              onTap: (tapPosition, point) {
                if (_isAddingPin) {
                  if (imageBounds.contains(point)) {
                    setState(() {
                      _draggingMarkerPosition = point;
                      _showConfirmButton =
                          true; // Show the confirm button after placing the pin
                    });
                  } else {
                    _showBoundaryError(); // Show error if outside bounds
                  }
                }
              },
            ),
            children: [
              OverlayImageLayer(
                overlayImages: [
                  OverlayImage(
                    bounds: imageBounds,
                    opacity: 1.0,
                    imageProvider: AssetImage('assets/test.png'),
                  ),
                ],
              ),
              MarkerLayer(
                markers: [
                  // Add regular markers
                  ..._markers.map((marker) {
                    return Marker(
                      point: marker['point'],
                      width: 40.0,
                      height: 40.0,
                      child: GestureDetector(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (BuildContext context) {
                              return AlertDialog(
                                title: const Text("Marker Note"),
                                content:
                                    Text(marker['text'] ?? "No text added"),
                                actions: [
                                  TextButton(
                                    onPressed: () {
                                      Navigator.of(context).pop();
                                    },
                                    child: const Text("Close"),
                                  ),
                                ],
                              );
                            },
                          );
                        },
                        child: const Icon(
                          Icons.location_on,
                          size: 40,
                          color: Colors.red,
                        ),
                      ),
                    );
                  }).toList(),
                  // Conditionally add the draggable marker if adding pin
                  if (_isAddingPin && _draggingMarkerPosition != null)
                    Marker(
                      point: _draggingMarkerPosition!,
                      width: 40.0,
                      height: 40.0,
                      child: const Icon(
                        Icons.pin_drop,
                        size: 40,
                        color: Colors.blue,
                      ),
                    ),
                ],
              ),
            ],
          ),
          // Button to add pin
          Positioned(
            bottom: 16.0,
            right: 16.0,
            child: FloatingActionButton(
              onPressed: () {
                setState(() {
                  _isAddingPin = !_isAddingPin;
                  _draggingMarkerPosition = null;
                  _showConfirmButton = false;
                });
              },
              child: Icon(
                _isAddingPin ? Icons.cancel : Icons.add_location,
                size: 30,
              ),
            ),
          ),
          // Confirm button to confirm the pin location and show a BottomSheet for note
          if (_showConfirmButton && _draggingMarkerPosition != null)
            Positioned(
              bottom: 100.0,
              right: 16.0,
              child: FloatingActionButton(
                onPressed: () {
                  _showPinNoteBottomSheet(_draggingMarkerPosition!);
                },
                child: const Icon(
                  Icons.check,
                  size: 30,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
