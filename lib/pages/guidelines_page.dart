import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart'; // For video functionality
import 'package:audioplayers/audioplayers.dart'; // For audio functionality
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart'; // Updated PDF viewer package

class GuidelinesPage extends StatefulWidget {
  const GuidelinesPage({Key? key}) : super(key: key); // Added key parameter

  @override
  _GuidelinesPageState createState() => _GuidelinesPageState();
}

class _GuidelinesPageState extends State<GuidelinesPage> {
  late AudioPlayer _audioPlayer;
  bool isPlaying = false;
  bool isPaused = false;
  String currentAudioFile = "";

  late VideoPlayerController _videoController;
  bool isVideoPlaying = false;

  final List<String> audioFiles = [
    "Audio1.mp3",
    "Audio2.mp3",
    "Audio3.mp3",
    "Audio4.mp3",
    "Audio5.mp3",
    "Audio6.mp3",
    "Audio7.mp3",
    "Audio8.mp3",
  ];

  final List<String> pdfFiles = [
    "lib/assets/pdfs/CentralElectricity2023.pdf",
    "lib/assets/pdfs/ExplosivesRules2008.pdf",
    "lib/assets/pdfs/MineRegulations1961_13092023.pdf",
    "lib/assets/pdfs/Mines_Creche_Rules-1966.pdf",
    "lib/assets/pdfs/Mines_Rescue_Rules-1985.pdf",
    "lib/assets/pdfs/Mines_Rules_1955.pdf",
    "lib/assets/pdfs/MinesAct1952.pdf",
    "lib/assets/pdfs/MineVocational1966.pdf",
    "lib/assets/pdfs/The_Factories_Act-1948.pdf",
    "lib/assets/pdfs/Coal_Mines_Regulation_2017_Noti.pdf",
    "lib/assets/pdfs/The_Oil_Mines_Regulation_2017.pdf",
  ];

  @override
  void initState() {
    super.initState();

    // Initialize Audio Player
    _audioPlayer = AudioPlayer();

    // Initialize Video Player
    _videoController =
        VideoPlayerController.asset("lib/assets/Videos/guidelines_video.mp4")
          ..initialize().then((_) {
            setState(() {});
          });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void playAudio(String file) async {
    final audioCache = AudioCache(prefix: "lib/assets/Audios/");
    try {
      final url = await audioCache.load(file);
      await _audioPlayer.play(UrlSource(url.path));
      setState(() {
        isPlaying = true;
        currentAudioFile = file;
        isPaused = false;
      });
    } catch (e) {
      print("Error playing audio: $e");
    }
  }

  void pauseAudio() {
    _audioPlayer.pause();
    setState(() {
      isPlaying = false;
      isPaused = true;
    });
  }

  void restartAudio() {
    _audioPlayer.stop();
    playAudio(currentAudioFile);
    setState(() {
      isPaused = false;
      isPlaying = true;
    });
  }

  void playVideo() {
    setState(() {
      isVideoPlaying = true;
    });
    _videoController.play();
  }

  void pauseVideo() {
    setState(() {
      isVideoPlaying = false;
    });
    _videoController.pause();
  }

  void restartVideo() {
    setState(() {
      isVideoPlaying = false;
    });
    _videoController.seekTo(Duration.zero);
    _videoController.play();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Guidelines"),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Expanded(
              child: ListView(
                children: [
                  // Basic Guidelines Section
                  ExpansionTile(
                    title: const Text("Basic Guidelines",
                        style: TextStyle(fontSize: 20)),
                    children: List.generate(4, (index) {
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading:
                              const Icon(Icons.audiotrack, color: Colors.blue),
                          title: Text("Audio Guideline ${index + 1}",
                              style: const TextStyle(fontSize: 18)),
                          trailing: IconButton(
                            icon: Icon(isPlaying &&
                                    currentAudioFile == audioFiles[index]
                                ? Icons.pause
                                : Icons.play_arrow),
                            onPressed: () {
                              if (isPlaying &&
                                  currentAudioFile == audioFiles[index]) {
                                pauseAudio();
                              } else {
                                playAudio(audioFiles[index]);
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),

                  // Advanced Guidelines Section
                  ExpansionTile(
                    title: const Text("Advanced Guidelines",
                        style: TextStyle(fontSize: 20)),
                    children: List.generate(4, (index) {
                      return Card(
                        elevation: 4,
                        margin: const EdgeInsets.symmetric(vertical: 8),
                        child: ListTile(
                          leading:
                              const Icon(Icons.audiotrack, color: Colors.blue),
                          title: Text("Audio Guideline ${index + 5}",
                              style: const TextStyle(fontSize: 18)),
                          trailing: IconButton(
                            icon: Icon(isPlaying &&
                                    currentAudioFile == audioFiles[index + 4]
                                ? Icons.pause
                                : Icons.play_arrow),
                            onPressed: () {
                              if (isPlaying &&
                                  currentAudioFile == audioFiles[index + 4]) {
                                pauseAudio();
                              } else {
                                playAudio(audioFiles[index + 4]);
                              }
                            },
                          ),
                        ),
                      );
                    }),
                  ),

                  // Tile Format for Open PDFs and Guidelines Video
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    children: [
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.all(8),
                        child: InkWell(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    PdfViewerPage(pdfFiles: pdfFiles),
                              ),
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.picture_as_pdf,
                                  size: 50, color: Colors.blue),
                              const SizedBox(height: 10),
                              const Text("Open PDFs",
                                  style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                      Card(
                        elevation: 4,
                        margin: const EdgeInsets.all(8),
                        child: InkWell(
                          onTap: () {
                            playVideo();
                            showDialog(
                              context: context,
                              builder: (context) {
                                return AlertDialog(
                                  title: const Text("Guidelines Video"),
                                  content: AspectRatio(
                                    aspectRatio: 16 / 9,
                                    child: VideoPlayer(_videoController),
                                  ),
                                  actions: [
                                    TextButton(
                                      onPressed: () {
                                        pauseVideo();
                                        Navigator.of(context).pop();
                                      },
                                      child: const Text("Close"),
                                    ),
                                  ],
                                );
                              },
                            );
                          },
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.video_library,
                                  size: 50, color: Colors.blue),
                              const SizedBox(height: 10),
                              const Text("Guidelines Video",
                                  style: TextStyle(fontSize: 18)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class PdfViewerPage extends StatelessWidget {
  final List<String> pdfFiles;

  const PdfViewerPage({Key? key, required this.pdfFiles}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Viewer"),
        backgroundColor: Colors.blue,
      ),
      body: ListView.builder(
        itemCount: pdfFiles.length,
        itemBuilder: (context, index) {
          return Card(
            elevation: 4,
            child: ListTile(
              title: Text("PDF Document ${index + 1}"),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        PdfViewer(pdfFile: "${pdfFiles[index]}"),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class PdfViewer extends StatelessWidget {
  final String pdfFile;

  const PdfViewer({Key? key, required this.pdfFile}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("PDF Viewer"),
        backgroundColor: Colors.blue,
      ),
      body: SfPdfViewer.asset(pdfFile),
    );
  }
}
