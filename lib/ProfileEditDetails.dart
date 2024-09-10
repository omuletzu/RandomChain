import 'dart:io';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:doom_chain/GlobalColors.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

class ProfileEditDetails extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final String userId;

  ProfileEditDetails({
    required this.changePageHeader,
    required this.userId
  });

  @override
  _ProfileEditDetails createState() => _ProfileEditDetails();
}

class _ProfileEditDetails extends State<ProfileEditDetails> {

  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _nicknameController = TextEditingController();
  late Map<String, dynamic> userData;

  final ImagePicker _imagePicker = ImagePicker();
  File? imagePicked;
  bool notPickedImage = true;

  String originalAvatar = '';
  bool hasOriginalAvatar = false;

  bool dataRetreived = false;
  String countryEmoji = '';
  String countryName = '';

  bool dataLoading = false;

  @override
  void initState() {
    _retreiveUserData();
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
        backgroundColor: globalBackground,
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: Column(
            children: [

              Column(
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: Container(
                      width: width * 0.4,
                      child: GestureDetector(
                        onTap:() => _pickImage(),
                        child: Stack(
                          children: [
                            Align(
                              alignment: Alignment.center,
                              child: ClipOval(
                                child: notPickedImage ?
                                (
                                  hasOriginalAvatar 
                                    ? CachedNetworkImage(
                                      imageUrl: originalAvatar,
                                      width: width * 0.25,
                                      height: width * 0.25,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) => const CircularProgressIndicator(),
                                      errorWidget: (context, url, error) => Icon(Icons.error, size: width * 0.25)
                                    )
                                    : Image.asset('assets/image/profile.png', height: width * 0.25, width: width * 0.25, color: globalTextBackground)
                                )
                                : Image.file(imagePicked!, height: width * 0.25, width: width * 0.25, fit: BoxFit.cover)
                              )
                            ),
                  
                            Align(
                              alignment: Alignment.bottomRight,
                              child: Container(
                                decoration: BoxDecoration(
                                  color: globalBackground,
                                  shape: BoxShape.circle,
                                  border: Border.all(color: Colors.grey)
                                ),
                                child: Padding(
                                  padding: EdgeInsets.all(width * 0.01),
                                  child: Image.asset('assets/image/camera.png', height: width * 0.06, width: width * 0.06, color: globalTextBackground),
                                ),
                              ),
                            )
                          ],
                        )
                      )
                    ),
                  ),
                  
                  Padding(
                    padding: EdgeInsets.all(width * 0.03),
                    child: Text('> Profile Image <', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),
                ],
              ),

              Padding(
                padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025),
                child: Divider(
                  height: 1,
                  color: globalDrawerBackground,
                ),
              ),

              Padding(
                padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025, left: width * 0.075, right: width * 0.075),
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  child: Column(
                    children: [
                      TextField(
                        controller: _nicknameController,
                        maxLines: 1,
                        maxLength: 15,
                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: globalPurple, width: 2.0)
                          ),
                          label: Center(
                            child: Text(
                              '',
                              style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          )
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(fontSize: width * 0.05, color: globalPurple, fontWeight: FontWeight.bold),
                      ),
                      
                      Padding(
                        padding: EdgeInsets.all(width * 0.03),
                        child: Text('> Nickname <', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      )
                    ],
                  )
                )
              ),

              Padding(
                padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025),
                child: Divider(
                  height: 1,
                  color: globalDrawerBackground,
                ),
              ),

              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [

                  Padding(
                    padding: EdgeInsets.all(width * 0.04),
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
                      child: Text('$countryEmoji $countryName', style: GoogleFonts.nunito(fontSize: width * 0.05, color: globalTextBackground, fontWeight: FontWeight.bold)),
                    ),
                  ),

                  Padding(
                    padding: EdgeInsets.all(width * 0.025),
                    child: Text('> Country <', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),

                  Divider(
                    height: 1.0,
                    color: globalDrawerBackground,
                  ),

                  Padding(
                    padding: EdgeInsets.all(width * 0.075),
                    child: dataLoading
                      ? const Center(
                        child: CircularProgressIndicator()
                      )
                      : Material(
                          color: globalPurple,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15))
                          ),
                          child: InkWell(
                            borderRadius: const BorderRadius.all(Radius.circular(15)),
                            onTap: () async {

                              if(_nicknameController.text.isEmpty){
                                Fluttertoast.showToast(msg: 'Empty nickname', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
                                return;
                              }

                              showDialog(
                                context: context, 
                                builder: (context){
                                  return AlertDialog(
                                    title: Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Image.asset('assets/image/info.png', width: width * 0.1, height: width * 0.1),
                                        Text('One last time', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.black87, fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    content: Text('Are you sure you want to save?', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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

                                              if(mounted){
                                                setState(() {
                                                  dataLoading = true;
                                                });

                                                Navigator.of(context).popUntil((route) => route.isFirst);
                                              }

                                              if(!notPickedImage){
                                                Reference newAvatarReference = _storage.ref().child('avatars/${widget.userId}');
                                                await newAvatarReference.putFile(imagePicked!);
                                              }

                                              await _firebase.collection('UserDetails').doc(widget.userId).update({
                                                'nickname' : _nicknameController.text.trim(),
                                                'nicknameLowercase' : _nicknameController.text.toLowerCase().trim(),
                                                'countryName' : countryName,
                                                'countryEmoji' : countryEmoji,
                                                'avatarPath' : 'avatars/${widget.userId}'
                                              });

                                              widget.changePageHeader('Profile', {
                                                'userId' : widget.userId
                                              });
                                            }, 
                                            splashColor: globalBlue,
                                            child: Padding(
                                              padding: EdgeInsets.all(width * 0.025),
                                              child: Text('Yeah', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
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
                                              Navigator.of(context).pop();
                                            }, 
                                            splashColor: globalBlue,
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
                            }, 
                            splashColor: globalBlue,
                            child: Padding(
                              padding: EdgeInsets.all(width * 0.03),
                              child: Text('SAVE', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                            )
                          )
                        )
                  ),

                  SizedBox(
                    height: width * 0.32,
                  )
                ],
              ),
            ],
          )
        )
      ),
    );
  }

  Future _retreiveUserData() async {
    userData = (await _firebase.collection('UserDetails').doc(widget.userId).get()).data() as Map<String, dynamic>;

    _nicknameController.text = userData['nickname'];
    countryEmoji = userData['countryEmoji'];
    countryName = userData['countryName'];

    if(userData['avatarPath'] != '-'){
      Reference avatarReference = _storage.ref().child('avatars/${widget.userId}');
      originalAvatar = await avatarReference.getDownloadURL();

      setState(() {
        hasOriginalAvatar = true;
      });
    }

    setState(() {
      dataRetreived = true;
    });
  }

  void _pickImage() async {
    final image = await _imagePicker.pickImage(source: ImageSource.gallery);

    if(image != null){
      setState(() {
        imagePicked = File(image.path);
        notPickedImage = false;
      });
    }
    else{
      setState(() {
        notPickedImage = true;
      });
    }
  }
}