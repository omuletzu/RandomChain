import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/Pair.dart';
import 'package:doom_chain/UnchainedViewChain.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class UnchainedElement extends StatefulWidget{
  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final Pair chainIdAndCategoryName;
  final Map<String, dynamic> chainData;
  final String userId;
  final bool calledByExplore;
  final FirebaseFirestore firebase;
  final FirebaseStorage storage;
  void Function() removeIndexFromWidgetList;

  UnchainedElement({required this.userId, 
  required this.firebase, 
  required this.storage, 
  required this.calledByExplore,
  required this.chainIdAndCategoryName, 
  required this.chainData, 
  required this.changePageHeader,
  required this.removeIndexFromWidgetList});

  @override
  _UnchainedElement createState() => _UnchainedElement();
}

class _UnchainedElement extends State<UnchainedElement>{

  late Color categoryColor;
  String containerImageUrl = '';
  bool containerImageLoaded = false;
  bool hasImage = false;
  List<String>tagList = List.empty(growable: true);
  String titleCategoryIconAssetPath = 'assets/image/book.png';

  String title = ' ';
  String theme = ' ';
  bool allPieces = false;
  bool random = false;

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
      padding: EdgeInsets.all(width * 0.03),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(15)),
        child: Material(
          color: Colors.grey.withOpacity(0.1),
          child: InkWell(
            splashColor: containerImageLoaded ? categoryColor.withOpacity(0.1) : Colors.grey[200],
            
            onTap: () {
              Navigator.of(context).push(MaterialPageRoute(builder: (context) => UnchainedViewChain(
                firebase: widget.firebase, storage: widget.storage, 
                width: width, categoryAssetPath: titleCategoryIconAssetPath, 
                chainMap: widget.chainData, categoryColor: categoryColor, 
                categoryName: widget.chainIdAndCategoryName.second as String, 
                contributors: contributors, changePageHeader: widget.changePageHeader, 
                userId: widget.userId, chainId: widget.chainIdAndCategoryName.first as String,
                chainNationality: widget.chainData['chainNationality'], removeIndex: widget.removeIndexFromWidgetList,
                calledByExplore: widget.calledByExplore)));
            },

            child: AnimatedContainer(
              duration: const Duration(milliseconds: 500),
              decoration: BoxDecoration(
                border: Border.all(width: 2.0, color: containerImageLoaded ? categoryColor : Colors.transparent),
                borderRadius: const BorderRadius.all(Radius.circular(15)),
              ),
              child: Column(
                children: [

                  Visibility(
                    visible: containerImageLoaded,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Padding(
                          padding: EdgeInsets.all(width * 0.01),
                          child: Image.asset(titleCategoryIconAssetPath, width: width * 0.075, height: width * 0.075),
                        ),

                        Padding(
                          padding: EdgeInsets.all(width * 0.01),
                          child: Text(containerImageLoaded ? title : ' ', style: GoogleFonts.nunito(fontSize: width * 0.045, color: containerImageLoaded ? categoryColor : Colors.transparent, fontWeight: FontWeight.bold)),
                        )
                      ],
                    )
                  ),

                  Padding(
                    padding: EdgeInsets.all(width * 0.01),
                    child: Text(containerImageLoaded ? theme : ' ', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),

                  Visibility(
                    visible: hasImage,
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.04),
                      child: ClipRRect(
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        child: containerImageLoaded 
                        ? Image.network(
                            containerImageUrl, 
                            fit: BoxFit.cover,
                            loadingBuilder: (context, child, loadingProgress) {
                              if(loadingProgress == null){
                                return child;
                              }
                              else{
                                return CircularProgressIndicator(color: categoryColor);
                              }
                            },
                        )
                        : CircularProgressIndicator(color: categoryColor)
                      )
                    )
                  ),

                  Visibility(
                    visible: containerImageLoaded,
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.01),
                      child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: allPieces ? Image.asset('assets/image/logo.png', width: width * 0.075, height: width * 0.075) : Image.asset('assets/image/one.png', width: width * 0.075, height: width * 0.075)
                          ),

                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: random ? Image.asset('assets/image/random.png', width: width * 0.075, height: width * 0.075) : Image.asset('assets/image/friends.png', width: width * 0.075, height: width * 0.075)
                          )
                        ],
                      )
                    )
                  ),

                  Visibility(
                    visible: tagList.isNotEmpty,
                    child: Padding(
                      padding: EdgeInsets.all(width * 0.025),
                      child: Text(tagList.join(' '), style: GoogleFonts.nunito(fontSize: width * 0.035, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    )
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
    
    String chainId = widget.chainIdAndCategoryName.first as String;
    String categoryName = widget.chainIdAndCategoryName.second as String;

    if(categoryName == 'Story'){
      categoryColor = const Color.fromARGB(255, 102, 0, 255);
    }else if(categoryName == 'Gossip'){
      categoryColor = const Color.fromARGB(255, 30, 144, 255);
      titleCategoryIconAssetPath = 'assets/image/gossip.png';
    }else if(categoryName == "Chainllange"){
      categoryColor = const Color.fromARGB(255, 0, 150, 136);
      titleCategoryIconAssetPath = 'assets/image/challange.png';
    }else{
      categoryColor = const Color.fromARGB(255, 102, 0, 255);
    }

    List<dynamic> contributions = jsonDecode(widget.chainData['contributions']);
    String? lastPhotoStorageId;

    if(contributions.isNotEmpty){
      
      for(dynamic item in contributions){

        List<dynamic> tuplaDecoded = jsonDecode(jsonEncode(item)) as List<dynamic>; 

        if(lastPhotoStorageId == null){
          lastPhotoStorageId = tuplaDecoded[2];
        }
        else{
          if(tuplaDecoded.last.compareTo(lastPhotoStorageId!) > 0 || (lastPhotoStorageId == '-' && tuplaDecoded.last != '-')){
            lastPhotoStorageId = tuplaDecoded[2];
          }
        }

        contributors.add([tuplaDecoded[0], tuplaDecoded[1], tuplaDecoded[2]]);
      }
    }

    if(lastPhotoStorageId != null && lastPhotoStorageId != '-'){
      Reference lastPhotoReference = widget.storage.ref().child(lastPhotoStorageId);
      containerImageUrl = await lastPhotoReference.getDownloadURL();

      if(mounted){
        setState(() {
          hasImage = true;
        });
      }
    }

    tagList = List.from(jsonDecode(widget.chainData['tagList'])).map((e) => '#$e').toList();

    if(mounted){
      setState(() {

        title = widget.chainData['title'];
        theme = widget.chainData['theme'];
        allPieces = widget.chainData['allPieces'];
        random = widget.chainData['random'];

        containerImageLoaded = true;
      });
    }
  }
}