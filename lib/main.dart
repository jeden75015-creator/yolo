import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import 'package:yolo/widgets/firebase_options.dart';
import 'package:yolo/notifications/notification_service.dart';
import 'package:yolo/profil/user_service.dart';

// Pages
import 'package:yolo/accueil/home_page.dart';
import 'package:yolo/connexions/login_page.dart';
import 'package:yolo/settings/settings_page.dart';
import 'package:yolo/Notifications/notification_page.dart';
import 'package:yolo/profil/reseau_page.dart';
import 'package:yolo/chats/messagerie_page.dart';
import 'package:yolo/activite/activite_liste_page.dart';
import 'package:yolo/event/event_page.dart';
import 'package:yolo/accueil/post/poll/create_poll_page.dart';
import 'package:yolo/accueil/post/post/create_post.dart';
import 'package:yolo/accueil/post/comment/comments_page.dart';
import 'package:yolo/groupe/groupe_creation_page.dart';

final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
    FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  }

  await initializeDateFormatting('fr_FR', null);
  Intl.defaultLocale = 'fr_FR';

  // Local notifications
  if (!kIsWeb) {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const init = InitializationSettings(android: android);
    await flutterLocalNotificationsPlugin.initialize(init);
  }

  try {
    await FirebaseMessaging.instance.requestPermission();
    await NotificationService.instance.initAndRegisterToken();
  } catch (_) {}

  if (!kIsWeb) {
    await MobileAds.instance.initialize();
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'YOLO',
      debugShowCheckedModeBanner: false,
      initialRoute: "/auth",
      routes: {
        "/auth": (context) => const AuthGate(),
        "/home": (context) => const HomePage(),
        "/settings": (context) => const SettingsPage(),
        "/notifications": (context) => const NotificationsPage(),
        "/reseau": (context) => const ReseauPage(),
        "/chat": (context) => const MessageriePage(),
        "/activites": (context) => const ActiviteListePage(),
        "/events": (context) => const EventPage(),
        "/create_post": (context) => const CreatePostPage(),
        "/comments": (context) => const CommentsPage(),
        "/create_poll": (context) => const CreatePollPage(),
        "/create_group": (context) => const GroupeCreationPage(),
      },
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(color: Colors.orange),
            ),
          );
        }

        final user = snap.data;

        if (user == null) {
          return const LoginPage();
        }

        return FutureBuilder<void>(
          future: UserService().ensureUserDocument(),
          builder: (_, done) {
            if (done.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(color: Colors.orange),
                ),
              );
            }
            return const HomePage();
          },
        );
      },
    );
  }
}
