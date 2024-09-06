import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/Pair.dart';
import 'package:doom_chain/ProfilePage.dart';
import 'package:doom_chain/UnchainedViewChain.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
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
            splashColor: const Color.fromARGB(255, 102, 0, 255).withOpacity(0.1),
            
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

                  Visibility(
                    visible: hasImage,
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: ClipOval(
                        child: Image.network(
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
                      )
                    )
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Visibility(
                        visible: !widget.friendOrStranger,
                        child: IconButton(
                          onPressed: () async {
                            await widget.firebase.collection('UserDetails').doc(widget.userId).collection('Friends').doc(widget.friendId).set({
                              'nickname' : widget.friendData!['nickname']
                            });
                          }, 
                          icon: Image.asset('assets/image/add.png', width: width * 0.075, height: width * 0.075)
                        )
                      ),

                      IconButton(
                        onPressed: () {

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
          Reference reference = widget.storage.ref().child(widget.friendData!['avatarPath'] + '.png');
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
      return const Color.fromARGB(255, 102, 0, 255);
    }

    if(index == 1){
      return const Color.fromARGB(255, 30, 144, 255);
    }

    return const Color.fromARGB(255, 0, 150, 136);
  }

  @override
  void dispose(){
    super.dispose();
  }
}