import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:coursework/providers/auth_provider.dart';
import 'package:coursework/providers/task_provider.dart';
import 'package:coursework/screens/auth/login_screen.dart';
import 'package:coursework/screens/home/home_screen.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:coursework/models/user.dart';
import 'services/analytics_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  
  // Включаем постоянное хранение данных
  FirebaseDatabase.instance.setPersistenceEnabled(true);
  // Устанавливаем URL базы данных
  FirebaseDatabase.instance.databaseURL = 'https://courseproject-5d1ad-default-rtdb.europe-west1.firebasedatabase.app';
  
  // Инициализируем аналитику
  final analytics = AnalyticsService();
  await analytics.init();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProxyProvider<AuthProvider, TaskProvider>(
          create: (context) => TaskProvider(User(
            id: 'temp',
            email: 'temp@temp.com',
            name: 'Temp User',
            role: 'user',
            createdAt: DateTime.now(),
          )),
          update: (context, auth, previous) {
            if (auth.user == null) {
              return TaskProvider(User(
                id: 'temp',
                email: 'temp@temp.com',
                name: 'Temp User',
                role: 'user',
                createdAt: DateTime.now(),
              ));
            }
            return TaskProvider(auth.user!);
          },
        ),
      ],
      child: MaterialApp(
        title: 'Task Manager',
        theme: ThemeData(
          primarySwatch: Colors.blue,
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
          ),
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
        navigatorObservers: [
          FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance),
        ],
        home: const AuthWrapper(),
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, authProvider, _) {
        if (authProvider.isLoading) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        return authProvider.isAuthenticated
            ? const HomeScreen()
            : const LoginScreen();
      },
    );
  }
}
