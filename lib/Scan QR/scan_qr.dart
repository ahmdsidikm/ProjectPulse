import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_code_scanner/qr_code_scanner.dart';
import 'package:text_recognition/Scan%20QR/generator_qr.dart';
import 'package:url_launcher/url_launcher.dart';

class QRViewExample extends StatefulWidget {
  const QRViewExample({Key? key}) : super(key: key);

  @override
  State<StatefulWidget> createState() => _QRViewExampleState();
}

class _QRViewExampleState extends State<QRViewExample> {
  QRViewController? controller;
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  bool isFlashOn = false;
  bool isCameraPaused = false;

  @override
  void reassemble() {
    super.reassemble();
    if (Platform.isAndroid) {
      controller!.pauseCamera();
    }
    controller!.resumeCamera();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF1E1E1E), // Change background color to black
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
        title: const Text('Memindai QR', style: TextStyle(color: Colors.white)),
        backgroundColor: Color(0xFF1E1E1E), // Change app bar color to black
        actions: [
          IconButton(
            onPressed: () async {
              // Hentikan kamera sebelum berpindah ke generator QR
              await controller?.pauseCamera();

              // Navigasi ke layar generator QR
              Navigator.of(context)
                  .push(
                MaterialPageRoute(
                  builder: (context) => QRCodeGenerator(),
                ),
              )
                  .then((_) {
                // Setelah kembali dari generator QR, jalankan kamera lagi
                controller?.resumeCamera();
              });
            },
            icon: Icon(Icons.qr_code, color: Colors.white),
            iconSize: 30,
          ),
          IconButton(
            onPressed: () async {
              if (controller != null) {
                await controller!.toggleFlash();
                setState(() {
                  isFlashOn = !isFlashOn;
                });
              }
            },
            icon: Icon(
              isFlashOn ? Icons.flash_on : Icons.flash_off,
              color: Colors.white,
              size: 30.0,
            ),
          ),
        ],
      ),
      body: Stack(
        children: <Widget>[
          _buildQrView(context),
        ],
      ),
    );
  }

  Widget _buildQrView(BuildContext context) {
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
            MediaQuery.of(context).size.height < 400)
        ? MediaQuery.of(context).size.width * 0.8
        : MediaQuery.of(context).size.width * 0.6;
    return QRView(
      key: qrKey,
      onQRViewCreated: _onQRViewCreated,
      overlay: QrScannerOverlayShape(
        borderColor: Colors.blueAccent,
        borderRadius: 10,
        borderLength: 30,
        borderWidth: 10,
        cutOutSize: scanArea,
      ),
      onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
    );
  }

  void _onQRViewCreated(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    controller.scannedDataStream.listen((scanData) {
      if (!isCameraPaused) {
        controller.pauseCamera();
        setState(() {
          isCameraPaused = true;
        });
        Navigator.of(context)
            .push(MaterialPageRoute(
          builder: (context) => ScanResultScreen(scanData.code ?? 'No data'),
        ))
            .then((_) {
          controller.resumeCamera();
          setState(() {
            isCameraPaused = false;
          });
        });
      }
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p' as num);
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content:
                Text('No Permission', style: TextStyle(color: Colors.white))),
      );
    }
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }
}

class ScanResultScreen extends StatelessWidget {
  final String scannedData;
  const ScanResultScreen(this.scannedData, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Hasil Pemindaian',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black, Colors.blueGrey[900]!],
          ),
        ),
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.qr_code_scanner, size: 80, color: Colors.blue),
                SizedBox(height: 30),
                Text(
                  'Hasil Pemindaian:',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 20),
                Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: InkWell(
                    onTap: () async {
                      await launchUrl(Uri.parse(scannedData));
                    },
                    child: Text(
                      scannedData,
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.blue[300],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
                SizedBox(height: 30),
                ElevatedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: scannedData));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Disalin ke Clipboard'),
                        backgroundColor: Colors.green,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: Icon(Icons.copy,
                      color: const Color.fromARGB(255, 255, 255, 255)),
                  label: Text('Salin',
                      style:
                          TextStyle(color: Color.fromARGB(255, 255, 254, 254))),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
