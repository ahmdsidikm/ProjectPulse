import 'package:flutter/material.dart';

class TextDisplayScreen extends StatelessWidget {
  final String text;

  const TextDisplayScreen({Key? key, required this.text}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, true);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Recognized Text'),
          leading: IconButton(
            icon: Icon(Icons.arrow_back),
            onPressed: () {
              Navigator.pop(context, true); // Mengirim sinyal kembali
            },
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: SelectableText(
            text,
            style: TextStyle(fontSize: 16.0),
          ),
        ),
      ),
    );
  }
}
