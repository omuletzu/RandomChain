import 'dart:convert';
import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:doom_chain/Pair.dart';
import 'package:doom_chain/ProfilePage.dart';
import 'package:doom_chain/UnchainedViewChain.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';

class FriendElement extends StatefulWidget{
  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final String userId;
  final String friendId;
  final bool friendOrStranger;
  final bool isThisRequests;
  final String userNickname;
  final void Function() increaseFriendCount;
  final Map<String, dynamic>? friendData;
  final FirebaseFirestore firebase;
  final FirebaseStorage storage;

  FriendElement({required this.userId, 
    required this.friendId,
    required this.firebase, 
    required this.friendOrStranger,
    required this.isThisRequests,
    required this.userNickname,
    required this.increaseFriendCount,
    required this.storage,  
    required this.friendData,
    required this.changePageHeader}
  );

  @override
  _FriendElement createState() => _FriendElement();
}

class _FriendElement extends State<FriendElement>{

  String containerImageUrl = '';
  bool friendDetailsLoaded = false;
  bool containerImageLoaded = false;
  bool hasImage = false;
  bool friendAddedOrNot = false;
  late CachedNetworkImage pfpImage;

  String friendNickname = '';

  @override 
  void initState() {
    super.initState();
    _retreiveDataFromFirebase();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return Padding(
      padding: EdgeInsets.all(width * 0.025),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: Material(
          color: Colors.grey.withOpacity(0.1),
          child: InkWell(
            splashColor: globalPurple.withOpacity(0.1),
            
            onTap: () {
              widget.changePageHeader('Profile (friend)', {
                'userId' : widget.friendId,
              });
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                border: Border.all(width: 2.0, color: friendDetailsLoaded ? getRandomColor() : Colors.transparent),
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                color: Colors.grey.withOpacity(0.1)
              ),
              child: Column(
                children: [

                  Padding(
                    padding: EdgeInsets.all(width * 0.025),
                    child: Text(friendDetailsLoaded ? friendNickname : ' ', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),

                  Padding(
                    padding: EdgeInsets.all(width * 0.025),
                    child: ClipOval(
                      child: hasImage 
                        ? pfpImage
                      : Image.asset('assets/image/profile.png', width: width * 0.15, height: width * 0.15)
                    )
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [

                      Visibility(
                        visible: widget.isThisRequests && !friendAddedOrNot,
                        child: IconButton(
                          onPressed: () async {
                            setState(() {
                              friendAddedOrNot = true;
                              Fluttertoast.showToast(msg: 'Added ${widget.friendData!['nickname']}', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                            });
                          }, 
                          icon: Image.asset('assets/image/add.png', width: width * 0.075, height: width * 0.075, color: globalTextBackground)
                        )
                      ),

                      Visibility(
                        visible: !widget.friendOrStranger,
                        child: !friendAddedOrNot 
                          ? IconButton(
                              onPressed: () async {
                                setState(() {
                                  friendAddedOrNot = true;
                                  Fluttertoast.showToast(msg: 'Sent request to ${widget.friendData!['nickname']}', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                                });
                              }, 
                              icon: Image.asset('assets/image/add.png', width: width * 0.075, height: width * 0.075, color: globalTextBackground)
                            )
                          : IconButton(
                              onPressed: () async {
                                setState(() {
                                  friendAddedOrNot = false;
                                });
                              }, 
                              icon: Image.asset('assets/image/minus.png', width: width * 0.075, height: width * 0.075, color: globalTextBackground)
                            )
                      ),

                      IconButton(
                        onPressed: () {
                          showDialog(
                            context: context, 
                            builder: (context){
                              return AlertDialog(
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ClipOval(
                                      child: pfpImage
                                    )
                                  ],
                                ),
                                actionsAlignment: MainAxisAlignment.center,
                                content: Text('${widget.friendData!['nickname']}', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                actions: [
                                  Padding(
                                    padding: EdgeInsets.all(width * 0.01),
                                    child: Material(
                                      color: globalPurple,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                      ),
                                      child: InkWell(
                                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                                        onTap: () async {
                                          widget.firebase.collection('UserDetails').doc(widget.userId).collection('BlockedUsers').doc(widget.friendId).set({});
                                          widget.firebase.collection('UserDetails').doc(widget.userId).collection('Friends').doc(widget.friendId).delete();
                                          widget.firebase.collection('UserDetails').doc(widget.friendId).collection('Friends').doc(widget.userId).delete();
                                          Navigator.of(context).pop();
                                          Fluttertoast.showToast(msg: '${widget.friendData!['nickname']} blocked', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                                        }, 
                                        splashColor: globalBlue,
                                        child: Padding(
                                          padding: EdgeInsets.all(width * 0.025),
                                          child: Text('Block', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                                        )
                                      )
                                    )
                                  ),

                                  Padding(
                                    padding: EdgeInsets.all(width * 0.01),
                                    child: Material(
                                      color: globalPurple,
                                      shape: const RoundedRectangleBorder(
                                        borderRadius: BorderRadius.all(Radius.circular(15))
                                      ),
                                      child: InkWell(
                                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                                        onTap: () async {
                                          showBlockDialog(widget.friendData!['nickname'], width);
                                        }, 
                                        splashColor: globalBlue,
                                        child: Padding(
                                          padding: EdgeInsets.all(width * 0.025),
                                          child: Text('Report', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                                        )
                                      )
                                    )
                                  )
                                ]
                              );
                            }
                          );
                        }, 
                        icon: Image.asset('assets/image/details.png', width: width * 0.05, height: width * 0.05, color: globalTextBackground)
                      )
                    ],
                  )
                ],
              )
            )
          )
        )
      )
    );
  }

  Future<void> _retreiveDataFromFirebase() async {

    if(widget.friendData != null){
      
      if(widget.friendData!['avatarPath'] != '-'){
        
        try{
          Reference reference = widget.storage.ref().child(widget.friendData!['avatarPath']);
          containerImageUrl =  await reference.getDownloadURL();

          if(mounted){
            setState(() {
              hasImage = true;
            });
          }
        }
        catch(e){
          print(e);
        }
      }

      friendNickname = widget.friendData!['nickname'];
    }

    pfpImage = CachedNetworkImage(
      imageUrl: containerImageUrl,
      width: globalWidth * 0.15,
      height: globalWidth * 0.15,
      fit: BoxFit.cover,
      placeholder: (context, url) => const CircularProgressIndicator(),
      errorWidget: (context, url, error) => Icon(Icons.error, size: globalWidth * 0.25)
    );

    if(mounted){
      setState(() {
        friendDetailsLoaded = true;
      });
    }
  }

  Color getRandomColor(){
    Random random = Random();
    int index = random.nextInt(1);

    if(index == 0){
      return globalPurple;
    }

    if(index == 1){
      return globalBlue;
    }

    return globalGreen;
  }

  void _addFriend() async {

    if(widget.isThisRequests){

      widget.increaseFriendCount();

      widget.firebase.collection('UserDetails').doc(widget.friendId).update({
        'friendsCount' : widget.friendData!['friendsCount']
      });

      widget.firebase.collection('UserDetails').doc(widget.userId).collection('FriendRequests').doc(widget.friendId).delete();

      widget.firebase.collection('UserDetails').doc(widget.userId).collection('Friends').doc(widget.friendId).set({});

      widget.firebase.collection('UserDetails').doc(widget.friendId).collection('Friends').doc(widget.userId).set({});
    }
    else{

      widget.firebase.collection('UserDetails').doc(widget.friendId).collection('FriendRequests').doc(widget.userId).set({});
    }
  }

  void showBlockDialog(String username, double width){

    TextEditingController _reportController = TextEditingController();

    showDialog(
      context: context, 
      builder: (context){
        return AlertDialog(
          title: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Report $username', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
            ],
          ),
          actionsAlignment: MainAxisAlignment.center,
          content: Padding(
            padding: EdgeInsets.only(left: width * 0.075, right: width * 0.075),
            child: AnimatedContainer(
              decoration: BoxDecoration(
                border: Border.all(color: globalPurple, width: 2.0),
                borderRadius: const BorderRadius.all(Radius.circular(15)),
              ),
              duration: const Duration(seconds: 1),
                child: Padding(
                  padding: EdgeInsets.all(width * 0.015),
                  child: TextField(
                  controller: _reportController,
                  maxLines: null,
                  decoration: InputDecoration(
                    border: InputBorder.none,
                    label: Center(
                      child: Text(
                        'Reason',
                        style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    )
                  ),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalPurple, fontWeight: FontWeight.bold),
                ),
              )
            ),
          ),
          actions: [
            Padding(
              padding: EdgeInsets.all(width * 0.01),
              child: Material(
                color: globalPurple,
                shape: const RoundedRectangleBorder(
                  borderRadius: BorderRadius.all(Radius.circular(15))
                ),
                child: InkWell(
                  borderRadius: const BorderRadius.all(Radius.circular(15)),
                  onTap: () async {

                    if(_reportController.text.isEmpty){
                      Fluttertoast.showToast(msg: 'Empty reason', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                      return;
                    }

                    if((await widget.firebase.collection('ReportedUsers').doc(widget.friendId).get()).exists){
                      widget.firebase.collection('ReportedUsers').doc(widget.friendId).update({
                        widget.userId : _reportController.text.trim()
                      });
                    }
                    else{
                      widget.firebase.collection('ReportedUsers').doc(widget.friendId).set({
                        widget.userId : _reportController.text.trim()
                      });
                    }
                    
                    Navigator.of(context).pop();
                    Fluttertoast.showToast(msg: '$username reported', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                  }, 
                  splashColor: globalBlue,
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.025),
                    child: Text('Report', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                  )
                )
              )
            )
          ]
        );
      }
    );
  }

  @override
  void dispose(){
    if(friendAddedOrNot){
      _addFriend();
    }

    super.dispose();
  }
}