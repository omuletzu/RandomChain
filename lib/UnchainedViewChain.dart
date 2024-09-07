import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/CreateChainCamera.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:camera/camera.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:country_picker/country_picker.dart';

class UnchainedViewChain extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final FirebaseFirestore firebase;
  final FirebaseStorage storage;
  final double width;
  final String categoryAssetPath;
  final Color categoryColor;
  final Map<String, dynamic> chainMap;
  final String categoryName;
  final List<List<String>> contributors;
  final String userId;
  final String chainId;
  final String chainNationality;
  final void Function() removeIndex;
  final bool calledByExplore;

  UnchainedViewChain({required this.firebase, required this.storage, 
    required this.categoryAssetPath, required this.width, 
    required this.chainMap, required this.categoryColor, 
    required this.categoryName, required this.contributors, 
    required this.changePageHeader, required this.userId,
    required this.chainId, required this.chainNationality,
    required this.removeIndex, required this.calledByExplore,
  });

  @override
  _UnchainedViewChain createState() => _UnchainedViewChain();
}

class _UnchainedViewChain extends State<UnchainedViewChain> with TickerProviderStateMixin{

  late AnimationController _animationControllerSlideUp1;
  late AnimationController _animationControllerSlideUp2;
  late AnimationController _animationControllerSlideUp3;
  late AnimationController _animationControllerSlideUp4;
  late AnimationController _animationControllerSlideDown;
  late AnimationController _animationControllerButtonFade;
  final ScrollController scrollController = ScrollController();
  final TextEditingController _textController = TextEditingController();

  late final Map<String, String> allChainContrib;
  late final List<String> allPhotoIds;
  final List<Widget> allWidgetContrib = List.empty(growable: true);

  late List<bool> usernameLoaded;
  late List<bool> pfpLoaded;
  late List<bool> containerImageUrlLoaded;

  String buttonText = 'EXTEND';
  String extendTextCopy = '';
  String? imagePath = '';
  bool alreadyExtended = false;
  bool extensionHasImage = false;
  bool chainSentForUpload = false;
  int likesNumber = 0;
  bool liked = false;
  bool saved = false;

  late List<String> usersCountryFlag;

