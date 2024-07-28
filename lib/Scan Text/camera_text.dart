import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

class CameraScreen extends StatelessWidget {
  final List<CameraDescription> cameras;

  const CameraScreen({Key? key, required this.cameras}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextRecognitionPage(cameras: cameras);
  }
}

class TextRecognitionPage extends StatefulWidget {
  final List<CameraDescription> cameras;

  const TextRecognitionPage({Key? key, required this.cameras})
      : super(key: key);

  @override
  _TextRecognitionPageState createState() => _TextRecognitionPageState();
}

class _TextRecognitionPageState extends State<TextRecognitionPage> {
  late CameraController _controller;
  late TextRecognizer _textRecognizer;
  String recognizedText = '';
  bool _isScanning = false;
  bool _isCameraActive = true;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
    _textRecognizer = TextRecognizer();
  }

  Future<void> _initializeCamera() async {
    _controller = CameraController(widget.cameras[0], ResolutionPreset.high);
    try {
      await _controller.initialize();
      if (mounted) setState(() {});
    } catch (e) {
      print('Error initializing camera: $e');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _textRecognizer.close();
    super.dispose();
  }

  Future<void> _scanImage() async {
    if (_isScanning) return;
    setState(() {
      _isScanning = true;
    });
    try {
      final image = await _controller.takePicture();
      final inputImage = InputImage.fromFilePath(image.path);
      final recognizedText = await _textRecognizer.processImage(inputImage);
      setState(() {
        this.recognizedText = recognizedText.text;
        _isCameraActive = false;
      });
      _controller.dispose();
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => ResultScreen(
            recognizedText: this.recognizedText,
            onReturnToCamera: _restartCamera,
          ),
        ),
      );
    } finally {
      setState(() {
        _isScanning = false;
      });
    }
  }

  Future<void> _restartCamera() async {
    await _initializeCamera();
    setState(() {
      _isCameraActive = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_controller.value.isInitialized || !_isCameraActive) {
      return Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        appBar: AppBar(
          title: Text('Pengenalan Teks', style: TextStyle(color: Colors.white)),
          backgroundColor: Colors.transparent,
          elevation: 0,
        ),
        body: Center(child: CircularProgressIndicator(color: Colors.white)),
      );
    }
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: Colors.white,
            size: 30,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Memandai Teks', style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.picture_in_picture_outlined, color: Colors.white),
            onPressed: () {
              // Your settings function
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          CameraPreview(_controller),
          Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.all(16),
              child: ElevatedButton(
                onPressed: _isScanning ? null : _scanImage,
                child: Text(
                  _isScanning ? 'Pemindaian..' : 'Memindai',
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueAccent,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  textStyle: TextStyle(fontSize: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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

class ResultScreen extends StatefulWidget {
  final String recognizedText;
  final VoidCallback onReturnToCamera;

  const ResultScreen({
    Key? key,
    required this.recognizedText,
    required this.onReturnToCamera,
  }) : super(key: key);

  @override
  _ResultScreenState createState() => _ResultScreenState();
}

class _ResultScreenState extends State<ResultScreen> {
  late TextEditingController _textEditingController;

  @override
  void initState() {
    super.initState();
    _textEditingController = TextEditingController(text: widget.recognizedText);
  }

  @override
  void dispose() {
    _textEditingController.dispose();
    widget.onReturnToCamera();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E),
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text('Hasil Pemindaian', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color.fromARGB(0, 61, 61, 61),
        elevation: 0,
      ),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: TextField(
                controller: _textEditingController,
                maxLines: null,
                expands: true,
                style: TextStyle(color: Colors.white),
                textAlignVertical: TextAlignVertical
                    .top, // Mengatur teks dimulai dari kiri atas
                decoration: InputDecoration(
                  hintText: 'Teks tidak terdeteksi',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white, width: 2),
                  ),
                  filled: true,
                  fillColor: Colors.blueGrey[900],
                ),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Clipboard.setData(
                    ClipboardData(text: _textEditingController.text));
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Teks disalin',
                        style: TextStyle(color: Colors.white)),
                    backgroundColor: Colors.blueAccent,
                  ),
                );
              },
              child: Text('Salin Teks', style: TextStyle(color: Colors.white)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent,
                padding: EdgeInsets.symmetric(vertical: 16),
                textStyle: TextStyle(fontSize: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
