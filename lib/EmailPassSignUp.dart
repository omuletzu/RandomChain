import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/AditionalData.dart';
import 'package:doom_chain/EmailPassSignIn.dart';
import 'package:doom_chain/GlobalColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'PhoneAuth.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'Auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fluttertoast/fluttertoast.dart';

class EmailPassSignUp extends StatefulWidget{

  final void Function(Widget) currentAuthRefresh;
  final FirebaseAuth firebaseAuth;
  final FirebaseFirestore firebaseFirestore;

  EmailPassSignUp({required this.currentAuthRefresh, required this.firebaseAuth, required this.firebaseFirestore});

  @override
  _EmailPassSignUp createState() => _EmailPassSignUp();
}

class _EmailPassSignUp extends State<EmailPassSignUp>{

  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passController = TextEditingController();
  final TextEditingController _confPassController = TextEditingController();

  bool hidePass = true;
  bool hideConfPass = true;
  bool displayProgress = false;

  @override
  Widget build(BuildContext context){

     final double width = MediaQuery.of(context).size.width;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Center(
              child: Text('Sign Up', style: GoogleFonts.nunito(fontSize: width * 0.10, color: Colors.black87, fontWeight: FontWeight.bold)),
            ),

            Padding(
              padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025, left: width * 0.075, right: width * 0.075),
              child: TextField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: 'Email',
                    hintStyle: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                  ),
                style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025, left: width * 0.075, right: width * 0.075),
              child: TextField(
                  controller: _passController,
                  obscureText: hidePass,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                    suffixIcon: IconButton(
                      onPressed: () {
                        if(mounted){
                          setState(() {
                            hidePass = !hidePass;
                          });
                        }
                      }, 
                      icon: hidePass ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                    )
                  ),
                style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025, left: width * 0.075, right: width * 0.075),
              child: TextField(
                  controller: _confPassController,
                  obscureText: hideConfPass,
                  decoration: InputDecoration(
                    hintText: 'Confirm password',
                    hintStyle: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                    suffixIcon: IconButton(
                      onPressed: () {
                        if(mounted){
                          setState(() {
                            hideConfPass = !hideConfPass;
                          });
                        }
                      }, 
                      icon: hideConfPass ? const Icon(Icons.visibility_off) : const Icon(Icons.visibility)
                    )
                  ),
                style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold),
              ),
            ),

            Padding(
              padding: EdgeInsets.all(width * 0.025),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: IconButton(
                      onPressed: () {
                        
                      }, 
                      icon: Image.asset('assets/image/mailpass.png', width: width * 0.1, height: width * 0.1)
                    )
                  ),

                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: IconButton(
                      onPressed: () {
                        widget.currentAuthRefresh(PhoneAuth(currentAuthRefresh: widget.currentAuthRefresh, firebaseAuth: widget.firebaseAuth, width: width, firebaseFirestore: widget.firebaseFirestore));
                      }, 
                      icon: Image.asset('assets/image/phone.png', width: width * 0.1, height: width * 0.1)
                    )
                  ),

                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: IconButton(
                      onPressed: () {
                        Auth.googleAuth(context, widget.firebaseAuth, widget.firebaseFirestore, widget.currentAuthRefresh, width);
                      }, 
                      icon: Image.asset('assets/image/googleicon.png', width: width * 0.1, height: width * 0.1)
                    )
                  )
                ],
              )
            ),

            displayProgress ? const CircularProgressIndicator()
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(width * 0.05),
                      child: Material(
                        color: globalPurple,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))
                        ),
                        child: InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          onTap: () async {

                            if(mounted){
                              setState(() {
                                displayProgress = true;
                              });
                            }

                            if(_emailController.text.isNotEmpty && _passController.text.isNotEmpty && _confPassController.text.isNotEmpty && _passController.text == _confPassController.text){

                              try{
                                UserCredential userCredential = await widget.firebaseAuth.createUserWithEmailAndPassword(email: _emailController.text.trim(), password: _passController.text);

                                SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
                                sharedPreferences.setBool('lastAuthPhone', false);
                                widget.currentAuthRefresh(AditionalData(firebaseAuth: widget.firebaseAuth, width: width, firebaseFirestore: widget.firebaseFirestore, phoneOrEmail: _emailController.text.trim(), currentAuthRefresh: widget.currentAuthRefresh, credentials: null, userCredential: userCredential));
                              }
                              on FirebaseAuthException catch(e){
                                switch(e.code){
                                  case 'email-already-in-use' : 
                                    Fluttertoast.showToast(msg: 'Email already in use', toastLength: Toast.LENGTH_LONG, backgroundColor: const Color.fromARGB(255, 30, 144, 255));
                                    break;

                                  case 'invalid-email' :
                                    Fluttertoast.showToast(msg: 'Invalid email', toastLength: Toast.LENGTH_LONG, backgroundColor: const Color.fromARGB(255, 30, 144, 255));
                                    break;

                                  case 'weak-password' :
                                    Fluttertoast.showToast(msg: 'Too weak password', toastLength: Toast.LENGTH_LONG, backgroundColor: const Color.fromARGB(255, 30, 144, 255));
                                    break;

                                  default : 
                                    Fluttertoast.showToast(msg: 'Error', toastLength: Toast.LENGTH_LONG, backgroundColor: const Color.fromARGB(255, 30, 144, 255));
                                }
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
                              if(_passController.text.trim() != _confPassController.text.trim()){
                                Fluttertoast.showToast(msg: 'Passwords don\'t match', toastLength: Toast.LENGTH_LONG, backgroundColor: const Color.fromARGB(255, 30, 144, 255));
                              }

                              if(mounted){
                                setState(() {
                                  displayProgress = false;
                                });
                              }
                            }

                          }, 
                          splashColor: const Color.fromARGB(255, 30, 144, 255),
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.025),
                            child: Text('Sign Up', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                          )
                        )
                      )
                    ),

                    Text('or', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold)),

                    Padding(
                      padding: EdgeInsets.all(width * 0.05),
                      child: Material(
                        color: Colors.black87,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))
                        ),
                        child: InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          onTap: () async {
                            widget.currentAuthRefresh(EmailPassSignIn(currentAuthRefresh: widget.currentAuthRefresh, firebaseAuth: widget.firebaseAuth, firebaseFirestore: widget.firebaseFirestore));
                          }, 
                          splashColor: globalPurple,
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.025),
                            child: Text('Sign In', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                          )
                        )
                      )
                    )
                  ],
                )
          ]
        )
      )
    );
  }
}