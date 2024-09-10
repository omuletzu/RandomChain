import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalColors.dart';
import 'package:doom_chain/SendUploadData.dart';
import 'package:doom_chain/SplashScreen.dart';
import 'package:doom_chain/firebase_options.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:workmanager/workmanager.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() async {

  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true
  );

  await Workmanager().initialize(
    callBackDipatcher,
    isInDebugMode: false
  );

  OneSignal.initialize('d6b98b33-6d45-4d2e-bd3a-94ede2822050');
  OneSignal.Notifications.requestPermission(true);
  OneSignal.User.pushSubscription.optOut();

  SystemChrome.setSystemUIOverlayStyle(
    SystemUiOverlayStyle(
      statusBarColor: globalBackground,
      systemNavigationBarColor: Colors.black
    )
  );

  sqfliteFfiInit();

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

      FirebaseFirestore _firebase = FirebaseFirestore.instance;
      FirebaseStorage _storage = FirebaseStorage.instance;

      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

      int lastNumberOfStory = sharedPreferences.getInt('lastNumberOfStory') ?? 0;
      int lastNumberOfrandom = sharedPreferences.getInt('lastNumberOfrandom') ?? 0;
      int lastNumberOfChainllange = sharedPreferences.getInt('lastNumberOfChainllange') ?? 0;

      QuerySnapshot pendingChains = await _firebase.collection('UserDetails').doc(inputData!['userId']).collection('PendingPersonalChains').get();

      Map<String, int> updatedNumberOfStory = {
        'Story' : 0,
        'random' : 0,
        'Chainllange' : 0
      };

      for(DocumentSnapshot document in pendingChains.docs){
        String categoryName = document.get('categoryName') as String;
        updatedNumberOfStory[categoryName] = updatedNumberOfStory[categoryName]! + 1;
      }

      updatedNumberOfStory['Story'] = updatedNumberOfStory['Story']! - lastNumberOfStory;
      updatedNumberOfStory['random'] = updatedNumberOfStory['random']! - lastNumberOfrandom;
      updatedNumberOfStory['Chainllange'] = updatedNumberOfStory['Chainllange']! - lastNumberOfChainllange;

      if(updatedNumberOfStory['Story']! < 0){
        updatedNumberOfStory['Story'] = 0;
      }

      if(updatedNumberOfStory['random']! < 0){
        updatedNumberOfStory['random'] = 0;
      }

      if(updatedNumberOfStory['Chainllange']! < 0){
        updatedNumberOfStory['Chainllange'] = 0;
      }

      sharedPreferences.setInt('lastNumberOfStory', updatedNumberOfStory['Story']!);
      sharedPreferences.setInt('lastNumberOfrandom', updatedNumberOfStory['random']!);
      sharedPreferences.setInt('lastNumberOfChainllange', updatedNumberOfStory['Chainllange']!);

      QuerySnapshot pendingFriends = await _firebase.collection('UserDetails').doc(inputData['userId']).collection('FriendRequests').get();

      int lastNumberOfPendingFriends = sharedPreferences.getInt('lastNumberOfPendingFriends') ?? 0;

      sharedPreferences.setInt('lastNumberOfPendingFriends', pendingFriends.docs.length);

      if(updatedNumberOfStory['Story']! > 0 || updatedNumberOfStory['random']! > 0 || updatedNumberOfStory['Chainllange']! > 0 || (pendingFriends.docs.length != lastNumberOfPendingFriends && pendingFriends.docs.isNotEmpty)){
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

        if(pendingFriends.docs.length != lastNumberOfPendingFriends && pendingFriends.docs.isNotEmpty){
          flutterLocalNotificationsPlugin.show(
            random.nextInt(69420), 
            'Friend requests',
            'You have ${pendingFriends.docs.length} pending requests',
            notificationDetails
          );
        }

        if(updatedNumberOfStory['Story']! > 0 || updatedNumberOfStory['random']! > 0 || updatedNumberOfStory['Chainllange']! > 0){
          flutterLocalNotificationsPlugin.show(
            random.nextInt(69420), 
            'Looks like you have new chains',
            '${updatedNumberOfStory['Story']} Story | ${updatedNumberOfStory['random']} random | ${updatedNumberOfStory['Chainllange']} Chainllange',
            notificationDetails
          );
        }
      }

      DateTime timestamp = Timestamp.now().toDate();

      for(DocumentSnapshot pendingChain in pendingChains.docs){
        DateTime timeDifference = pendingChain.get('receivedTime').toDate();
        int differenceInHours = timestamp.difference(timeDifference).inHours;

        if(differenceInHours >= 2){
          SendUploadData.uploadData(
            firebase: _firebase, 
            storage: _storage, 
            addData: {
              'userId' : inputData['userId'],
              'randomOrFriends' : pendingChain['random']
            }, 
            chainMap: pendingChain.data() as Map<String, dynamic>, 
            disableFirstPhraseForChallange: false, 
            contributorsList: null,
            theme: '', 
            title: '', 
            photoSkipped: false, 
            chainIdentifier: pendingChain.id, 
            categoryName: pendingChain.get('categoryName'), 
            chainSkipped: true, 
            photoPath: null, 
            mounted: false, 
            context: null, 
            changePageHeader: null, 
            newChainOrExtend: false
          );

          _firebase.collection('UserDetails').doc(inputData['userId']).collection('PendingPersonalChains').doc(pendingChain.id).delete();
        }
      }
    }
    
     return Future.value(true);
  });
}