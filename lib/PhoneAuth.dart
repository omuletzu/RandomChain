import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/AbstractMenu.dart';
import 'package:doom_chain/AditionalData.dart';
import 'package:doom_chain/EmailPassSignIn.dart';
import 'package:doom_chain/GlobalColors.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Auth.dart';

class PhoneAuth extends StatefulWidget{

  final void Function(Widget) currentAuthRefresh;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;
  final double width;

  PhoneAuth({required this.currentAuthRefresh, required this.firebaseAuth, required this.width, required this.firebaseFirestore});

  @override
  _PhoneAuth createState() => _PhoneAuth();
}

class _PhoneAuth extends State<PhoneAuth>{

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  String countryPrefix = '+1';

  String verificationId = ' ';
  bool codeSent = false;
  bool displayProgress = false;

  String finalPhoneNumber = ' ';

  late Widget phoneInput;
  late Widget codeInput;

  @override
  void initState(){
    super.initState();

    phoneInput = IntlPhoneField(
      controller: _phoneController,
      decoration: InputDecoration(
        hintText: '(123) 456 7890',
        hintStyle: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    initialCountryCode: 'US',
    dropdownTextStyle: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold),
    onCountryChanged: (value) {
      countryPrefix = value.dialCode;
    },
    style: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold));

    codeInput = TextField(
      controller: _codeController,
      keyboardType: TextInputType.phone,
      decoration: InputDecoration(
        hintText: 'SMS Code',
        hintStyle: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
      ),
    style: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center);
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      body: Column(
          children: [
            Center(
              child: Text('Phone number', style: GoogleFonts.nunito(fontSize: width * 0.10, color: Colors.black87, fontWeight: FontWeight.bold)),
            ),

            Padding(
              padding: EdgeInsets.all(width * 0.1),
                child: !codeSent ? phoneInput : codeInput,
          ),

          Padding(
            padding: EdgeInsets.all(width * 0.1),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: IconButton(
                    onPressed: () {
                      widget.currentAuthRefresh(EmailPassSignIn(currentAuthRefresh: widget.currentAuthRefresh, firebaseAuth: widget.firebaseAuth, firebaseFirestore: widget.firebaseFirestore));
                    }, 
                    icon: Image.asset('assets/image/mailpass.png', width: width * 0.1, height: width * 0.1)
                  )
                ),

                Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: IconButton(
                    onPressed: () {
                      
                    }, 
                    icon: Image.asset('assets/image/phone.png', width: width * 0.1, height: width * 0.1)
                  )
                ),

                Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: IconButton(
                    onPressed: () async {
                      Auth.googleAuth(context, widget.firebaseAuth, widget.firebaseFirestore, widget.currentAuthRefresh, width);
                    }, 
                    icon: Image.asset('assets/image/googleicon.png', width: width * 0.1, height: width * 0.1)
                  )
                )
              ],
            )
          ),

          displayProgress ? const CircularProgressIndicator()
            : Material(
                color: globalPurple,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))
                ),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  onTap: () async {

                    FocusScope.of(context).unfocus();

                    if(mounted){
                      setState(() {
                        displayProgress = true;
                      });
                    }
                    
                    if(codeSent){

                      if(mounted){
                        setState(() {
                          displayProgress = true;
                        });
                      }

                      if(mounted && _codeController.text.isEmpty){
                        Fluttertoast.showToast(msg: 'Empty SMS code', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
                        setState(() {
                          displayProgress = false;
                        });
                        return;
                      }

                      PhoneAuthCredential credentials = PhoneAuthProvider.credential(verificationId: verificationId, smsCode: _codeController.text.trim());

                      try{

                        await widget.firebaseAuth.signInWithCredential(credentials);

                        DocumentSnapshot documentSnapshot = await widget.firebaseFirestore.collection('UserDetails').doc(finalPhoneNumber).get();

                        if(documentSnapshot.exists){
                          await widget.firebaseAuth.signInWithCredential(credentials);
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AbstractMenu(phoneOrEmail: finalPhoneNumber.trim())));
                        }
                        else{
                          SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
                          sharedPreferences.setBool('lastAuthPhone', true);
                          UserCredential userCredential = await widget.firebaseAuth.signInWithCredential(credentials);
                          widget.currentAuthRefresh(AditionalData(firebaseAuth: widget.firebaseAuth, width: width, firebaseFirestore: widget.firebaseFirestore, phoneOrEmail: finalPhoneNumber.trim(), currentAuthRefresh: widget.currentAuthRefresh, credentials: credentials, userCredential: userCredential));
                        }
                      }
                      on FirebaseAuthException catch(e){
                        switch(e.code){
                          case 'invalid-verification-code' : 
                            Fluttertoast.showToast(msg: 'Invalid SMS code', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
                            break;
                          case 'session-expired' : 
                            Fluttertoast.showToast(msg: 'Session expired. SMS sent again', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
                            break;
                          default :
                            Fluttertoast.showToast(msg: 'Error', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
                        }
                        
                        print(e);
                      }
                      finally{
                        if(mounted){
                          setState(() {
                            displayProgress = false;
                          });
                        }
                      }
                    }
                    else{
                      sendSmsMessage();
                    }

                  }, 
                  
                  splashColor: globalBlue,
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.025),
                    child: Text('CONTINUE', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                  )
                )
              )
        ]
      )
    );
  }

  void sendSmsMessage() {
    finalPhoneNumber = '+$countryPrefix${_phoneController.text}';

    widget.firebaseAuth.verifyPhoneNumber(
      phoneNumber: finalPhoneNumber,

      verificationCompleted: (PhoneAuthCredential credential) async {

        await widget.firebaseAuth.signInWithCredential(credential);
      }, 
      verificationFailed: (FirebaseAuthException e) {
        if(e.code == 'invalid-phone-number'){
          Fluttertoast.showToast(msg: 'Invalid phone number', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
        }

        print(e);
      }, 
      codeSent: (verificationId, forceResendingToken) => {

        if(mounted){
          setState(() {
            displayProgress = false;
            this.verificationId = verificationId;
            codeSent = true;
          })
        },

        Fluttertoast.showToast(msg: 'SMS Code sent', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue),
      }, 
      codeAutoRetrievalTimeout: (verificationId){

        if(FirebaseAuth.instance.currentUser != null){
          return;
        }

        this.verificationId = verificationId;
        sendSmsMessage();
      }
    );
  }
}