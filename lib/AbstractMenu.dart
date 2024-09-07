import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/Auth.dart';
import 'package:doom_chain/CreateChainCategory.dart';
import 'package:doom_chain/CreateChainDetails.dart';
import 'package:doom_chain/CreateChainPage.dart';
import 'package:doom_chain/CreateChainTagsPage.dart';
import 'package:doom_chain/ProfileEditDetails.dart';
import 'package:doom_chain/ProfileSettings.dart';
import 'package:doom_chain/ProfileViewChains.dart';
import 'package:doom_chain/UnchainedPage.dart';
import 'package:doom_chain/main.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'ExplorePage.dart';
import 'ProfilePage.dart';
import 'FriendsPage.dart';
import 'FriendsPageStrangers.dart';
import 'package:workmanager/workmanager.dart';

class AbstractMenu extends StatefulWidget{

  final String phoneOrEmail;

  AbstractMenu({required this.phoneOrEmail});

  @override
  _AbstractMenu createState() => _AbstractMenu();

  static String generateRandomId(int length){
    String val = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';

    Random random = Random.secure();

    return List.generate(length, (index) => val[random.nextInt(val.length)]).join('');
  }
}

class _AbstractMenu extends State<AbstractMenu> with TickerProviderStateMixin{

  late final DocumentSnapshot userDetails;

  late AnimationController _animationOpacity;
  late AnimationController _animationOpacityIconExplore;
  late AnimationController _animationOpacityIconUnchained;
  late AnimationController _animationOpacityIconFriends;
  late AnimationController _animationOpacityIconProfile;

  late Widget currentPage;

  String topImageAsset = 'assets/image/explore.png';
  String topTitle = 'Explore';
  String lastTopTile = 'Explore';
  Color topTitleColor = const Color.fromARGB(255, 102, 0, 255);

  bool friendsPage = false;
  bool lastFriendsButtonMode = false;
  bool profilePage = false;
  bool unchainedPage = false;
  bool explorePage = true;

  @override
  void initState(){
    super.initState();

    _setUserIdentifier();

    currentPage = ExplorePage(exploreData: {
      'userId' : widget.phoneOrEmail
    }, changePageHeader: changePageHeader, key: null);

    _animationOpacity = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacityIconExplore = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacityIconUnchained = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacityIconFriends = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacityIconProfile = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationOpacity.forward();
    _animationOpacityIconExplore.forward();
    _animationOpacityIconUnchained.forward();
    _animationOpacityIconFriends.forward();
    _animationOpacityIconProfile.forward();

    Workmanager().registerPeriodicTask(
      '1', 
      'listenerTask',
      frequency: const Duration(minutes: 15),
      inputData: {
        'userId' : widget.phoneOrEmail
      }
    );

    //MyApp.platform.invokeMethod('startNotif', {'userId' : widget.phoneOrEmail});
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return SafeArea(
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.only(left: width * 0.05, right: width * 0.025, top: width * 0.025, bottom: width * 0.025),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacity, curve: Curves.easeOut)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.all(width * 0.02),
                      child: Image.asset(topImageAsset, fit: BoxFit.fill, width: width * 0.12, height: width * 0.12),
                    ),

                    Padding(
                      padding: EdgeInsets.all(width * 0.02),
                      child: Text(topTitle, style: GoogleFonts.nunito(fontSize: width * 0.05, color: topTitleColor, fontWeight: FontWeight.bold))
                    ),

                    Visibility(
                      visible: friendsPage,
                      child: const Spacer(),
                    ),

