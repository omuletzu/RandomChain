import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/SplashScreen.dart';
import 'package:doom_chain/firebase_options.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  
  OneSignal.initialize('d6b98b33-6d45-4d2e-bd3a-94ede2822050');
  OneSignal.Notifications.requestPermission(true);

  await Workmanager().initialize(
    callBackDipatcher,
    isInDebugMode: true
  );

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.grey,
      systemNavigationBarColor: Colors.black
    )
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  static const platform = MethodChannel('com.example.doom_chain/channel');

  @override
  Widget build(BuildContext context) {

    final double width = MediaQuery.of(context).size.width;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: SplashScreen(width: width)
    );
  }
}

@pragma('vm:entry-point')
void callBackDipatcher(){
  Workmanager().executeTask((task, inputData) async {
    if (task == "listenerTask") {

      if(Firebase.apps.isEmpty){
        await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
      }

      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      int lastNumberOfStory = sharedPreferences.getInt('lastNumberOfStory') ?? 0;
      int lastNumberOfGossip = sharedPreferences.getInt('lastNumberOfGossip') ?? 0;
      int lastNumberOfChainllange = sharedPreferences.getInt('lastNumberOfChainllange') ?? 0;

      QuerySnapshot pendingChains = await FirebaseFirestore.instance.collection('UserDetails').doc(inputData!['userId']).collection('PendingPersonalChains').get();

      Map<String, int> updatedNumberOfStory = {
        'Story' : 0,
        'Gossip' : 0,
        'Chainllange' : 0
      };

      for(DocumentSnapshot document in pendingChains.docs){
        String categoryName = document.get('categoryName') as String;
        updatedNumberOfStory[categoryName] = updatedNumberOfStory[categoryName]! + 1;
      }

      updatedNumberOfStory['Story'] = updatedNumberOfStory['Story']! - lastNumberOfStory;
      updatedNumberOfStory['Gossip'] = updatedNumberOfStory['Gossip']! - lastNumberOfGossip;
      updatedNumberOfStory['Chainllange'] = updatedNumberOfStory['Chainllange']! - lastNumberOfChainllange;

      if(updatedNumberOfStory['Story']! < 0){
        updatedNumberOfStory['Story'] = 0;
      }

      if(updatedNumberOfStory['Gossip']! < 0){
        updatedNumberOfStory['Gossip'] = 0;
      }

      if(updatedNumberOfStory['Chainllange']! < 0){
        updatedNumberOfStory['Chainllange'] = 0;
      }

      sharedPreferences.setInt('lastNumberOfStory', updatedNumberOfStory['Story']!);
      sharedPreferences.setInt('lastNumberOfGossip', updatedNumberOfStory['Gossip']!);
      sharedPreferences.setInt('lastNumberOfChainllange', updatedNumberOfStory['Chainllange']!);

      if(updatedNumberOfStory['Story']! > 0 || updatedNumberOfStory['Gossip']! > 0 || updatedNumberOfStory['Chainllange']! > 0){
        FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin = FlutterLocalNotificationsPlugin();
        AndroidInitializationSettings androidInitializationSettings = const AndroidInitializationSettings('@mipmap/logo');

        final InitializationSettings initializationSettings = InitializationSettings(android: androidInitializationSettings);

        flutterLocalNotificationsPlugin.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (details) {
            
          }
        );

        Random random = Random();

        AndroidNotificationDetails androidNotificationDetails = AndroidNotificationDetails(
          (random.nextInt(69420)).toString(), 
          'ReminderNotification',
          importance: Importance.max,
          priority: Priority.high
        );

        NotificationDetails notificationDetails = NotificationDetails(android: androidNotificationDetails);

        flutterLocalNotificationsPlugin.show(
          random.nextInt(69420), 
          'Looks like you have new chains',
          '${updatedNumberOfStory['Story']} Story | ${updatedNumberOfStory['Gossip']} Gossip | ${updatedNumberOfStory['Chainllange']} Chainllange',
          notificationDetails
        );
      }
    }
    
     return Future.value(true);
  });
}