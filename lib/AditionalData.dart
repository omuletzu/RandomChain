import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/EmailPassSignUp.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:doom_chain/PhoneAuth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:country_picker/country_picker.dart';
import 'AbstractMenu.dart';

class AditionalData extends StatefulWidget{

  final PhoneAuthCredential? credentials;
  final UserCredential? userCredential;
  final String phoneOrEmail;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final double width;
  final void Function(Widget) currentAuthRefresh;

  AditionalData({required this.firebaseAuth, required this.width, required this.firebaseFirestore, required this.phoneOrEmail, required this.currentAuthRefresh, required this.credentials, required this.userCredential});

  @override
  _AditionalData createState() => _AditionalData();
}

class _AditionalData extends State<AditionalData>{

  final TextEditingController _nicknameController = TextEditingController();

  String lastDateTimeText = 'DD / MM / YYYY';
  String dateTimeText = 'DD / MM / YYYY';
  late DateTime? dateTime;

  String countryEmoji = Country.worldWide.flagEmoji;
  String countryName = '-';

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if(didPop == false){

          if(widget.userCredential != null){
            await widget.userCredential!.user!.delete();
          }

          await widget.firebaseAuth.signOut();
          await GoogleSignIn().signOut();

          SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
          if(sharedPreferences.getBool('lastAuthPhone') == true){
            widget.currentAuthRefresh(PhoneAuth(currentAuthRefresh: widget.currentAuthRefresh, firebaseAuth: widget.firebaseAuth, width: widget.width, firebaseFirestore: widget.firebaseFirestore));
          }
          else{
            widget.currentAuthRefresh(EmailPassSignUp(currentAuthRefresh: widget.currentAuthRefresh, firebaseAuth: widget.firebaseAuth, firebaseFirestore: widget.firebaseFirestore));
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Center(
              child: Text('Additional data', style: GoogleFonts.nunito(fontSize: width * 0.10, color: Colors.black87, fontWeight: FontWeight.bold)),
            ),

            Padding(
              padding: EdgeInsets.all(width * 0.1),
                child: TextField(
                  controller: _nicknameController,
                  maxLength: 15,
                  decoration: InputDecoration(
                    hintText: 'Nickname',
                    hintStyle: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                style: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(widget.width * 0.025),
                  child: Text('Date of birth', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.black87, fontWeight: FontWeight.bold)),
                ),

                Padding(
                  padding: EdgeInsets.all(widget.width * 0.025),
                  child: TextButton(
                    onPressed: () async {
                      dateTime = await showDatePicker(
                        context: context, 
                        firstDate: DateTime(1900), 
                        lastDate: DateTime(DateTime.now().year + 1),
                      );
                  
                      if(dateTime != null){
                        setState(() {
                          dateTimeText = '${dateTime?.day} / ${dateTime?.month} / ${dateTime?.year}';
                          lastDateTimeText = dateTimeText;
                        });
                      }
                      else{
                        setState(() {
                          dateTimeText = lastDateTimeText;
                        });
                      }
                    }, 
                    child: Text(dateTimeText, style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                  ),
                ),
              ],
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                
                Padding(
                  padding: EdgeInsets.all(widget.width * 0.025),
                  child: Text('Country', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.black87, fontWeight: FontWeight.bold)),
                ),

                Padding(
                  padding: EdgeInsets.all(widget.width * 0.025),
                  child: TextButton(
                    onPressed: () {
                      showCountryPicker(
                        context: context, 
                        showPhoneCode: false,
                        onSelect: (country) {
                          setState(() {
                            countryEmoji = country.flagEmoji;
                            countryName = country.displayNameNoCountryCode;
                          });
                        }
                      );
                    }, 
                    child: Text('$countryEmoji $countryName', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold)),
                  ),
                ),
              ],
            ),
            

            Padding(
              padding: EdgeInsets.all(widget.width * 0.1),
              child: Material(
                color: globalPurple,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))
                ),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  onTap: () async {
                    
                    if(dateTimeText == 'DD / MM / YYYY'){
                      Fluttertoast.showToast(msg: 'Invalid birthdate', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                      return;
                    }

                    if(dateTime == null){
                      Fluttertoast.showToast(msg: 'Invalid birthdate', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                      return;
                    }

                    if(DateTime.now().year - (dateTime?.year ?? 0) < 10){
                      Fluttertoast.showToast(msg: 'Invalid birthdate', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                      return;
                    }

                    if(_nicknameController.text.isEmpty){
                      Fluttertoast.showToast(msg: 'Invalid nickname', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                      return;
                    }

                    if(countryName == '-'){
                      Fluttertoast.showToast(msg: 'Invalid country', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                      return;
                    }

                    widget.firebaseFirestore.collection('UserDetails').doc(widget.phoneOrEmail).set({
                      'nickname' : _nicknameController.text.trim(),
                      'nicknameLowercase': _nicknameController.text.toLowerCase().trim(),
                      'birthdate' : dateTimeText,
                      'countryName' : countryName,
                      'countryEmoji' : countryEmoji,
                      'avatarPath' : '-',
                      'StoryContributions' : 0,
                      'RandomContributions' : 0,
                      'ChainllangeContributions' : 0,
                      'totalContributions' : 0,
                      'totalPoints' : 0,
                      'accountSince' : Timestamp.now(),
                      'friendsCount' : 0,
                    });

                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AbstractMenu(phoneOrEmail: widget.phoneOrEmail)));

                  }, 
                  splashColor: globalBlue,
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.025),
                    child: Text('CONTINUE', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                  )
                )
              )
            )
          ]
        )
      )
    );
  }
}