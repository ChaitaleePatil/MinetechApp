import 'dart:io';
import 'package:flutter/material.dart';
import 'package:minetech_project/pages/const.dart';
import 'package:record/record.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:open_file/open_file.dart';
import 'package:deepgram_speech_to_text/deepgram_speech_to_text.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore _firestore = FirebaseFirestore.instance;

class ShiftLogScreen extends StatefulWidget {
  final String teamId;
  const ShiftLogScreen({required this.teamId});

  @override
  _ShiftLogScreenState createState() => _ShiftLogScreenState();
}

class _ShiftLogScreenState extends State<ShiftLogScreen> {
  final TextEditingController _textController = TextEditingController();
  final AudioRecorder _audioRecorder = AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _formKey = GlobalKey<FormState>();
  String? _selectedRecipientId;
  bool _isRecording = false;
  List<Map<String, dynamic>> _users = [];
  String? _recordedFilePath;
  String? _generatedPdfPath;
  bool _isPlaying = false;
  bool _isUploading = false;
  Duration _audioDuration = Duration.zero;
  Duration _currentPosition = Duration.zero;
  String _shiftType = 'Day';
  List<String> _shiftTypes = ['Day', 'Night', 'Morning', 'Evening'];
  final SupabaseClient _supabaseClient = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    fetchUsers();
  }

  void fetchUsers() async {
    try {
      DocumentSnapshot snapshot =
          await _firestore.collection('teams').doc(widget.teamId).get();

      List<String> userIds = List<String>.from(snapshot['members'] ?? []);
      List<Map<String, dynamic>> users = [];

      for (String userId in userIds) {
        DocumentSnapshot userSnapshot =
            await _firestore.collection('users').doc(userId).get();

        if (userSnapshot.exists) {
          Map<String, dynamic> userData =
              userSnapshot.data() as Map<String, dynamic>;

          String? jobTitleForCurrentTeam;
          if (userData['teams'] != null && userData['teams'] is List) {
            for (var team in userData['teams']) {
              if (team is Map<String, dynamic> &&
                  team['teamId'] == widget.teamId) {
                jobTitleForCurrentTeam = team['jobTitle'];
                break;
              }
            }
          }

          userData['jobTitle'] = jobTitleForCurrentTeam;
          userData['userId'] = userId;
          users.add(userData);
        }
      }

      setState(() {
        _users = users;
      });
    } catch (e) {
      print("Error fetching users: $e");
    }
  }

  Future<void> _generatePdfReport() async {
    DocumentSnapshot userSnapshot =
        await _firestore.collection('users').doc(_selectedRecipientId).get();
    final pdf = pw.Document();

    String transcribedText = await transcribeAudio(_recordedFilePath) ??
        'No transcription available';

    pdf.addPage(
      pw.MultiPage(
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Text('Shift Log Report',
                style:
                    pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Table(
            border: pw.TableBorder.all(),
            children: [
              pw.TableRow(children: [
                pw.Text('Date',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(DateTime.now().toLocal().toString().split(' ')[0]),
              ]),
              pw.TableRow(children: [
                pw.Text('Recipient',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(
                    "${userSnapshot['firstName']} ${userSnapshot['middleName']} ${userSnapshot['lastName']}"),
              ]),
              pw.TableRow(children: [
                pw.Text('Shift Type',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text(_shiftType),
              ]),
            ],
          ),
          pw.SizedBox(height: 20),
          pw.Text('Shift Notes:',
              style:
                  pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.Paragraph(text: transcribedText),
        ],
      ),
    );

    try {
      final directory = await getApplicationDocumentsDirectory();
      final outputFile = File(
          '${directory.path}/shift_log_report_${DateTime.now().millisecondsSinceEpoch}.pdf');
      await outputFile.writeAsBytes(await pdf.save());
      setState(() {
        _generatedPdfPath = outputFile.path;
      });
      print('PDF saved to ${outputFile.path}');
      _uploadToSupabase();
    } catch (e) {
      print('Error saving PDF: $e');
      _showErrorSnackBar('Error saving PDF: $e');
    }
  }

  Future<String> transcribeAudio(String? audioFilePath) async {
    if (audioFilePath == null) return 'No audio file available';
    final apiKey = key; // Add your Deepgram API key here
    Deepgram deepgram = Deepgram(apiKey, baseQueryParams: {
      'model': 'nova-2-general',
      'detect_language': true,
      'filler_words': false,
      'punctuation': true,
    });

    try {
      File audioFile = File(audioFilePath);
      DeepgramSttResult result = await deepgram.transcribeFromFile(audioFile);
      return result.transcript ?? 'Transcription failed';
    } catch (e) {
      print('Error transcribing audio: $e');
      return 'Error transcribing audio';
    }
  }

  Future<void> _viewPdf() async {
    if (_generatedPdfPath != null) {
      try {
        await OpenFile.open(_generatedPdfPath!);
      } catch (e) {
        _showErrorSnackBar('Failed to open PDF: $e');
      }
    } else {
      _showErrorSnackBar('Please generate a PDF first');
    }
  }

  Future<void> _uploadToSupabase() async {
    if (_generatedPdfPath == null && _recordedFilePath == null) {
      _showErrorSnackBar('No files to upload');
      return;
    }

    setState(() {
      _isUploading = true;
    });

    try {
      final reportStorage =
          _supabaseClient.storage.from('media-storage/reports');
      final audioStorage = _supabaseClient.storage.from('media-storage/audio');
      final timestamp = DateTime.now().millisecondsSinceEpoch;

      String? pdfUrl;
      String? audioUrl;

      if (_generatedPdfPath != null) {
        final pdfFile = File(_generatedPdfPath!);
        final pdfFileName = 'shift_log_$timestamp.pdf';
        await reportStorage.upload(pdfFileName, pdfFile,
            fileOptions: const FileOptions(upsert: true));
        final pdfFileUrl = reportStorage.getPublicUrl(pdfFileName);
        pdfUrl = pdfFileUrl.toString();
        print('PDF URL: $pdfUrl');
      }

      if (_recordedFilePath != null) {
        final audioFile = File(_recordedFilePath!);
        final audioFileName = 'shift_log_audio_$timestamp.m4a';
        await audioStorage.upload(audioFileName, audioFile,
            fileOptions: const FileOptions(upsert: true));
        final audioFileUrl = audioStorage.getPublicUrl(audioFileName);
        audioUrl = audioFileUrl.toString();
        print('Audio URL: $audioUrl');
      }

      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        await _firestore.collection('ShiftLogs').add({
          'audioURL': audioUrl ?? '',
          'createdBy': user.uid,
          'pdfURL': pdfUrl ?? '',
          'recipient': _selectedRecipientId,
          'teamID': widget.teamId,
          'textMessage': _textController.text,
          'timestamp': FieldValue.serverTimestamp(),
        });
        _showSuccessSnackBar('Data saved to Firestore successfully');
      } else {
        _showErrorSnackBar('User is not logged in');
      }

      if (pdfUrl != null) {
        _showSuccessSnackBar(
            'PDF uploaded successfully. Download URL: $pdfUrl');
      }
      if (audioUrl != null) {
        _showSuccessSnackBar(
            'Audio uploaded successfully. Download URL: $audioUrl');
      }
    } catch (e) {
      _showErrorSnackBar('Upload failed: $e');
    } finally {
      setState(() {
        _isUploading = false;
      });
    }
  }

  Future<void> _startRecording() async {
    if (await _audioRecorder.hasPermission()) {
      final directory = await getExternalStorageDirectory();
      final filePath =
          '${directory?.path}/shift_log_${DateTime.now().millisecondsSinceEpoch}.m4a';

      await _audioRecorder.start(
        const RecordConfig(encoder: AudioEncoder.aacLc, bitRate: 128000),
        path: filePath,
      );

      setState(() {
        _isRecording = true;
        _recordedFilePath = filePath;
      });
    } else {
      _showErrorSnackBar('Microphone permission is required');
    }
  }

  Future<void> _stopRecording() async {
    if (_isRecording) {
      await _audioRecorder.stop();
      setState(() {
        _isRecording = false;
      });
    }
  }

  String formatDate(DateTime date) {
    final day = date.day;
    final suffix = (day % 10 == 1 && day != 11)
        ? 'st'
        : (day % 10 == 2 && day != 12)
            ? 'nd'
            : (day % 10 == 3 && day != 13)
                ? 'rd'
                : 'th';
    final monthNames = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December'
    ];
    final month = monthNames[date.month - 1];
    final year = date.year;

    return '$day$suffix $month, $year';
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: const Text('Shift Log'),
      //   centerTitle: true,
      // ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 60,
            ),
            const Text(
              'Shift Log',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              '${formatDate(DateTime.now())}',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                const Text(
                  'To:',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _selectedRecipientId,
                    decoration: const InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(),
                    ),
                    hint: const Text('Select Recipient'),
                    onChanged: (String? value) {
                      setState(() {
                        _selectedRecipientId = value;
                      });
                    },
                    items: _users.map((user) {
                      return DropdownMenuItem<String>(
                        value: user['userId'],
                        child: Text("${user['firstName']} ${user['lastName']}"),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Center(
              child: GestureDetector(
                onTap: _isRecording ? _stopRecording : _startRecording,
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue,
                  child: Icon(
                    _isRecording ? Icons.stop : Icons.mic,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _textController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: 'Write about shift if preferred',
                border: OutlineInputBorder(),
                fillColor: Colors.grey[200],
                filled: true,
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: ElevatedButton(
                onPressed: _isUploading
                    ? null
                    : _generatePdfReport, // Disable button during upload
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(200, 50),
                ),
                child: _isUploading
                    ? CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      )
                    : const Text('Send'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
