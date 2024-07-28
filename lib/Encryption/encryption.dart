import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:path_provider/path_provider.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:external_path/external_path.dart';

class FileCryptoApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'File Crypto',
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.teal,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: FileCryptoScreen(),
    );
  }
}

class FileCryptoScreen extends StatefulWidget {
  @override
  _FileCryptoScreenState createState() => _FileCryptoScreenState();
}

class _FileCryptoScreenState extends State<FileCryptoScreen> {
  File? _selectedFile;
  List<FileSystemEntity> _encryptedFiles = [];
  bool _isProcessing = false;
  final TextEditingController _passwordController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _requestPermissions();
    _loadEncryptedFiles();
  }

  Future<void> _requestPermissions() async {
    if (Platform.isAndroid) {
    } else if (Platform.isIOS) {
      // iOS doesn't need explicit permissions for accessing Downloads
    }
  }

  Future<void> _loadEncryptedFiles() async {
    final directory = await getApplicationDocumentsDirectory();
    setState(() {
      _encryptedFiles = directory
          .listSync()
          .where((file) => file.path.contains('encrypted_'))
          .toList();
    });
  }

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles();
      if (result != null) {
        setState(() {
          _selectedFile = File(result.files.single.path!);
        });
      }
    } catch (e) {
      _showErrorDialog('Error picking file: $e');
    }
  }

  Future<void> _encryptFile() async {
    if (_selectedFile == null) {
      _showErrorDialog('Please select a file first');
      return;
    }
    if (_passwordController.text.isEmpty) {
      _showErrorDialog('Please enter a password');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final key = _generateKey(_passwordController.text);
      final iv = encrypt.IV.fromSecureRandom(16);
      final encrypter = encrypt.Encrypter(encrypt.AES(key));

      final fileBytes = await _selectedFile!.readAsBytes();
      final encrypted = encrypter.encryptBytes(fileBytes, iv: iv);

      final directory = await getApplicationDocumentsDirectory();
      final fileName =
          'encrypted_${DateTime.now().millisecondsSinceEpoch}_${_selectedFile!.path.split('/').last}';
      final encryptedFile = File('${directory.path}/$fileName');

      List<int> encryptedBytes = iv.bytes + encrypted.bytes;
      await encryptedFile.writeAsBytes(encryptedBytes);

      await _loadEncryptedFiles();
      _showSuccessDialog('File encrypted successfully');

      setState(() {
        _selectedFile = null;
      });
    } catch (e) {
      print('Error encrypting file: $e');
      _showErrorDialog('Error encrypting file: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _decryptFile(File file) async {
    if (_passwordController.text.isEmpty) {
      _showErrorDialog('Please enter a password');
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final key = _generateKey(_passwordController.text);
      final fileBytes = await file.readAsBytes();

      final iv = encrypt.IV(fileBytes.sublist(0, 16));
      final encryptedBytes = fileBytes.sublist(16);

      final encrypter = encrypt.Encrypter(encrypt.AES(key));
      final decrypted =
          encrypter.decryptBytes(encrypt.Encrypted(encryptedBytes), iv: iv);

      // Get the Downloads directory path
      String? downloadsPath =
          await ExternalPath.getExternalStoragePublicDirectory(
              ExternalPath.DIRECTORY_DOWNLOADS);

      final fileName =
          'decrypted_${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last.replaceFirst('encrypted_', '')}';
      final decryptedFile = File('$downloadsPath/$fileName');

      await decryptedFile.writeAsBytes(decrypted);

      _showSuccessDialog(
          'File decrypted successfully and saved to Downloads: ${decryptedFile.path}');
    } catch (e) {
      print('Error decrypting file: $e');
      _showErrorDialog('Error decrypting file: ${e.toString()}');
    } finally {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  Future<void> _deleteFile(File file) async {
    try {
      await file.delete();
      await _loadEncryptedFiles();
      _showSuccessDialog('File deleted successfully');
    } catch (e) {
      print('Error deleting file: $e');
      _showErrorDialog('Error deleting file: ${e.toString()}');
    }
  }

  encrypt.Key _generateKey(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return encrypt.Key(hash.bytes as Uint8List);
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  void _showSuccessDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('File Crypto'),
        backgroundColor: Colors.black12,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: _pickFile,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Colors.blueAccent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(150, 50), // Increased size
              ),
              child: Text('Pick a file'),
            ),
            SizedBox(height: 10),
            if (_selectedFile != null)
              Text('Selected file: ${_selectedFile!.path}'),
            SizedBox(height: 10),
            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                border: OutlineInputBorder(),
                filled: true,
                fillColor: Color.fromARGB(164, 50, 48, 48),
              ),
              style: TextStyle(color: Colors.white),
              obscureText: true,
            ),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: _isProcessing ? null : _encryptFile,
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: _isProcessing ? Colors.grey : Colors.teal,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                minimumSize: Size(150, 50), // Increased size
              ),
              child: _isProcessing
                  ? CircularProgressIndicator()
                  : Text('Encrypt file'),
            ),
            SizedBox(height: 20),
            Text('Encrypted Files:',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            Expanded(
              child: ListView.builder(
                itemCount: _encryptedFiles.length,
                itemBuilder: (context, index) {
                  final file = _encryptedFiles[index];
                  return ListTile(
                    title: Text(file.path.split('/').last),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(Icons.lock_open),
                          onPressed: () => _decryptFile(file as File),
                          color: Colors.tealAccent,
                        ),
                        IconButton(
                          icon: Icon(Icons.delete),
                          onPressed: () => _deleteFile(file as File),
                          color: Colors.redAccent,
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }
}
