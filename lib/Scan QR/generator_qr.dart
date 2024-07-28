import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:screenshot/screenshot.dart';

class QRCodeGenerator extends StatefulWidget {
  @override
  _QRCodeGeneratorState createState() => _QRCodeGeneratorState();
}

class _QRCodeGeneratorState extends State<QRCodeGenerator> {
  String _data = '';
  ScreenshotController screenshotController = ScreenshotController();

  Future<void> _saveQRCode() async {
    try {
      String? fileName = await _showFileNameDialog();
      if (fileName != null) {
        await Future.delayed(Duration(milliseconds: 100));
        final Uint8List? imageBytes = await screenshotController.capture();
        if (imageBytes != null) {
          final result = await ImageGallerySaver.saveImage(imageBytes,
              quality: 100, name: fileName);
          if (result['isSuccess']) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('QR code berhasil disimpan di galeri',
                    style: TextStyle(color: Colors.white))));
          } else {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('Gagal menyimpan QR code',
                    style: TextStyle(color: Colors.white))));
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gambar QR code kosong',
                  style: TextStyle(color: Colors.white))));
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Terjadi kesalahan: ${e.toString()}',
              style: TextStyle(color: Colors.white))));
    }
  }

  Future<String?> _showFileNameDialog() async {
    String? fileName;
    await showDialog(
      context: context,
      builder: (BuildContext context) {
        String nameText = '';
        return AlertDialog(
          title: Text('Nama File', style: TextStyle(color: Colors.white)),
          content: TextField(
            onChanged: (value) {
              nameText = value;
            },
            decoration: InputDecoration(
              hintText: '',
              hintStyle: TextStyle(color: Colors.white54),
            ),
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.grey[900],
          actions: <Widget>[
            TextButton(
              child: Text('Batal', style: TextStyle(color: Colors.white)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child: Text('Simpan', style: TextStyle(color: Colors.white)),
              onPressed: () {
                fileName = nameText;
                Navigator.of(context).pop();
              },
            ),
          ],
        );
      },
    );
    return fileName;
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        backgroundColor: Color(0xFF1E1E1E),
        appBar: AppBar(
          title: Text('Membuat QR', style: TextStyle(color: Colors.white)),
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios, color: Colors.white),
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
          actions: [
            IconButton(
              icon: Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 30.0,
              ),
              onPressed: () {
                showAboutDialog(
                  context: context,
                  applicationName: 'QR Code Generator',
                  applicationVersion: '1.0.0',
                  children: [
                    Text(
                      'Aplikasi untuk membuat dan menyimpan QR Code.',
                      style:
                          TextStyle(color: const Color.fromARGB(255, 0, 0, 0)),
                    ),
                  ],
                );
              },
            )
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 10.0),
                child: TextField(
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Color.fromARGB(164, 50, 48, 48),
                    hintText: 'Masukkan data',
                    hintStyle: TextStyle(color: Colors.grey),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(30.0)),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding:
                        EdgeInsets.symmetric(vertical: 0.0, horizontal: 20.0),
                  ),
                  onChanged: (text) {
                    setState(() {
                      _data = text;
                    });
                  },
                  style: TextStyle(
                      color: const Color.fromARGB(255, 185, 185, 185)),
                ),
              ),
              SizedBox(height: 20),
              Screenshot(
                controller: screenshotController,
                child: _data.isNotEmpty
                    ? Container(
                        padding: EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: QrImageView(
                          data: _data,
                          size: 200,
                        ),
                      )
                    : Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            'QR code akan muncul di sini',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black),
                          ),
                        ),
                      ),
              ),
              SizedBox(height: 20),
              ElevatedButton.icon(
                icon: Icon(Icons.save),
                label: Text('Simpan QR Code',
                    style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 30, vertical: 15),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                onPressed: _data.isNotEmpty ? _saveQRCode : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
