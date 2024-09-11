import 'package:doom_chain/GlobalValues.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';

class ProfileSettings extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final void Function() updateUIFromSetting;
  final String userId;

  ProfileSettings({
    required this.changePageHeader,
    required this.updateUIFromSetting,
    required this.userId
  });

  @override
  _ProfileSettings createState() => _ProfileSettings();
}

class _ProfileSettings extends State<ProfileSettings> {

  late SharedPreferences sharedPreferences;
  bool notificationsEnabled = true;
  bool darkModeEnabled = false;
  bool dataRetreived = false;

  @override
  void initState() {
    _retreiveSharedPref();
    super.initState();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if(!didPop){
          widget.changePageHeader('Go Back', null);
        }
      },
      child: Scaffold(
        backgroundColor: globalBackground,
        body: Column(
          children: [
            
            Padding(
              padding:  EdgeInsets.only(left: width * 0.05, right: width * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Text('Notifications', style: GoogleFonts.nunito(fontSize: width * 0.045, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                  ),

                  Icon(Icons.notifications, size: width * 0.075, color: globalTextBackground),
              
                  const Spacer(),
              
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Switch(
                      value: dataRetreived ? notificationsEnabled : false, 
                      onChanged: (value) {
                        sharedPreferences.setBool('notificationsEnabled', value);
                        setState(() {
                          notificationsEnabled = value;
                        });

                        if(value){
                          Workmanager().registerPeriodicTask(
                            '1', 
                            'listenerTask',
                            frequency: const Duration(minutes: 15),
                            existingWorkPolicy: ExistingWorkPolicy.replace,
                            inputData: {
                              'userId' : widget.userId
                            }
                          );
                          OneSignal.User.pushSubscription.optIn();
                        }
                        else{
                          Workmanager().cancelByUniqueName('1');
                          OneSignal.User.pushSubscription.optOut();
                        }
                      }
                    )
                  )
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025),
              child: Divider(
                height: 2.0,
                color: globalDrawerBackground,
              ),
            ),

            Padding(
              padding:  EdgeInsets.only(left: width * 0.05, right: width * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Text('Dark Mode', style: GoogleFonts.nunito(fontSize: width * 0.045, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                  ),

                  Icon(Icons.dark_mode, size: width * 0.075, color: globalTextBackground),
              
                  const Spacer(),
              
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Switch(
                      value: dataRetreived ? darkModeEnabled : false, 
                      onChanged: (value) {
                        sharedPreferences.setBool('darkModeEnabled', value);
                        setState(() {
                          darkModeEnabled = value;
                        });

                        if(value){
                          setState(() {
                            globalPurple = const Color.fromARGB(255, 128, 0, 255);
                            globalBackground = const Color(0xFF121212);
                            globalTextBackground = Colors.grey[200]!;
                            globalDrawerBackground = Colors.grey;
                          });
                        }
                        else{
                          setState(() {
                            globalPurple = const Color.fromARGB(255, 102, 0, 255);
                            globalBackground = Colors.white;
                            globalTextBackground = Colors.black87;
                            globalDrawerBackground = Colors.grey[200]!;
                          });
                        }

                        widget.updateUIFromSetting();
                      }
                    )
                  )
                ],
              ),
            )
          ],
        ),
      )
    );
  }

  Future<void> _retreiveSharedPref() async {
    sharedPreferences = await SharedPreferences.getInstance();
    
    if(sharedPreferences.getBool('notificationsEnabled') == null){
      sharedPreferences.setBool('notificationsEnabled', true);
      notificationsEnabled = true;
    }
    else{
      notificationsEnabled = sharedPreferences.getBool('notificationsEnabled')!;
    }

    if(sharedPreferences.getBool('darkModeEnabled') == null){
      sharedPreferences.setBool('darkModeEnabled', true);
      darkModeEnabled = true;
    }
    else{
      darkModeEnabled = sharedPreferences.getBool('darkModeEnabled')!;
    }

    if(mounted){
      setState(() {
        dataRetreived = true;
      });
    }
  }
}