import 'package:doom_chain/CreateChainCamera.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:permission_handler/permission_handler.dart';


class CreateChainDetails extends StatefulWidget {

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final Map<String, dynamic>? addData;

  CreateChainDetails({required this.changePageHeader, required this.addData});

  @override
  _CreateChainDetails createState() => _CreateChainDetails();
}

class _CreateChainDetails extends State<CreateChainDetails> with TickerProviderStateMixin {

  final TextEditingController _tagController = TextEditingController();
  late final AnimationController _animationControllerIcon;
  late final Animation<double> _animationIcon;

  bool randomOrFriends = true;
  bool allOrPartChain = true;

  List<String> tagList = List.empty(growable: true);

  @override
  void initState(){
    super.initState();
    
    if(widget.addData != null && widget.addData!['tagList'] != null){
      tagList = widget.addData!['tagList'];
    }

    _animationControllerIcon = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1)
    );

    _animationIcon = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationControllerIcon, curve: Curves.easeOut));
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if(!didPop){
          widget.addData!['tagList'] = tagList;

          if(widget.addData!['categoryType'] == 0){
            widget.changePageHeader('New chain (details)', widget.addData);
          }
          
          if(widget.addData!['categoryType'] == 1){
            widget.changePageHeader('New chain (random details)', widget.addData);
          }

          if(widget.addData!['categoryType'] == 2){
            widget.changePageHeader('New chain (challange details)', widget.addData);
          }
        }
      },
      child: Scaffold(
        backgroundColor: globalBackground,
        resizeToAvoidBottomInset: false,
        body: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [

              Padding(
                padding: EdgeInsets.all(width * 0.075),
                child: Text('Tags are meant for others to search chains like this or to be recommanded to others', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
              ),

              Padding(
                padding: EdgeInsets.all(width * 0.075),
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.00),
                    child: TextField(
                      controller: _tagController,
                      maxLines: 1,
                      maxLength: 15,
                      decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: widget.addData!['baseCategoryColor'], width: 2.0)
                        ),
                        label: Center(
                          child: Text(
                            '#Tags',
                            style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        ),
                        suffixIcon: AnimatedBuilder(
                          animation: _animationIcon, 
                          builder: (context, child) {
                            return Transform.rotate(
                              angle: 2 * pi * _animationIcon.value,
                              child: child,
                            );
                          },
                          child: IconButton(
                            onPressed: () async {

                              if(_tagController.text.trim().isNotEmpty && !tagList.contains(_tagController.text.trim())){

                                if(mounted){
                                  setState(() {
                                    tagList.add(_tagController.text.trim());
                                    _tagController.text = '';
                                  });
                                }

                                _animationControllerIcon.reset();
                                await _animationControllerIcon.forward();
                              }
                            }, 
                            icon: Image.asset('assets/image/add.png', width: width * 0.075, height: width * 0.075, color: globalTextBackground)
                          )
                        )
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(fontSize: width * 0.05, color: widget.addData!['baseCategoryColor'], fontWeight: FontWeight.bold),
                    ),
                  )
                )
              ),

              SizedBox(
                width: width * 0.85,
                child: GridView.builder(
                  physics: const NeverScrollableScrollPhysics(),
                  shrinkWrap: true,
                  itemCount: tagList.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.5
                  ), 
                  itemBuilder: ((context, index) {
                    return Padding(
                      padding: EdgeInsets.all(width * 0.01),
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.1),
                          shape: BoxShape.rectangle,
                          border: Border.all(color: widget.addData!['baseCategoryColor'], width: 1.0),
                          borderRadius: const BorderRadius.all(Radius.circular(20)),
                        ),
                        child: Row(
                          children: [
                            IconButton(
                              onPressed: () {
                                if(mounted){
                                  setState(() {
                                    tagList.removeAt(index);
                                  });
                                }
                              }, 
                              icon: Image.asset('assets/image/x.png', width: width * 0.06, height: width * 0.06, color: globalTextBackground)
                            ),
                            const Spacer(),
                            Text(tagList[index], style: GoogleFonts.nunito(fontSize: width * 0.03, color: globalTextBackground, fontWeight: FontWeight.bold)),
                            const Spacer()
                          ],
                        )
                      ),
                    );
                  })
                )
              ),  

              Padding(
                padding: EdgeInsets.only(top: width * 0.075, left: width * 0.075, right: width * 0.075, bottom: width * 0.3),
                child: Material(
                  color: widget.addData!['baseCategoryColor'],
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15))
                  ),
                  child: InkWell(
                    borderRadius: const BorderRadius.all(Radius.circular(15)),
                    onTap: () async {

                      if(tagList.isEmpty){
                        showDialog(
                          context: context, 
                          builder: (context){
                            return AlertDialog(
                              title: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Image.asset('assets/image/info.png', width: width * 0.1, height: width * 0.1),
                                  const Spacer(),
                                  Text('Just so you know', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.black87, fontWeight: FontWeight.bold)),
                                ],
                              ),
                              actionsAlignment: MainAxisAlignment.center,
                              content: Text('Generally it\'s recommanded to add some tags', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
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
                                        finishNewChainPost(context, false);
                                      }, 
                                      splashColor: globalBlue,
                                      child: Padding(
                                        padding: EdgeInsets.all(width * 0.025),
                                        child: Text('I\'m fine', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
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
                                ),
                              ]
                            );
                          }
                        );
                      }
                      else{
                        finishNewChainPost(context, true);
                      }
                    }, 
                    splashColor: widget.addData!['splashColor'],
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text('CONTINUE', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                    )
                  )
                )
              )
            ],
          )
        )
      )
    );
  }

  void finishNewChainPost(BuildContext context, bool hasTags_forPoppingAlert) async {

    final List<CameraDescription> cameraList;
    final CameraDescription camera;
    CameraController _cameraController;

    cameraList = await availableCameras();
    camera = cameraList.first;

    _cameraController = CameraController(
      camera, 
      ResolutionPreset.max,
    );

    var permissionStatus = await Permission.camera.status;

    if(!permissionStatus.isGranted){
      if(!(await Permission.camera.request().isGranted)){
        Fluttertoast.showToast(msg: 'Not enough users', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
        return;
      }
    }

    await _cameraController.initialize();
    await _cameraController.setZoomLevel(1.5);

    widget.addData!['tagList'] = tagList;

    if(hasTags_forPoppingAlert){
        if(mounted){
          Navigator.of(context).push(MaterialPageRoute(builder: (context) => CreateChainCamera(cameraList: cameraList, camera: camera, cameraBackground: CameraPreview(_cameraController), cameraController: _cameraController, addData: widget.addData, changePageHeader: widget.changePageHeader, isUserCreatingNewChain: true, callBackAfterPhoto: null)));
        }
      }
      else{
        if(mounted){
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => CreateChainCamera(cameraList: cameraList, camera: camera, cameraBackground: CameraPreview(_cameraController), cameraController: _cameraController, addData: widget.addData, changePageHeader: widget.changePageHeader, isUserCreatingNewChain: true, callBackAfterPhoto: null)));
        }
      }
  }

  @override
  void dispose(){
    _animationControllerIcon.dispose();
    super.dispose();
  }
}