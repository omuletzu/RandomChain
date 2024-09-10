import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:doom_chain/AbstractMenu.dart';
import 'package:doom_chain/GlobalColors.dart';
import 'package:doom_chain/SendUploadData.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CreateChainCamera extends StatefulWidget{

  final List<CameraDescription> cameraList;
  final CameraDescription camera;
  final CameraController cameraController;
  final Widget cameraBackground;
  final bool isUserCreatingNewChain;

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final void Function(String?, bool)? callBackAfterPhoto;
  final Map<String, dynamic>? addData;

  CreateChainCamera({Key? key, required this.isUserCreatingNewChain, required this.cameraList, required this.camera, required this.cameraBackground, required this.cameraController, required this.addData, required this.changePageHeader, required this.callBackAfterPhoto}) : super(key: key);

  _CreateChainCamera createState() => _CreateChainCamera();
}

class _CreateChainCamera extends State<CreateChainCamera> with TickerProviderStateMixin{

  late BuildContext mainContext;

  late final AnimationController _animationFade;
  final TextEditingController _textController = TextEditingController();
  late final TextEditingController _themeController;
  XFile? photo;
  bool photoTaken = false;
  bool photoWasLoadedFromMemory = false;
  bool photoSkipped = false;

  bool uploadIsLoading = false;

  bool checkForDoubleTapForPhoto = false;

  bool disableFirstPhraseForChallangeAndRandom = false;

  late final String categoryIconPath;
  late final String categoryFirstPhraseDescription;
  late final String categoryTextFieldDescription;
  late final String categoryName;

  int photoLatDivider = 1;

