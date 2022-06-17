import '../components/LayoutSettingsScreen/ContentGridViewCrossAxisCountListTile.dart';
import '../components/LayoutSettingsScreen/ContentViewTypeDropdownListTile.dart';
import '../components/LayoutSettingsScreen/ShowTextOnGridViewSelector.dart';
import 'package:flutter/material.dart';


class LayoutSettingsScreen extends StatelessWidget {
  const LayoutSettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Layout"),
      ),
      body: ListView(
        children: [
          const ContentViewTypeDropdownListTile(),
          for (final type in ContentGridViewCrossAxisCountType.values)
            ContentGridViewCrossAxisCountListTile(type: type),
          const ShowTextOnGridViewSelector(),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.tab),
            title: const Text("Tabs"),
            onTap: () => Navigator.of(context).pushNamed("/settings/tabs"),
          ),
        ],
      ),
    );
  }
}
