import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalValues.dart';
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

      FirebaseFirestore firebase = FirebaseFirestore.instance;
      FirebaseStorage storage = FirebaseStorage.instance;
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      DateTime timestamp = Timestamp.now().toDate();

      int lastNumberOfStory = sharedPreferences.getInt('lastNumberOfStory') ?? 0;
      int lastNumberOfRandom = sharedPreferences.getInt('lastNumberOfRandom') ?? 0;
      int lastNumberOfChainllange = sharedPreferences.getInt('lastNumberOfChainllange') ?? 0;

      Map<String, int> updatedNumber = {
        'Story' : 0,
        'Random' : 0,
        'Chainllange' : 0
      };

      QuerySnapshot pendingChains = await firebase.collection('UserDetails').doc(inputData!['userId']).collection('PendingPersonalChains').get();

      for(DocumentSnapshot pendingChain in pendingChains.docs){

        Map<String, dynamic> chainMap = pendingChain.data() as Map<String, dynamic>;
        DateTime timeDifference = chainMap['receivedTime'].toDate();

        if(timestamp.difference(timeDifference).inHours >= 2){

          chainMap['receivedTime'] = Timestamp.now();

          SendUploadData.uploadData(
            firebase: firebase, 
            storage: storage, 
            addData: {
              'userId' : inputData['userId'],
              'randomOrFriends' : chainMap['random']
            }, 
            chainMap: chainMap, 
            disableFirstPhraseForChallange: false, 
            contributorsList: null,
            theme: '', 
            title: '', 
            photoSkipped: true, 
            chainIdentifier: pendingChain.id, 
            categoryName: chainMap['categoryName'], 
            chainSkipped: true, 
            photoPath: null, 
            mounted: false, 
            context: null, 
            changePageHeader: null, 
            newChainOrExtend: false
          );
        }
        else{
          updatedNumber[chainMap['categoryName']] = updatedNumber[chainMap['categoryName']]! + 1;
        }
      }

      updatedNumber['Story'] = updatedNumber['Story']! - lastNumberOfStory;
      updatedNumber['Random'] = updatedNumber['Random']! - lastNumberOfRandom;
      updatedNumber['Chainllange'] = updatedNumber['Chainllange']! - lastNumberOfChainllange;

      if(updatedNumber['Story']! < 0){
        updatedNumber['Story'] = 0;
      }

      if(updatedNumber['Random']! < 0){
        updatedNumber['Random'] = 0;
      }

      if(updatedNumber['Chainllange']! < 0){
        updatedNumber['Chainllange'] = 0;
      }

      sharedPreferences.setInt('lastNumberOfStory', updatedNumber['Story']!);
      sharedPreferences.setInt('lastNumberOfRandom', updatedNumber['Random']!);
      sharedPreferences.setInt('lastNumberOfChainllange', updatedNumber['Chainllange']!);

      QuerySnapshot pendingFriends = await firebase.collection('UserDetails').doc(inputData['userId']).collection('FriendRequests').get();

      int lastNumberOfPendingFriends = sharedPreferences.getInt('lastNumberOfPendingFriends') ?? 0;

      sharedPreferences.setInt('lastNumberOfPendingFriends', pendingFriends.docs.length);

      if(updatedNumber['Story']! > 0 || updatedNumber['Random']! > 0 || updatedNumber['Chainllange']! > 0 || (pendingFriends.docs.length != lastNumberOfPendingFriends && pendingFriends.docs.isNotEmpty)){
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

        if(updatedNumber['Story']! > 0 || updatedNumber['Random']! > 0 || updatedNumber['Chainllange']! > 0){
          flutterLocalNotificationsPlugin.show(
            random.nextInt(69420), 
            'Looks like you have new chains',
            '${updatedNumber['Story']} Story | ${updatedNumber['Random']} Random | ${updatedNumber['Chainllange']} Chainllange',
            notificationDetails
          );
        }
      }
    }
    
     return Future.value(true);
  });
}