                    Visibility(
                      visible: friendsPage,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.02),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              lastFriendsButtonMode = false;
                            });
                            
                            changePageHeader('Friends', null);
                          }, 
                          icon: Image.asset('assets/image/list.png', width: width * 0.1, height: width * 0.1, color: const Color.fromARGB(255, 102, 0, 255))
                        )
                      )
                    ),

                    Visibility(
                      visible: friendsPage,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.02),
                        child: IconButton(
                          onPressed: () {
                            setState(() {
                              lastFriendsButtonMode = true;
                            });
                            changePageHeader('Strangers', null);
                          }, 
                          icon: Image.asset('assets/image/addfriends.png', width: width * 0.1, height: width * 0.1, color: const Color.fromARGB(255, 102, 0, 255))
                        )
                      )
                    ),

                    Visibility(
                      visible: profilePage,
                      child: const Spacer()
                    ),

                    Visibility(
                      visible: profilePage,
                      child: Builder(
                        builder: (context) {
                          return Padding(
                            padding: EdgeInsets.all(width * 0.02),
                            child: IconButton(
                              onPressed: () {
                                Scaffold.of(context).openEndDrawer();
                              }, 
                              icon: Image.asset('assets/image/slidemenu.png', width: width * 0.1, height: width * 0.1, color: const Color.fromARGB(255, 102, 0, 255))
                            )
                          );
                        }
                      )
                    ),

                    Visibility(
                      visible: unchainedPage,
                      child: const Spacer()
                    ),

                    Visibility(
                      visible: unchainedPage,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.02),
                        child: IconButton(
                          onPressed: () {
                            changePageHeader('Unchained (refresh)', null);
                          }, 
                          icon: Image.asset('assets/image/refresh.png', width: width * 0.05, height: width * 0.05, color: const Color.fromARGB(255, 102, 0, 255))
                        )
                      )
                    ),

                    Visibility(
                      visible: explorePage,
                      child: const Spacer()
                    ),

                    Visibility(
                      visible: explorePage,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.02),
                        child: IconButton(
                          onPressed: () {
                            changePageHeader('Explore (refresh)', null);
                          }, 
                          icon: Image.asset('assets/image/refresh.png', width: width * 0.05, height: width * 0.05, color: const Color.fromARGB(255, 102, 0, 255))
                        )
                      )
                    ),
                  ],
                )
              )
            ),

            Expanded(
              child: Stack(
                children: [
                  Align(
                    alignment: Alignment.center,
                    child: FadeTransition(
                      opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacity, curve: Curves.easeOut)),
                      child: Column(
                        children: [
                          Expanded(
                            child: currentPage
                          ),

                          Visibility(
                            visible: unchainedPage,
                              child: SizedBox(
                                height: width * 0.32,
                                width: width,
                              ),
                            )
                        ],
                      ),
                    )
                  ),

                  Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.9), Colors.white, Colors.white]
                        )
                      ),
                      child: Padding(
                        padding: EdgeInsets.only(top: width * 0.05, bottom: width * 0.05),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityIconExplore, curve: Curves.easeOut)),
                              child: Padding(
                                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
                                child: IconButton(
                                  onPressed: () {
                                    changePageHeader('Explore', null);
                                    animateOpacity(_animationOpacityIconExplore);
                                  }, 
                                  icon: Image.asset('assets/image/explore.png', fit: BoxFit.fill, width: width * 0.12, height: width * 0.12)
                                ),
                              )
                            ),

                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityIconUnchained, curve: Curves.easeOut)),
                              child: Padding(
                                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
                                child: IconButton(
                                  onPressed: () {
                                    changePageHeader('Unchained', null);
                                    animateOpacity(_animationOpacityIconUnchained);
                                  }, 
                                  icon: Image.asset('assets/image/newchain.png', fit: BoxFit.fill, width: width * 0.12, height: width * 0.12)
                                ),
                              )
                            ),

                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityIconFriends, curve: Curves.easeOut)),
                              child: Padding(
                                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
                                child: IconButton(
                                  onPressed: () {
                                    changePageHeader('Friends', null);
                                    animateOpacity(_animationOpacityIconFriends);
                                  }, 
                                  icon: Image.asset('assets/image/friends.png', fit: BoxFit.fill, width: width * 0.12, height: width * 0.12)
                                ),
                              )
                            ),

                            FadeTransition(
                              opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationOpacityIconProfile, curve: Curves.easeOut)),
                              child: Padding(
                                padding: EdgeInsets.only(left: width * 0.025, right: width * 0.025),
                                child: IconButton(
                                  onPressed: () {
                                    changePageHeader('Profile', {
                                      'userId' : widget.phoneOrEmail
                                    });
                                    animateOpacity(_animationOpacityIconProfile);
                                  }, 
                                  icon: Image.asset('assets/image/profile.png', fit: BoxFit.fill, width: width * 0.12, height: width * 0.12)
                                ),
                              )
                            )
                          ],
                        ),
                      )
                    )
                  ),
                ],
              )
            )
          ],
        ),

        endDrawer: Builder(
          builder: (context) {
            return Drawer(
              backgroundColor: Colors.grey[200],
              child: ListView(
                children: [

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.1, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/star.png', width: width * 0.075, height: width * 0.075, color: const Color.fromARGB(255, 102, 0, 255)),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: const Color.fromARGB(255, 102, 0, 255).withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Liked Chains', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Profile (liked chains)', {
                          'userId' : widget.phoneOrEmail
                        });

                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/save.png', width: width * 0.075, height: width * 0.075, color: const Color.fromARGB(255, 102, 0, 255)),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: const Color.fromARGB(255, 102, 0, 255).withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Saved Chains', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Profile (saved chains)', {
                          'userId' : widget.phoneOrEmail
                        });

                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/info.png', width: width * 0.075, height: width * 0.075, color: const Color.fromARGB(255, 102, 0, 255)),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: const Color.fromARGB(255, 102, 0, 255).withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Edit profile', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Profile (edit profile)', null);
                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/key.png', width: width * 0.075, height: width * 0.075, color: const Color.fromARGB(255, 102, 0, 255)),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: const Color.fromARGB(255, 102, 0, 255).withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Settings', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        changePageHeader('Settings', null);
                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.025),
                    child: ListTile(
                      leading: Image.asset('assets/image/signout.png', width: width * 0.075, height: width * 0.075, color: const Color.fromARGB(255, 102, 0, 255)),
                      trailing: const Icon(Icons.arrow_right),
                      splashColor: const Color.fromARGB(255, 102, 0, 255).withOpacity(0.1),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15))
                      ),
                      title: Text('Sign Out', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      onTap: () {
                        
                        showDialog(
                          context: context, 
                          builder: (context){
                            return AlertDialog(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/image/info.png', width: width * 0.1, height: width * 0.1),
                                  Text('Sign Out', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.black87, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              content: Text('Are you sure you want to sign out?', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                              actions: [
                                Padding(
                                  padding: EdgeInsets.all(width * 0.01),
                                  child: Material(
                                    color: const Color.fromARGB(255, 102, 0, 255),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: InkWell(
                                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                                      onTap: () async {
                                        await FirebaseAuth.instance.signOut();
                                        await GoogleSignIn().signOut();

                                        if(mounted){
                                          Navigator.of(context).popUntil((route) => route.isFirst);
                                        }

                                        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => Auth(width: width)));
                                      }, 
                                      splashColor: const Color.fromARGB(255, 30, 144, 255),
                                      child: Padding(
                                        padding: EdgeInsets.all(width * 0.025),
                                        child: Text('Yeah', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                                      )
                                    )
                                  )
                                ),

                                const Spacer(),

                                Padding(
                                  padding: EdgeInsets.all(width * 0.01),
                                  child: Material(
                                    color: const Color.fromARGB(255, 102, 0, 255),
                                    shape: const RoundedRectangleBorder(
                                      borderRadius: BorderRadius.all(Radius.circular(15))
                                    ),
                                    child: InkWell(
                                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                                      onTap: () async {
                                        if(mounted){
                                          Navigator.of(context).popUntil((route) => route.isFirst);
                                        }
                                      }, 
                                      splashColor: const Color.fromARGB(255, 30, 144, 255),
                                      child: Padding(
                                        padding: EdgeInsets.all(width * 0.025),
                                        child: Text('Close', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                                      )
                                    )
                                  )
                                )
                              ]
                            );
                          }
                        );

                        Scaffold.of(context).closeEndDrawer();
                      },
                    ),
                  ),

                  Text('©Copyright omuletzu\nDumbChain', style: GoogleFonts.nunito(fontSize: width * 0.025, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                ]
              )
            );
          }
        )
      ),
    );
  }

  void changePageHeader(String title, Map<String, dynamic>? addData) {

    _animationOpacity.reset();
    _animationOpacity.forward();

    String assetPath = ' ';
    Widget page = ExplorePage(exploreData: {'userId' : widget.phoneOrEmail}, changePageHeader: changePageHeader, key: null);

    switch(title){
      case 'Explore' :
        assetPath = 'assets/image/explore.png';
        page = ExplorePage(exploreData: {'userId' : widget.phoneOrEmail}, changePageHeader: changePageHeader, key: null);
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          profilePage = false;
          unchainedPage = false;
          explorePage = true;
        });
        break;

      case 'Explore (refresh)' :
        assetPath = 'assets/image/explore.png';
        page = ExplorePage(exploreData: {'userId' : widget.phoneOrEmail}, changePageHeader: changePageHeader, key: UniqueKey());
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          profilePage = false;
          unchainedPage = false;
        });
        break;

      case 'Unchained' :
        assetPath = 'assets/image/newchain.png';
        page = UnchainedPage(changePageHeader: changePageHeader, userId: widget.phoneOrEmail, key: null);
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          profilePage = false;
          unchainedPage = true;
          explorePage = false;
        });
        break;

      case 'Unchained (refresh)' :
        assetPath = 'assets/image/newchain.png';
        page = UnchainedPage(changePageHeader: changePageHeader, userId: widget.phoneOrEmail, key: UniqueKey());
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          profilePage = false;
          unchainedPage = true;
          explorePage = false;
        });
        break;

      case 'Friends' :
        assetPath = 'assets/image/friends.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = true;
          profilePage = false;
          unchainedPage = false;
          explorePage = false;
        });

        page = FriendsPage(
          userId: widget.phoneOrEmail,
          changePageHeader: changePageHeader,
        );
        break;

      case 'Strangers' :
        assetPath = 'assets/image/friends.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = true;
          profilePage = false;
          unchainedPage = false;
          explorePage = false;
        });
       
        page = FriendsPageStrangers(
          userId: widget.phoneOrEmail,
          changePageHeader: changePageHeader,
        );
        break;

      case 'Profile' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          profilePage = true;
          unchainedPage = false;
          explorePage = false;
        });

        page = ProfilePage(
          changePageHeader: changePageHeader,
          userId: addData!['userId'],
          isThisUser: true,
          key: UniqueKey());

        break;

      case 'Profile (friend)' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          profilePage = false;
          unchainedPage = false;
        });

        page = ProfilePage(
          changePageHeader: changePageHeader,
          userId: addData!['userId'],
          isThisUser: false,
          key: null);

        break;

      case 'Profile (chains)' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          unchainedPage = false;
        });

        page = ProfileViewChains(
          changePageHeader: changePageHeader, 
          userData: addData!,
          personalLikedSavedChains: 0);
        break;

      case 'Profile (liked chains)' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          unchainedPage = false;
        });

        page = ProfileViewChains(
          changePageHeader: changePageHeader, 
          userData: addData!,
          personalLikedSavedChains: 1);
        break;

      case 'Profile (saved chains)' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          unchainedPage = false;
        });

        page = ProfileViewChains(
          changePageHeader: changePageHeader, 
          userData: addData!,
          personalLikedSavedChains: 2);
        break;

      case 'Profile (edit profile)' :
        assetPath = 'assets/image/profile.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          unchainedPage = false;
        });

      case 'Settings' :
        assetPath = 'assets/image/key.png';
        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
          friendsPage = false;
          unchainedPage = false;
        });

        page = ProfileSettings(
          changePageHeader: changePageHeader, 
          userId: widget.phoneOrEmail
        );
        break;

      case 'New chain (story)' :
        assetPath = 'assets/image/book.png';
        addData!['categoryType'] = 0;
        page = CreateChain(changePageHeader: changePageHeader, addData: addData);

        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
        });

      case 'New chain (category)' :
        assetPath = 'assets/image/create.png';
        page = CreateChainCategory(changePageHeader: changePageHeader, userId: widget.phoneOrEmail);

        setState(() {
          topTitleColor = const Color.fromARGB(255, 102, 0, 255);
        });

      case 'New chain (details)' :
        assetPath = 'assets/image/book.png';
        page = CreateChainTagsPage(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (tags)' :
        assetPath = 'assets/image/book.png';
        page = CreateChainDetails(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (gossip)' :
        assetPath = 'assets/image/gossip.png';
        addData!['categoryType'] = 1;
        page = CreateChain(changePageHeader: changePageHeader, addData: addData);

        setState(() {
          topTitleColor = const Color.fromARGB(255, 30, 144, 255);
        });

      case 'New chain (gossip details)' :
        assetPath = 'assets/image/gossip.png';
        page = CreateChainTagsPage(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (gossip tags)' :
        assetPath = 'assets/image/gossip.png';
        page = CreateChainDetails(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (challange)' :
        assetPath = 'assets/image/challange.png';
        addData!['categoryType'] = 2;
        page = CreateChain(changePageHeader: changePageHeader, addData: addData);

        setState(() {
          topTitleColor = const Color.fromARGB(255, 0, 150, 136);
        });

      case 'New chain (challange details)' :
        assetPath = 'assets/image/challange.png';
        page = CreateChainTagsPage(changePageHeader: changePageHeader, addData: addData);

      case 'New chain (challange tags)' :
        assetPath = 'assets/image/challange.png';
        page = CreateChainDetails(changePageHeader: changePageHeader, addData: addData);

      default :
        assetPath = 'assets/image/explore.png';
        page = ExplorePage(exploreData: {'userId' : widget.phoneOrEmail}, changePageHeader: changePageHeader, key: null);
        break;
    }

    lastTopTile = topTitle;

    if(mounted){
      setState(() {
        topImageAsset = assetPath;
        topTitle = title;
        currentPage = page;
      });
    }
  }

  void animateOpacity(AnimationController animationOpacity){
    animationOpacity.reset();
    animationOpacity.forward();

    _animationOpacity.reset();
    _animationOpacity.forward();
  }

  Future<void> _setUserIdentifier() async{
    SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
    await sharedPreferences.setString('userId', widget.phoneOrEmail);
  }
}