import 'dart:async';

import 'package:doom_chain/AbstractMenu.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'Auth.dart';

class SplashScreen extends StatefulWidget {

  final double width;

  SplashScreen({required this.width});

  @override
  _SplashScreen createState() => _SplashScreen();
}

class _SplashScreen extends State<SplashScreen> with TickerProviderStateMixin{

  late AnimationController _animationAfterSplash;

  bool splashFinished = true;

  @override
  void initState(){
    super.initState();

    _checkForDarkMode();
    
    _animationAfterSplash = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1)
    );

    Timer(const Duration(seconds: 1, milliseconds: 750), () async { 
      _checkForAlreadyLogged();
    });
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: globalBackground,
      body: Stack(
        children: [
          Container(
            constraints: const BoxConstraints.expand(),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                const Spacer(),

                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.0, 0.0), end: const Offset(0.0, -2.5)).animate(CurvedAnimation(parent: _animationAfterSplash, curve: Curves.easeIn)),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.1),
                    child: Image.asset('assets/image/logo.png', fit: BoxFit.fill, width: width * 0.5, height: width * 0.5, color: globalTextBackground),
                  )
                ),

                const Spacer(),

                SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.0, 0.0), end: const Offset(0.0, 2.5)).animate(CurvedAnimation(parent: _animationAfterSplash, curve: Curves.easeIn)),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.075),
                    child: Text('©Copyright omuletzu\nRandomChain', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey[800], fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )
                )
              ],
            ),
          )
        ],
      )
    );
  }

  Future<void> _checkForDarkMode() async {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    bool darkModeEnabled = sharedPreferences.getBool('darkModeEnabled') ?? true;

    if(darkModeEnabled){
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
  }

  void _checkForAlreadyLogged() async 
  {
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();

    FirebaseAuth firebaseAuth = FirebaseAuth.instance;

    if(firebaseAuth.currentUser != null){
      if(firebaseAuth.currentUser?.phoneNumber != null){
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AbstractMenu(phoneOrEmail: firebaseAuth.currentUser?.phoneNumber ?? ' ')));
      }
      else{
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => AbstractMenu(phoneOrEmail: firebaseAuth.currentUser?.email ?? ' ')));
      }
    }
    else{
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => Auth(width: widget.width)));
    }

    globalWidth = MediaQuery.of(context).size.width;
  }

  @override
  void dispose(){
    super.dispose();
    _animationAfterSplash.dispose();
  }
}