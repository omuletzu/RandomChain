import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:doom_chain/PhoneAuth.dart';
import 'package:flutter/material.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'AbstractMenu.dart';
import 'AditionalData.dart';

class Auth extends StatefulWidget{

  final double width;

  Auth({required this.width});

  @override
  _Auth createState() => _Auth();

  static void googleAuth(BuildContext context, FirebaseAuth firebaseAuth, FirebaseFirestore firebaseFirestore, void Function(Widget) currentAuthRefresh, double width) async {
    try{

      GoogleSignIn googleSignIn = GoogleSignIn();

      GoogleSignInAccount? googleSignInAccount = await googleSignIn.signIn();

      if(googleSignInAccount == null){
        Fluttertoast.showToast(msg: 'Please retry', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
        return;
      }

      final GoogleSignInAuthentication googleSignInAuthentication = await googleSignInAccount.authentication;

      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleSignInAuthentication.accessToken,
        idToken: googleSignInAuthentication.idToken
      );

      UserCredential userCredential = await firebaseAuth.signInWithCredential(credential);

      DocumentSnapshot documentSnapshot = await firebaseFirestore.collection('UserDetails').doc(userCredential.user?.uid).get();

      if(documentSnapshot.exists){
        if(userCredential.user?.phoneNumber != null){
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AbstractMenu(uid: userCredential.user?.phoneNumber ?? ' ')));
        }
        else{
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AbstractMenu(uid: userCredential.user?.email ?? ' ')));
        }
      }
      else{
        currentAuthRefresh(AditionalData(firebaseAuth: firebaseAuth, width: width, firebaseFirestore: firebaseFirestore, currentAuthRefresh: currentAuthRefresh, credentials: null, userCredential: userCredential));
      }
      
    }
    catch(e){
      print(e);
      Fluttertoast.showToast(msg: 'Error', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
    }
  }
}

class _Auth extends State<Auth> with TickerProviderStateMixin{
  
  final FirebaseAuth firebaseAuth = FirebaseAuth.instance;
  final FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;

  late AnimationController _animationController;
  late Widget currentAuth = PhoneAuth(currentAuthRefresh: currentAuthRefresh, firebaseAuth: firebaseAuth, width: widget.width, firebaseFirestore: firebaseFirestore);

  late AnimationController _animationOpacityContainer;

  List<String> typedStrings = ['Be random', 'Be funny', 'Be dramatic', 'Be chained'];
  int typedStringIndex = 0;
  int lastTypedStringIndex = 0;

  Random random = Random();

  @override
  void initState(){
    super.initState();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2)
    );

    _animationController.forward();

    _animationOpacityContainer = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1)
    );

    _animationOpacityContainer.forward();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.0, -1.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
              child: Row(
                children: [
                    SlideTransition(
                    position: Tween<Offset>(begin: const Offset(0.0, -1.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.1),
                      child: Image.asset('assets/image/logo.png', fit: BoxFit.fill, width: width * 0.15, height: width * 0.15)
                    )
                  ),

                  AnimatedTextKit(
                    repeatForever: true,
                    isRepeatingAnimation: true,
                    animatedTexts: [
                      TypewriterAnimatedText(
                        typedStrings[typedStringIndex],
                        speed: const Duration(milliseconds: 500),
                        textStyle: GoogleFonts.courierPrime(fontSize: width * 0.05, color: globalPurple, fontWeight: FontWeight.bold)
                      )
                    ],

                    onNextBeforePause: (p0, finished) => {

                      lastTypedStringIndex = typedStringIndex,

                      if(finished){
                        setState(() {
                          while(typedStringIndex == lastTypedStringIndex){
                            typedStringIndex = random.nextInt(typedStrings.length);
                          }
                        })
                      }
                    },
                  )
                ],
              )
            ),

            Expanded(
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityContainer, curve: Curves.easeOut)),
                child: currentAuth,
              ),
            ),

            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.0, 1.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationController, curve: Curves.easeOut)),
              child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Center(
                  child: Text('RandomChain', style: GoogleFonts.nunito(fontSize: width * 0.1, color: Colors.black87, fontWeight: FontWeight.bold)),
                ),
              )
            ),
          ],
        )
      )
    );
  }

  void currentAuthRefresh(Widget newAuth) async {

    setState(() {
      currentAuth = newAuth;
    });

    _animationOpacityContainer.reset();
    _animationOpacityContainer.forward();
  }
}