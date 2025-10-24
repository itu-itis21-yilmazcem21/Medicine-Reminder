import 'package:flutter/material.dart';
import 'package:medicine_reminder/screens/medicine_list_screen.dart';
//import 'package:medicine_reminder/services/notification_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  //await NotificationService.ensureTimezoneInit();
  //await NotificationService().init();
  //await NotificationService().rescheduleAllFromDatabase();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '\u0130la\u00E7 Hat\u0131rlat\u0131c\u0131',
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.indigo),
      home: const MedicineListScreen(),
    );
  }
}
