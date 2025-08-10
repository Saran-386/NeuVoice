import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/api_service.dart';
import 'services/history_service.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/responsive_home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive for Flutter
  await Hive.initFlutter();

  // Register any custom adapters here
  // Hive.registerAdapter(TranscriptionAdapter());

  // Open your boxes
  await Hive.openBox('transcriptions');
  await Hive.openBox('settings');
  runApp(const NeuVoiceApp());
}

class NeuVoiceApp extends StatelessWidget {
  const NeuVoiceApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => ApiService()),
        ChangeNotifierProvider(create: (_) => HistoryService()),
      ],
      child: MaterialApp(
        title: 'NeuVoice - AI Speech Recognition',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        home: const ResponsiveHomeScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