  @override
  void initState() {
    super.initState();

    mainContext = context;

    if(widget.addData!['categoryType'] == 0){
      categoryName = 'Story';
      categoryIconPath = 'assets/image/book.png';

      if(widget.isUserCreatingNewChain){
        categoryFirstPhraseDescription = 'This is the opening sentence of the story, keep it concise and great';
        categoryTextFieldDescription = 'What would be the first phrase?';
      }
      else{
        categoryFirstPhraseDescription = '';
        categoryTextFieldDescription = '';
      }
    }

    if(widget.addData!['categoryType'] == 1){
      categoryName = 'Random';
      categoryIconPath = 'assets/image/random.png';
      categoryFirstPhraseDescription = '';
      disableFirstPhraseForChallangeAndRandom = true;
      categoryTextFieldDescription = '';
    }

    if(widget.addData!['categoryType'] == 2){
      categoryName = 'Chainllange';
      categoryIconPath = 'assets/image/challange.png';
      categoryFirstPhraseDescription = '';
      disableFirstPhraseForChallangeAndRandom = true;
      categoryTextFieldDescription = '';
    }

    _themeController = TextEditingController();
    if(widget.isUserCreatingNewChain){
      _themeController.text = widget.addData!['theme'];
    }

    _animationFade = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250)  
    );

    _animationFade.forward();
  }

  @override
  void dispose(){
    super.dispose();
    widget.cameraController.dispose(); 
  }

  @override
  Widget build(BuildContext context){
   
    FirebaseFirestore _firebase = FirebaseFirestore.instance;
    FirebaseStorage _storage = FirebaseStorage.instance;

    final double width = MediaQuery.of(context).size.width;
    final double height = MediaQuery.of(context).size.height;

    List<Widget> iconList = widget.isUserCreatingNewChain ? getIconList(width) : getIconListNoButtons(width);
    List<Widget> columnOrRow = [
      Visibility(
        visible: !photoSkipped,
        child: Padding(
          padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05, top: width * 0.025, bottom: width * 0.015),
          child: ClipRRect(
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            child: Container(
              height: height * 0.6 / photoLatDivider,
              width: width / photoLatDivider,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.all(Radius.circular(15)),
                color: Colors.grey[200]
              ),
              child: !photoTaken
                  ? widget.cameraBackground
                  : photoWasLoadedFromMemory
                      ? (!photoSkipped ? Image.file(File(photo!.path), fit: BoxFit.cover) : Center(child: Text('Photo skipped', style: GoogleFonts.nunito(fontSize: width * 0.04, color: widget.addData!['baseCategoryColor'], fontWeight: FontWeight.bold))))
                      : const Center(child: CircularProgressIndicator()),
            )
          )
        )
      ),

      Visibility(
        visible: photoTaken,
        child: Padding(
          padding: EdgeInsets.only(bottom: width * 0.05),
          child: !photoSkipped 
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: iconList 
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: iconList
              )
        )
      )
    ];

    return PopScope(
      canPop: !photoTaken,
      onPopInvoked: (didPop) {
        if(!didPop && mounted){
          setState(() {
            if(widget.isUserCreatingNewChain){
              photoTaken = false;
              photoWasLoadedFromMemory = false;
              photoSkipped = false;
              photoLatDivider = 1;
            }
            else{
              Navigator.of(context).pop();
            }
          });

          widget.cameraController.resumePreview();
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: globalBackground,
          body: SingleChildScrollView(
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(width * 0.025),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationFade, curve: Curves.easeOut)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: Image.asset(categoryIconPath, fit: BoxFit.fill, width: width * 0.12, height: width * 0.12, color: globalTextBackground),
                        ),

                        Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: Text('New $categoryName', style: GoogleFonts.nunito(fontSize: width * 0.05, color: widget.addData!['baseCategoryColor'], fontWeight: FontWeight.bold))
                        ),
                      ],
                    )
                  )
                ),

                Visibility(
                  visible: !photoTaken,
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.025),
                    child: Text('> Press the button below to take a photo <', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold))
                  )
                ),

                Visibility(
                  visible: !photoTaken,
                  child: TextButton(
                    onPressed: () {
                      if(widget.isUserCreatingNewChain){
                        photo = null;
                        photoSkipped = true;
                        afterPhotoTaken();
                      }
                      else{
                        widget.callBackAfterPhoto!(null, false);
                        Navigator.of(context).pop();
                      }
                    }, 
                    child: Text('Skip this step', style: GoogleFonts.nunito(fontSize: width * 0.04, color: widget.addData!['baseCategoryColor'], fontWeight: FontWeight.bold))
                  )
                ),

                photoTaken
                  ? Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: columnOrRow,
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: columnOrRow,
                    ),
                
                Visibility(
                  visible: !photoTaken,
                  child: IconButton(
                    onPressed: () async {

                      if(!checkForDoubleTapForPhoto){
                        checkForDoubleTapForPhoto = true;
                        photo = await widget.cameraController.takePicture();
                        checkForDoubleTapForPhoto = false;

                        if(widget.isUserCreatingNewChain){
                          photoSkipped = false;
                          photoLatDivider = 2;
                          afterPhotoTaken();
                        }
                        else{
                          widget.callBackAfterPhoto!(photo!.path, true);
                          Navigator.of(context).pop();
                        }
                      }
                    }, 
                    icon: Icon(Icons.circle, size: width * 0.2, color: widget.addData!['baseCategoryColor'])
                  )
                ),

                Visibility(
                  visible: photoTaken,
                  child: Padding(
                    padding: EdgeInsets.only(left: width * 0.075, right: width * 0.075),
                    child: AnimatedContainer(
                      decoration: BoxDecoration(
                        border: Border.all(color: widget.addData!['baseCategoryColor'], width: 2.0),
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                      ),
                      duration: const Duration(seconds: 1),
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.025),
                          child: TextField(
                          controller: _themeController,
                          maxLines: null,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            label: Center(
                              child: Text(
                                (widget.addData!['categoryType'] == 1) ? 'Random chain' : 'Chainllange theme',
                                style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                              ),
                            )
                          ),
                          textAlign: TextAlign.center,
                          style: GoogleFonts.nunito(fontSize: width * 0.05, color: widget.addData!['baseCategoryColor'], fontWeight: FontWeight.bold),
                        ),
                      )
                    ),
                  )
                ),

                Visibility(
                  visible: photoTaken,
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.075),
                    child: disableFirstPhraseForChallangeAndRandom
                      ? (widget.addData!['categoryType'] == 2)
                        ? Text('Pick a theme that sets the stage for an engaging and competitive challenge. It should inspire participants to bring their best game', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center) 
                        : Text('Be as random as you want to and don\'t forget to add a spark', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center) 
                      : AnimatedContainer(
                      duration: const Duration(seconds: 2),
                      child: Column(
                        children: [
                          TextField(
                            controller: _textController,
                            maxLines: null,
                            decoration: InputDecoration(
                              focusedBorder: UnderlineInputBorder(
                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                borderSide: BorderSide(color: widget.addData!['baseCategoryColor'], width: 2.0)
                              ),
                              label: Center(
                                child: Text(
                                  categoryTextFieldDescription,
                                  style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                                ),
                              )
                            ),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.nunito(fontSize: width * 0.05, color: widget.addData!['baseCategoryColor'], fontWeight: FontWeight.bold),
                          ),
                          
                          Padding(
                            padding: EdgeInsets.only(top: width * 0.05),
                            child: Text(categoryFirstPhraseDescription, style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          )
                        ],
                      )
                    )
                  )
                ),

                Visibility(
                  visible: !uploadIsLoading,
                  child: Visibility(
                    visible: photoTaken,
                    child: Padding(
                      padding: EdgeInsets.only(top: width * 0.05, left: width * 0.075, right: width * 0.075, bottom: width * 0.05),
                      child: Material(
                        color: widget.addData!['baseCategoryColor'],
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))
                        ),
                        child: InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          onTap: () async {

                            if(!disableFirstPhraseForChallangeAndRandom && _textController.text.isEmpty){
                              Fluttertoast.showToast(msg: 'Empty first phrase', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
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
                                  content: Text('Are you sure you want to proceed?', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                  actions: [
                                    Padding(
                                      padding: EdgeInsets.all(width * 0.01),
                                      child: Material(
                                        color: widget.addData!['baseCategoryColor'],
                                        shape: const RoundedRectangleBorder(
                                          borderRadius: BorderRadius.all(Radius.circular(15))
                                        ),
                                        child: InkWell(
                                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                                          onTap: () async {
                                            if(mounted){
                                              setState(() {
                                                uploadIsLoading = true;
                                              });
                                            }

                                            Navigator.of(context).pop();

                                            bool uploadedSuccessfully = await SendUploadData.uploadData(
                                              firebase: _firebase,
                                              storage: _storage,
                                              addData: widget.addData!,
                                              chainMap: null,
                                              contributorsList: null,
                                              disableFirstPhraseForChallange: disableFirstPhraseForChallangeAndRandom,
                                              chainSkipped: false,
                                              theme: _themeController.text.trim(),
                                              title: _textController.text.trim(),
                                              photoSkipped: photoSkipped,
                                              chainIdentifier: AbstractMenu.generateRandomId(16),
                                              categoryName: categoryName,
                                              photoPath: photo?.path,
                                              mounted: mounted,
                                              context: mainContext,
                                              changePageHeader: widget.changePageHeader,
                                              newChainOrExtend: true,
                                            );

                                            if(!uploadedSuccessfully){
                                              setState(() {
                                                uploadIsLoading = false;
                                              });
                                            }
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
                                        color: widget.addData!['baseCategoryColor'],
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
                          splashColor: widget.addData!['splashColor'],
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.025),
                            child: Text('SEND IT', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                          )
                        )
                      )
                    )
                  )
                ),

                Visibility(
                  visible: uploadIsLoading,
                  child: CircularProgressIndicator(color: widget.addData!['baseCategoryColor']),
                )
              ],
            )
          ),
        )
      )
    );
  }

  void afterPhotoTaken(){
    widget.cameraController.pausePreview();

    if(mounted){
      setState(() {
        photoTaken = true;
      });
    }

    Future.delayed(
      const Duration(seconds: 4), () {
        if(mounted){
          setState(() {
            photoWasLoadedFromMemory = true;
          });
        }
      }
    );
  }

  List<Widget> getIconList(double width){

    List<Widget> widgetsForNumberOfContributors = [
      IconButton(
        onPressed: () {
          if(widget.addData!['chainPieces'] < 20){
            setState(() {
              widget.addData!['chainPieces']++;
            });
          }
        }, 
        icon: Icon(Icons.arrow_drop_up, size: width * 0.08, color: globalTextBackground)
      ),

      Text(widget.addData!['chainPieces'].toString(), style: GoogleFonts.nunito(fontSize: width * 0.05, color: globalTextBackground, fontWeight: FontWeight.bold)),

      IconButton(
        onPressed: () {
          if(widget.addData!['chainPieces'] > 1){
            setState(() {
              widget.addData!['chainPieces']--;
            });
          }
        }, 
        icon: Icon(Icons.arrow_drop_down, size: width * 0.08, color: globalTextBackground)
      )
    ];

    return [
      Padding(
        padding: EdgeInsets.only(top: width * 0.05, bottom: width * 0.05, left: width * 0.025, right: width * 0.025),
        child: IconButton(
          onPressed: () {
            if(mounted){
              setState(() {
                widget.addData!['allOrPartChain'] = !widget.addData!['allOrPartChain'];
              });
            }
          }, 
          icon: widget.addData!['allOrPartChain'] ? Image.asset('assets/image/one.png', width: width * 0.1, height: width * 0.1, color: globalTextBackground) : Image.asset('assets/image/logo.png', width: width * 0.1, height: width * 0.1, color: globalTextBackground)
        )
      ),

      Padding(
        padding: EdgeInsets.only(top: width * 0.05, bottom: width * 0.05, left: width * 0.025, right: width * 0.025),
        child: IconButton(
          onPressed: () {
            if(mounted){
              setState(() {
                widget.addData!['randomOrFriends'] = !widget.addData!['randomOrFriends'];
              });
            }
          }, 
          icon: widget.addData!['randomOrFriends'] ? Image.asset('assets/image/random.png', width: width * 0.1, height: width * 0.1, color: globalTextBackground) : Image.asset('assets/image/friends.png', width: width * 0.1, height: width * 0.1, color: globalTextBackground)
        )
      ),
      
      Padding(
        padding: EdgeInsets.only(top: width * 0.05, bottom: width * 0.05, left: width * 0.025, right: width * 0.025),
        child: photoSkipped 
          ? Column(children: widgetsForNumberOfContributors)
          : Row(children: widgetsForNumberOfContributors.reversed.toList())
      )
    ];
  }

  List<Widget> getIconListNoButtons(double width){
    return [
      Padding(
        padding: EdgeInsets.all(width * 0.05),
        child: widget.addData!['allOrPartChain'] ? Image.asset('assets/image/one.png', width: width * 0.1, height: width * 0.1) : Image.asset('assets/image/logo.png', width: width * 0.1, height: width * 0.1)
      ),

      Padding(
        padding: EdgeInsets.all(width * 0.05),
        child: widget.addData!['randomOrFriends'] ? Image.asset('assets/image/random.png', width: width * 0.1, height: width * 0.1) : Image.asset('assets/image/friends.png', width: width * 0.1, height: width * 0.1)
      )
    ];
  }
}