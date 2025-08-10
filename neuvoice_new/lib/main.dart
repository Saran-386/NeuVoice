import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/audio_service_interface.dart';
import 'services/audio_service_impl.dart';
import 'services/api_service.dart';
import 'services/history_service.dart';
import 'screens/home_screen.dart';
import 'utils/constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AudioServiceInterface>(
          create: (context) => AudioServiceImpl(),
        ),
        ChangeNotifierProvider<ApiService>(
          create: (context) => ApiService(),
        ),
        ChangeNotifierProvider<HistoryService>(
          create: (context) => HistoryService(),
        ),
      ],
      child: MaterialApp(
        title: 'NeuVoice',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(AppConstants.primaryColor),
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}
