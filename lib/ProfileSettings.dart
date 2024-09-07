import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileSettings extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final String userId;

  ProfileSettings({
    required this.changePageHeader,
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
        body: Column(
          children: [
            
            Padding(
              padding:  EdgeInsets.only(left: width * 0.05, right: width * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Text('Notifications', style: GoogleFonts.nunito(fontSize: width * 0.045, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                  ),

                  Icon(Icons.notifications, size: width * 0.075),
              
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
                      }
                    )
                  )
                ],
              ),
            ),

            Padding(
              padding: EdgeInsets.all(width * 0.025),
              child: Divider(
                height: 2.0,
                color: Colors.grey[200],
              ),
            ),

            Padding(
              padding:  EdgeInsets.only(left: width * 0.05, right: width * 0.05),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Text('Dark Mode', style: GoogleFonts.nunito(fontSize: width * 0.045, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                  ),

                  Icon(Icons.dark_mode, size: width * 0.075),
              
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
      sharedPreferences.setBool('darkModeEnabled', false);
      darkModeEnabled = false;
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