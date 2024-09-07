import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalColors.dart';
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
  final Map<String, dynamic>? friendData;
  final FirebaseFirestore firebase;
  final FirebaseStorage storage;

  FriendElement({required this.userId, 
    required this.friendId,
    required this.firebase, 
    required this.friendOrStranger,
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

  String friendNickname = '';

  List<List<String>> contributors = List.empty(growable: true);

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
                    child: Text(friendDetailsLoaded ? friendNickname : ' ', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),

                  Padding(
                    padding: EdgeInsets.all(width * 0.025),
                    child: ClipOval(
                      child: hasImage 
                        ? Image.network(
                          containerImageUrl,
                          width: width * 0.15,
                          height: width * 0.15,
                          fit: BoxFit.cover,
                          loadingBuilder: (context, child, loadingProgress) {
                            if(loadingProgress == null){
                              return child;
                            }
                            else{
                              return const Center(
                                child: CircularProgressIndicator(),
                              );
                            }
                          },
                          errorBuilder: (context, error, stackTrace) {
                            print('$error\n$stackTrace');
                            return Icon(Icons.error, size: width * 0.025);
                          },
                        )
                      : Image.asset('assets/image/profile.png', width: width * 0.15, height: width * 0.15)
                    )
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: !widget.friendOrStranger,
                        child: !friendAddedOrNot 
                          ? IconButton(
                              onPressed: () async {
                                setState(() {
                                  friendAddedOrNot = true;
                                  Fluttertoast.showToast(msg: 'Sent request to ${widget.friendData!['nickname']}', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
                                });
                              }, 
                              icon: Image.asset('assets/image/add.png', width: width * 0.075, height: width * 0.075)
                            )
                          : IconButton(
                              onPressed: () async {
                                setState(() {
                                  friendAddedOrNot = false;
                                });
                              }, 
                              icon: Image.asset('assets/image/minus.png', width: width * 0.075, height: width * 0.075)
                            )
                      ),

                      IconButton(
                        onPressed: () {
                          print(widget.friendOrStranger);
                        }, 
                        icon: Image.asset('assets/image/details.png', width: width * 0.05, height: width * 0.05)
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
    await widget.firebase.collection('UserDetails').doc(widget.userId).collection('Friends').doc(widget.friendId).set({
      'nickname' : widget.friendData!['nickname']
    });

    int currentFriendsCount = (await widget.firebase.collection('UserDetails').doc(widget.userId).get()).get('friendsCount');

    await widget.firebase.collection('UserDetails').doc(widget.userId).update({
      'friendsCount' : currentFriendsCount + 1
    });
  }

  @override
  void dispose(){
    if(friendAddedOrNot){
      _addFriend();
    }

    super.dispose();
  }
}