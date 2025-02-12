import 'package:flutter/material.dart';

class SettingsPage extends StatefulWidget {

  const SettingsPage({
    super.key,

  });

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ayarlar'),
      ),
      body: ListView(
        children: [
          ListTile(
            title: const Text('Tema Seçimi'),
            trailing: DropdownButton<ThemeMode>(

              items: const [
                DropdownMenuItem(
                  value: ThemeMode.system,
                  child: Text('Sistem'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.light,
                  child: Text('Açık Tema'),
                ),
                DropdownMenuItem(
                  value: ThemeMode.dark,
                  child: Text('Koyu Tema'),
                ),
              ],
              onChanged: (ThemeMode? newTheme) {
                if (newTheme != null) {

                }
              },
            ),
          ),
        ],
      ),
    );
  }
}