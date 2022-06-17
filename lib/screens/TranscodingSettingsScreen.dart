import '../components/TranscodingSettingsScreen/TranscodeSwitch.dart';
import '../components/TranscodingSettingsScreen/BitrateSelector.dart';
import 'package:flutter/material.dart';


class TranscodingSettingsScreen extends StatelessWidget {
  const TranscodingSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Transcoding"),
      ),
      body: Scrollbar(
        child: ListView(
          children: [
            const TranscodeSwitch(),
            const BitrateSelector(),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                "Jellyfin uses AAC for transcoding.",
                style: Theme.of(context).textTheme.caption,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