  @override
  void initState() {
    super.initState();

    _animationControllerSlideUp1 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animationControllerSlideUp2 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animationControllerSlideUp3 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animationControllerSlideUp4 = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animationControllerSlideDown = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    _animationControllerButtonFade = AnimationController(vsync: this, duration: const Duration(seconds: 1));
    
    _animationControllerSlideUp1.forward().then((value) => _animationControllerSlideUp2.forward());

    usernameLoaded = List.filled(widget.contributors.length, false);
    pfpLoaded = List.filled(widget.contributors.length, false);
    containerImageUrlLoaded = List.filled(widget.contributors.length + 1, false);
    usersCountryFlag = List.filled(widget.contributors.length, Country.worldWide.flagEmoji);

    bool oneOrTwoTilesContainer = true;

    int index = 0;

    if(!widget.chainMap['allPieces'] && !widget.calledByExplore){
      index = widget.contributors.length - 1;
    }

    allWidgetContrib.add(
      SizedBox(height: widget.width * 0.05, width: widget.width)
    );

    for(index; index < widget.contributors.length; index++){

      List<String> contributor = widget.contributors[index];  // 0 - uid, 1 - phrase, 2 - ref
    
      bool hasImage = true;

      if(contributor[2] == '-'){
        hasImage = false;
      }
      else{
        _retreiveContainerImage(contributor[2], index);
      }

      double widgetTopPadding = 0;
      double widgetBottomPadding = 0;

      if(index == 0){
        widgetTopPadding = widget.width * 0.05;
      }

      allWidgetContrib.add(
        _createWidgetContrib(index, contributor, hasImage, widgetTopPadding, widgetBottomPadding)
      );

      if(index < widget.contributors.length - 1){
        allWidgetContrib.add(
          Row(
            children: [
              Container(
                width: oneOrTwoTilesContainer ? widget.width / 2 : widget.width,
                height: widget.width * 0.1,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/image/linkChain.png'),
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      widget.categoryColor, 
                      BlendMode.srcIn
                    )
                  )
                ),
              ),

              Visibility(
                visible: oneOrTwoTilesContainer,
                child: Container(
                  width: widget.width / 2,
                  height: widget.width * 0.1,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const AssetImage('assets/image/linkChain.png'),
                      fit: BoxFit.contain,
                      colorFilter: ColorFilter.mode(
                        widget.categoryColor, 
                        BlendMode.srcIn
                      )
                    )
                  ),
                )
              )
            ],
          )
        );
      }

      oneOrTwoTilesContainer = !oneOrTwoTilesContainer;
    }

    allWidgetContrib.add(
      SizedBox(height: widget.width * (0.05 + 0.32), width: widget.width)
    );

    _checkForLiked();
    _checkForSaved();
  }

  @override
  Widget build(BuildContext context){
    return PopScope(
      canPop: false,
      onPopInvoked: ((didPop) {
        if(!didPop){

          if(_textController.text.isNotEmpty && extensionHasImage){
            showDialog(
              context: context, 
              builder: (context){
                return AlertDialog(
                  title: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/image/info.png', width: widget.width * 0.1, height: widget.width * 0.1),
                      Text('Warning', style: GoogleFonts.nunito(fontSize: widget.width * 0.06, color: Colors.black87, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  actionsAlignment: MainAxisAlignment.center,
                  content: Text('Are you sure you want to go back?', style: GoogleFonts.nunito(fontSize: widget.width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  actions: [
                    Padding(
                      padding: EdgeInsets.all(widget.width * 0.01),
                      child: Material(
                        color: widget.categoryColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))
                        ),
                        child: InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          onTap: () async {
                            Navigator.of(context).popUntil((route) => route.isFirst);
                          }, 
                          splashColor: const Color.fromARGB(255, 30, 144, 255),
                          child: Padding(
                            padding: EdgeInsets.all(widget.width * 0.025),
                            child: Text('Yeah', style: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                          )
                        )
                      )
                    ),

                    Padding(
                      padding: EdgeInsets.all(widget.width * 0.01),
                      child: Material(
                        color: widget.categoryColor,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.all(Radius.circular(15))
                        ),
                        child: InkWell(
                          borderRadius: const BorderRadius.all(Radius.circular(15)),
                          onTap: () async {
                            Navigator.of(context).pop();
                          }, 
                          splashColor: const Color.fromARGB(255, 30, 144, 255),
                          child: Padding(
                            padding: EdgeInsets.all(widget.width * 0.025),
                            child: Text('Close', style: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                          )
                        )
                      )
                    )
                  ]
                );
              }
            );
          }
          else{
            Navigator.of(context).popUntil((route) => route.isFirst);
          }
        }
      }),
      child: SafeArea(
        child: Scaffold(
          body: Column(
            children: [
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[200]
                ),
                child: Padding(
                  padding: EdgeInsets.only(left: widget.width * 0.05, right: widget.width * 0.025, top: widget.width * 0.025, bottom: widget.width * 0.025),
                  child: FadeTransition(
                    opacity: Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationControllerSlideUp1, curve: Curves.easeOut)),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(widget.width * 0.025),
                          child: Image.asset(widget.categoryAssetPath, fit: BoxFit.fill, width: widget.width * 0.12, height: widget.width * 0.12),
                        ),

                        Padding(
                          padding: EdgeInsets.all(widget.width * 0.025),
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(widget.width * 0.01),
                                child: Text(widget.chainMap['title'], style: GoogleFonts.nunito(fontSize: widget.width * 0.05, color: widget.categoryColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                              ),

                              Padding(
                                padding: EdgeInsets.all(widget.width * 0.01),
                                child: Text(widget.chainMap['theme'], style: GoogleFonts.nunito(fontSize: widget.width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                              )
                            ],
                          )
                        ),
                      ],
                    )
                  )
                )
              ),

              Divider(
                height: 1,
                color: Colors.grey[300],
              ),

              Expanded(
                child: Stack(
                  children: [
                    Align(
                      alignment: Alignment.topCenter,
                      child: SingleChildScrollView(
                        controller: scrollController,
                        child: Column(
                          children: allWidgetContrib
                        ),
                      )
                    ),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Visibility(
                        visible: widget.calledByExplore,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.0, 0.0), end: const Offset(0.0, 2.0)).animate(CurvedAnimation(parent: _animationControllerSlideDown, curve: Curves.easeOut)),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.9), Colors.grey[200]!, Colors.grey[200]!]
                                )
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  Expanded(
                                    child: SlideTransition(
                                    position: Tween<Offset>(begin: const Offset(0.0, 2.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideUp1, curve: Curves.easeOut)),
                                      child: Padding(
                                        padding: EdgeInsets.all(widget.width * 0.05),
                                        child: Material(
                                          color: widget.categoryColor,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(15))
                                          ),
                                          child: InkWell(
                                            borderRadius: const BorderRadius.all(Radius.circular(15)),
                                            onTap: () async {
                                              if(liked){
                                                setState(() {
                                                  likesNumber--;
                                                  liked = false;
                                                });
                                                await widget.firebase.collection('UserDetails').doc(widget.userId).collection('LikedChains${widget.categoryName}').doc(widget.chainId).delete();
                                              }
                                              else{
                                                setState(() {
                                                  likesNumber++;
                                                  liked = true;
                                                });
                                                await widget.firebase.collection('UserDetails').doc(widget.userId).collection('LikedChains${widget.categoryName}').doc(widget.chainId).set({
                                                  'categoryName' : widget.categoryName, 
                                                  'chainNationality' : widget.chainMap['chainNationality']
                                                });
                                              }

                                              await widget.firebase.collection('FinishedChains').doc(widget.categoryName).collection(widget.chainMap['chainNationality']).doc(widget.chainId).update({
                                                'likes' : likesNumber
                                              });
                                            }, 
                                            splashColor: Colors.grey,
                                            child: Padding(
                                              padding: EdgeInsets.all(widget.width * 0.025),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(right: widget.width * 0.025),
                                                    child: Image.asset('assets/image/star.png', width: widget.width * 0.075, height: widget.width * 0.075, color: liked ? Colors.white : Colors.transparent),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(widget.width * 0.01),
                                                    child: Text('Like ($likesNumber)', style: GoogleFonts.nunito(fontSize: widget.width * 0.045, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                                  )
                                                ],
                                              )
                                            )
                                          )
                                        )
                                      )
                                    )
                                  ),

                                  Expanded(
                                    child: SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(0.0, 2.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideUp2, curve: Curves.easeOut)),
                                      child: Padding(
                                        padding: EdgeInsets.all(widget.width * 0.05),
                                        child: Material(
                                          color: widget.categoryColor,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(15))
                                          ),
                                          child: InkWell(
                                            borderRadius: const BorderRadius.all(Radius.circular(15)),
                                            onTap: () async {
                                              if(saved){
                                                setState(() {
                                                  saved = false;
                                                });
                                                await widget.firebase.collection('UserDetails').doc(widget.userId).collection('SavedChains${widget.categoryName}').doc(widget.chainId).delete();
                                              }
                                              else{
                                                setState(() {
                                                  saved = true;
                                                });
                                                await widget.firebase.collection('UserDetails').doc(widget.userId).collection('SavedChains${widget.categoryName}').doc(widget.chainId).set({
                                                  'categoryName' : widget.categoryName, 
                                                  'chainNationality' : widget.chainMap['chainNationality']
                                                });
                                              }
                                            }, 
                                            splashColor: Colors.grey,
                                            child: Padding(
                                              padding: EdgeInsets.all(widget.width * 0.025),
                                              child: Row(
                                                mainAxisAlignment: MainAxisAlignment.center,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.only(right: widget.width * 0.025),
                                                    child: Image.asset('assets/image/save.png', width: widget.width * 0.075, height: widget.width * 0.075, color: saved ? Colors.white : Colors.transparent),
                                                  ),
                                                  Padding(
                                                    padding: EdgeInsets.all(widget.width * 0.01),
                                                    child: Text('Save', style: GoogleFonts.nunito(fontSize: widget.width * 0.045, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                                  )
                                                ],
                                              )
                                            )
                                          )
                                        )
                                      )
                                    )
                                  )
                                ],
                            )
                          )
                        )
                      )
                    ),

                    Align(
                      alignment: Alignment.bottomCenter,
                      child: Visibility(
                      visible: !widget.calledByExplore,
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(0.0, 0.0), end: const Offset(0.0, 2.0)).animate(CurvedAnimation(parent: _animationControllerSlideDown, curve: Curves.easeOut)),
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [Colors.white.withOpacity(0.1), Colors.white.withOpacity(0.9), Colors.grey[200]!, Colors.grey[200]!]
                                )
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [

                                  Expanded(
                                    child: SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(0.0, 2.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideUp1, curve: Curves.easeOut)),
                                      child: Padding(
                                        padding: EdgeInsets.all(widget.width * 0.05),
                                        child: Material(
                                          color: widget.categoryColor,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(15))
                                          ),
                                          child: InkWell(
                                            borderRadius: const BorderRadius.all(Radius.circular(15)),
                                            onTap: () async {
                                              final List<CameraDescription> cameraList;
                                              final CameraDescription camera;
                                              CameraController _cameraController;

                                              cameraList = await availableCameras();
                                              camera = cameraList.first;

                                              _cameraController = CameraController(
                                                camera, 
                                                ResolutionPreset.max,
                                              );

                                              await _cameraController.initialize();

                                              await _cameraController.setZoomLevel(1.5);

                                              Map<String, dynamic> addData = Map<String, dynamic>();
                                              if(widget.categoryName == 'Story'){
                                                addData = {
                                                  'categoryType' : 0
                                                };
                                              }
                                              else if(widget.categoryName == 'Gossip'){
                                                addData = {
                                                  'categoryType' : 1
                                                };
                                              }
                                              else if(widget.categoryName == 'Chainllange'){
                                                addData = {
                                                  'categoryType' : 2
                                                };
                                              }

                                              addData.addAll({
                                                'allOrPartChain' : widget.chainMap['allPieces'],
                                                'randomOrFriends' : widget.chainMap['random'],
                                                'baseCategoryColor' : widget.categoryColor,
                                                'splashColor' : widget.categoryColor
                                              });

                                              if(mounted){
                                                Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateChainCamera(
                                                  cameraList: cameraList, 
                                                  camera: camera, 
                                                  cameraBackground: CameraPreview(_cameraController), 
                                                  cameraController: _cameraController, 
                                                  addData: addData, 
                                                  changePageHeader: widget.changePageHeader, 
                                                  isUserCreatingNewChain: false,
                                                  callBackAfterPhoto: callBackAfterPhoto,
                                                )));
                                              }
                                            }, 
                                            splashColor: Colors.grey,
                                            child: Padding(
                                              padding: EdgeInsets.all(widget.width * 0.025),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(widget.width * 0.01),
                                                    child: Text(buttonText, style: GoogleFonts.nunito(fontSize: widget.width * 0.045, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                                  ),
                                                  Image.asset(alreadyExtended ? 'assets/image/camera.png' : 'assets/image/logo.png', width: widget.width * 0.075, height: widget.width * 0.075, color: Colors.white),
                                                ],
                                              )
                                            )
                                          )
                                        )
                                      )
                                    )
                                  ),

                                  Visibility(
                                    visible: alreadyExtended,
                                    child: FadeTransition(
                                      opacity:Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _animationControllerButtonFade, curve: Curves.easeOut)),
                                      child: Padding(
                                        padding: EdgeInsets.all(widget.width * 0.0),
                                        child: !chainSentForUpload ? IconButton(
                                          onPressed: () {

                                            if(_textController.text.trim().isEmpty){
                                              Fluttertoast.showToast(msg: 'Empty text', toastLength: Toast.LENGTH_LONG, backgroundColor: const Color.fromARGB(255, 30, 144, 255));
                                              return;
                                            }

                                            _animationControllerSlideDown.forward();
                                            uploadExtendData(false);
                                          }, 
                                          icon: Image.asset('assets/image/rightarrow.png', fit: BoxFit.fill, width: widget.width * 0.12, height: widget.width * 0.12)
                                        ) : CircularProgressIndicator(color: widget.categoryColor)
                                      )
                                    )
                                  ),

                                  Expanded(
                                    child: SlideTransition(
                                      position: Tween<Offset>(begin: const Offset(0.0, 2.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideUp2, curve: Curves.easeOut)),
                                      child: Padding(
                                        padding: EdgeInsets.all(widget.width * 0.05),
                                        child: Material(
                                          color: widget.categoryColor,
                                          shape: const RoundedRectangleBorder(
                                            borderRadius: BorderRadius.all(Radius.circular(15))
                                          ),
                                          child: InkWell(
                                            borderRadius: const BorderRadius.all(Radius.circular(15)),
                                            onTap: () async {
                                              uploadExtendData(true);
                                            }, 
                                            splashColor: Colors.grey,
                                            child: Padding(
                                              padding: EdgeInsets.all(widget.width * 0.025),
                                              child: Column(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Padding(
                                                    padding: EdgeInsets.all(widget.width * 0.01),
                                                    child: Text('SKIP', style: GoogleFonts.nunito(fontSize: widget.width * 0.045, color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                                                  ),
                                                  Image.asset('assets/image/skip.png', width: widget.width * 0.075, height: widget.width * 0.075, color: Colors.white)
                                                ]
                                              )
                                            )
                                          )
                                        )
                                      )
                                    )
                                  )
                                ],
                              )
                            )
                        )
                      )
                    )
                  ],
                ),
              )
            ],
          ),
        )
      )
    );
  }

  void uploadExtendData(bool extendingSkipped) async {
    if(extendingSkipped){
      callStaticSentMethod();
      Fluttertoast.showToast(msg: 'SKIPPED', toastLength: Toast.LENGTH_LONG, backgroundColor: const Color.fromARGB(255, 30, 144, 255));
    }
    else{
      try{

        setState(() {
          chainSentForUpload = true;
        });
        
        String extensionImagePath = '-';

        widget.chainMap['remainingOfContrib']--;

        if(extensionHasImage){
          extensionImagePath = 'uploads/${widget.chainId}/${widget.chainMap['remainingOfContrib']}_${widget.userId}';
          Reference reference =  widget.storage.ref().child(extensionImagePath);
          await reference.putFile(File(imagePath!));
        }

        widget.contributors.add(List.from([
          widget.userId, _textController.text, extensionImagePath
        ]));

        await widget.firebase.collection('PendingChains').doc(widget.categoryName).collection(widget.chainNationality).doc(widget.chainId).update({
          'contributions' : jsonEncode(widget.contributors),
          'remainingOfContrib' : widget.chainMap['remainingOfContrib']
        }); 

        callStaticSentMethod();
        Fluttertoast.showToast(msg: 'SENT', toastLength: Toast.LENGTH_LONG, backgroundColor: const Color.fromARGB(255, 30, 144, 255));
      }
      catch(e){
        print(e);
      }
    }
  }

  void callStaticSentMethod() async {
    String chainNationality = '';
    Map<String, dynamic> chainMap = (await widget.firebase.collection('PendingChains').doc(widget.categoryName).collection(widget.chainNationality).doc(widget.chainId).get()).data() as Map<String, dynamic>;

    chainNationality = chainMap['chainNationality'];

    if(widget.chainMap['remainingOfContrib'] > 0){
      CreateChainCamera.uploadData(
        firebase: widget.firebase, 
        storage: widget.storage, 
        addData: {'randomOrFriends' : chainMap['random']},
        chainMap: chainMap, 
        disableFirstPhraseForChallange: false, 
        theme: '', 
        title: '', 
        photoSkipped: false, 
        chainIdentifier: widget.chainId, 
        categoryName: widget.categoryName, 
        photoPath: null, 
        mounted: mounted, 
        context: context, 
        changePageHeader: widget.changePageHeader, 
        newChainOrExtend: false, 
        userIdForExtend: widget.userId, 
        userNationalityForExtend: chainNationality
      );
    }
    else{

      await widget.firebase.collection('UserDetails').doc(widget.userId).collection('FinishedChains${widget.categoryName}').doc(widget.chainId).set({
        'categoryName' : widget.categoryName, 
        'chainNationality' : chainMap['chainNationality']
      });

      for(List<String> contributor in widget.contributors){

        String contributorId = contributor[0];
        
        await widget.firebase.collection('UserDetails').doc(contributorId).collection('FinishedChains${widget.categoryName}').doc(widget.chainId).set({
        'categoryName' : widget.categoryName, 
        'chainNationality' : chainMap['chainNationality']
      });
      }

      await widget.firebase.collection('FinishedChains').doc(widget.categoryName).collection(widget.chainNationality).doc(widget.chainId).set(chainMap);
      await widget.firebase.collection('PendingChains').doc(widget.categoryName).collection(widget.chainNationality).doc(widget.chainId).delete();
    }

    DocumentReference userDetails = widget.firebase.collection('UserDetails').doc(widget.userId);
    int categoryTypeContributions = (await userDetails.get()).get('${widget.categoryName}Contributions');
    int totalContributions = (await userDetails.get()).get('totalContributions');

    userDetails.update({
      '${widget.categoryName}Contributions' : categoryTypeContributions + 1,
      'totalContributions' : totalContributions + 1
    });

    widget.firebase.collection('UserDetails').doc(widget.userId).collection('PendingPersonalChains').doc(widget.chainId).delete(); 

    if(mounted){
      Navigator.of(context).pop();
      widget.changePageHeader('Unchained (refresh)', null);
    }
  }

  void callBackAfterPhoto(String? photoPath, bool hasImage) async {
    setState(() {

      extendTextCopy = _textController.text;

      if(alreadyExtended){
        allWidgetContrib.remove(allWidgetContrib.last);
        allWidgetContrib.remove(allWidgetContrib.last);
      }
      else{
        alreadyExtended = true;
        buttonText = 'RETAKE';
        _animationControllerButtonFade.forward();

        allWidgetContrib.last = 
          Row(
            children: [
              Container(
                width: widget.width / 2,
                height: widget.width * 0.1,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/image/linkChain.png'),
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      widget.categoryColor, 
                      BlendMode.srcIn
                    )
                  )
                ),
              ),

              Container(
                width: widget.width / 2,
                height: widget.width * 0.1,
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: const AssetImage('assets/image/linkChain.png'),
                    fit: BoxFit.contain,
                    colorFilter: ColorFilter.mode(
                      widget.categoryColor, 
                      BlendMode.srcIn
                    )
                  )
                ),
              )
            ],
          );
      }

      allWidgetContrib.add(
        getExtentChainContainer(photoPath, hasImage)
      );

      allWidgetContrib.add(
        SizedBox(
          width: widget.width,
          height: widget.width * (0.05 + 0.32),
        )
      );

      // WidgetsBinding.instance.addPostFrameCallback((_) { 
      //   scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(seconds: 1), curve: Curves.easeOut);
      // });

      _textController.text = extendTextCopy;
    });

    imagePath = photoPath;
    extensionHasImage = hasImage;
  }

  Widget _createWidgetContrib(int index, List<String> contributor, bool hasImage, double widgetTopPadding, double widgetBottomPadding) {
    return Padding(
      padding: EdgeInsets.only(left: widget.width * 0.1, right: widget.width * 0.1, top: widgetTopPadding, bottom: widgetBottomPadding),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            border: Border.all(width: 2.0, color: widget.categoryColor),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            color: Colors.grey[200]
          ),
          child: Column(
            children: [

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(widget.width * 0.025),
                    child: FutureBuilder<Map<String, String>>(
                      future: _retreiveUsernameAndPfp(contributor[0], index),
                      builder: (context, snapshot) {
                        if(snapshot.hasData){
                      
                          String username = snapshot.data!['username']!;
                          String pfpUrl = snapshot.data!['pfp']!;

                          return Row(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(widget.width * 0.01),
                                child: ClipOval(
                                  child: Image.network(
                                    pfpUrl, 
                                    width: widget.width * 0.075, 
                                    height: widget.width * 0.075,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if(loadingProgress == null){
                                        return child;
                                      }
                                      
                                      return CircularProgressIndicator(color: widget.categoryColor);
                                    },
                                  )
                                )
                              ),
                              Padding(
                                padding: EdgeInsets.all(widget.width * 0.01),
                                child: Text(username, style: GoogleFonts.nunito(color: Colors.black87, fontSize: widget.width * 0.04, fontWeight: FontWeight.bold))
                              )
                            ],
                          );
                        }
                        
                        return Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.all(widget.width * 0.01),
                              child: Image.asset('assets/image/profile.png', width: widget.width * 0.075, height: widget.width * 0.075)
                            ),
                            Padding(
                              padding: EdgeInsets.all(widget.width * 0.01),
                              child: Text('Unknown user', style: GoogleFonts.nunito(color: Colors.black87, fontSize: widget.width * 0.04, fontWeight: FontWeight.bold))
                            )
                          ],
                        );
                      },
                    )
                  ),

                  const Spacer(),

                  Padding(
                    padding: EdgeInsets.all(widget.width * 0.025),
                    child: Image.asset(widget.categoryAssetPath, width: widget.width * 0.075, height: widget.width * 0.075, color: widget.categoryColor)
                  )
                ],
              ),

              Divider(
                height: 1.0,
                color: Colors.grey[200],
              ),

              Padding(
                padding: EdgeInsets.only(top: widget.width * 0.01, bottom: widget.width * 0.01),
                child: Text(contributor[1], style: GoogleFonts.nunito(fontSize: widget.width * 0.04, color: Colors.black87), textAlign: TextAlign.center),
              ),

              Visibility(
                visible: hasImage,
                child: Padding(
                  padding: EdgeInsets.only(left: widget.width * 0.075, top: widget.width * 0.075, right: widget.width * 0.075, bottom: widget.width * 0.025),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    child: FutureBuilder(
                      future: _retreiveContainerImage(contributor[2], index), 
                      builder: (context, snapshot){
                        if(snapshot.hasData){
                          return hasImage ? Image.network(
                              snapshot.data!, 
                                fit: BoxFit.cover,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if(loadingProgress == null){
                                    return child;
                                  }
                                  else{
                                    return CircularProgressIndicator(color: widget.categoryColor);
                                  }
                                }
                            )
                            : Image.asset('assets/image.logo.png');
                        }

                        return Image.asset('assets/image/logo.png', width: widget.width * 0.12, height: widget.width * 0.12);
                      }
                    )
                  )
                )
              ),

              Divider(
                height: 1.0,
                color: Colors.grey[200],
              ),

              Row(
                children: [

                  const Spacer(),

                  Padding(
                    padding:  EdgeInsets.all(widget.width * 0.01),
                    child: FutureBuilder(
                      future: _retreiveUserCountryEmoji(contributor[0]), 
                      builder: (context, snapshot) {
                        if(snapshot.hasData){
                          return Text(snapshot.data!, style: GoogleFonts.nunito(fontSize: widget.width * 0.04));
                        }
                    
                        return Text(Country.worldWide.flagEmoji, style: GoogleFonts.nunito(fontSize: widget.width * 0.04));
                      }
                    ),
                  ),

                  const Spacer(),

                  Padding(
                    padding: EdgeInsets.all(widget.width * 0.01),
                    child: TextButton(
                      onPressed: () {
                        //report logic
                      }, 
                      child: Text('Report', style: GoogleFonts.nunito(fontSize: widget.width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold))
                    ),
                  ),

                  const Spacer(),
                ],
              )
            ],
          )
        )
      )
    );
  }

  Widget getExtentChainContainer(String? imagePath, bool hasImage){
    return Padding(
      padding: EdgeInsets.only(left: widget.width * 0.1, right: widget.width * 0.1, bottom: widget.width * 0.075),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 500),
          decoration: BoxDecoration(
            border: Border.all(width: 2.0, color: widget.categoryColor),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
            color: Colors.grey[200]
          ),
          child: Column(
            children: [

              Padding(
                padding: EdgeInsets.only(left: widget.width * 0.075, right: widget.width * 0.075, top: widget.width * 0.025, bottom: widget.width * 0.025),
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  child: Column(
                    children: [
                      TextField(
                        controller: _textController,
                        maxLines: null,
                        onTap: () {
                          scrollController.animateTo(scrollController.position.maxScrollExtent, duration: const Duration(seconds: 1), curve: Curves.easeOut);
                        },
                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: widget.categoryColor, width: 2.0)
                          ),
                          label: Center(
                            child: Text(
                              'Type here the text',
                              style: GoogleFonts.nunito(fontSize: widget.width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                          )
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(fontSize: widget.width * 0.04, color: widget.categoryColor, fontWeight: FontWeight.bold),
                      ),
                    ],
                  )
                )
              ),

              Visibility(
                visible: hasImage,
                child: Padding(
                  padding: EdgeInsets.only(bottom: widget.width * 0.075, left: widget.width * 0.075, right: widget.width * 0.075),
                  child: ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    child: hasImage 
                    ? Image.file(File(imagePath!), fit: BoxFit.cover)
                    : Image.asset('assets/image.logo.png')
                  )
                )
              )
            ],
          )
        )
      )
    );
  }

  Future<Map<String, String>> _retreiveUsernameAndPfp(String userId, int index) async {
    DocumentSnapshot userDocument = await widget.firebase.collection('UserDetails').doc(userId).get();

    String pfpLink = '-';

    if(userDocument.get('avatarPath') != '-'){
      Reference pfpReference = widget.storage.ref().child(userDocument.get('avatarPath') + '.png');
      pfpLink = await pfpReference.getDownloadURL();
    }

    return {
      'username' : userDocument.get('nickname') ?? 'User',
      'pfp' : pfpLink
    };
  }

  Future<String> _retreiveUserCountryEmoji(String userId) async {
    DocumentSnapshot userDocument = await widget.firebase.collection('UserDetails').doc(userId).get();
    return userDocument.get('countryEmoji');
  }

  Future<String> _retreiveContainerImage(String path, int index) async {

    if(path == '-'){
      return '';
    }

    try{
      Reference storageRef = widget.storage.ref().child(path);
      return await storageRef.getDownloadURL();
    }
    on FirebaseException catch(e){
      print(e.code);
      return '';
    }
  }

  Future<void> _checkForLiked() async {

    if(!widget.calledByExplore){
      return;
    }

    int tempLikesNumber = (await widget.firebase.collection('FinishedChains').doc(widget.categoryName).collection(widget.chainMap['chainNationality']).doc(widget.chainId).get(const GetOptions(source: Source.server))).get('likes');

    setState(() {
      likesNumber = tempLikesNumber;
    });

    print(likesNumber);

    DocumentSnapshot checkDocument = await widget.firebase.collection('UserDetails').doc(widget.userId).collection('LikedChains${widget.categoryName}').doc(widget.chainId).get();

    if(checkDocument.exists){
      setState(() {
        liked = true;
      });
    }
  }

  Future<void> _checkForSaved() async {

    if(!widget.calledByExplore){
      return;
    }

    DocumentSnapshot checkDocument = await widget.firebase.collection('UserDetails').doc(widget.userId).collection('SavedChains${widget.categoryName}').doc(widget.chainId).get();

    if(checkDocument.exists){
      setState(() {
        saved = true;
      });
    }
  }

  @override
  void dispose(){
    _animationControllerButtonFade.dispose();
    _animationControllerSlideDown.dispose();
    _animationControllerSlideUp1.dispose();
    _animationControllerSlideUp2.dispose();
    _animationControllerSlideUp3.dispose();
    _animationControllerSlideUp4.dispose();
    _textController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}