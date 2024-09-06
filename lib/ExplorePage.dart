import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:country_picker/country_picker.dart';
import 'package:doom_chain/Pair.dart';
import 'package:doom_chain/UnchainedElement.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ExplorePage extends StatefulWidget{

  final Map<String, dynamic>? exploreData;
  final void Function(String, Map<String, dynamic>?)? changePageHeader;
  final Key? key;

  ExplorePage({
    required this.exploreData,
    required this.changePageHeader,
    required this.key
  }) : super(key: key);

  @override
  _ExplorePage createState() => _ExplorePage();
}

class _ExplorePage extends State<ExplorePage>{

  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  late String userNationality;
  bool hasCheckedForExistingChains = false;
  bool existingChains = false;

  List<Pair> allChainsWidget = List.empty(growable: true);
  final List<Pair> finishedChainsCategory = List.empty(growable: true);

  int totalNumberOfChains = 0;

  Random random = Random();

  @override
  void initState() {
    retreiveDataFromFirebase();
    super.initState();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          
          Padding(
            padding: EdgeInsets.only(left: width * 0.075, right: width * 0.075, top: width * 0.025, bottom: width * 0.025),
            child: AnimatedContainer(
              duration: const Duration(seconds: 2),
              child: TextField(
                controller: _textController,
                maxLines: null,
                decoration: InputDecoration(
                  border: const OutlineInputBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15)),
                    borderSide: BorderSide(width: 2.0),
                  ),
                  suffixIcon: GestureDetector(
                    onTap: () {

                    },
                    child: const Icon(Icons.search),
                  ),
                  focusColor: const Color.fromARGB(255, 30, 144, 255),
                  label: Center(
                    child: Text(
                      'Search chain',
                      style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: width * 0.01)
                ),
                
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: width * 0.04, color: const Color.fromARGB(255, 102, 0, 255), fontWeight: FontWeight.bold)
              )
            ),
          ),

          Divider(
            height: 1,
            color: Colors.grey[200],
          ),

          hasCheckedForExistingChains ?
            (!existingChains 
              ? Expanded(
                child: Center(
                  child: Text('There are no chains at the moment :(\nTry creating a chain yourself', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                ),
              )
              : Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  child: StaggeredGrid.count(
                  crossAxisCount: 2,
                  children: allChainsWidget.map((e) => e.first as Widget).toList()
                )
                )
              ))
            : const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
        ],
      ),
    );
  }

  Future<void> retreiveDataFromFirebase() async {

    if(widget.exploreData == null){
      return;
    }

    userNationality = (await _firebase.collection('UserDetails').doc(widget.exploreData!['userId']).get()).get('countryName');

    QuerySnapshot finishedStoryReference = await _firebase.collection('FinishedChains').doc('Story').collection(userNationality).get();
    QuerySnapshot finishedGossipReference = await _firebase.collection('FinishedChains').doc('Gossip').collection(userNationality).get();
    QuerySnapshot finishedChainllangeReference = await _firebase.collection('FinishedChains').doc('Chainllange').collection(userNationality).get();

    if(finishedStoryReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: finishedStoryReference, second: 'Story'));
    }

    if(finishedGossipReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: finishedGossipReference, second: 'Gossip'));
    }

    if(finishedChainllangeReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: finishedChainllangeReference, second: 'Chainllange'));
    }

    totalNumberOfChains = finishedStoryReference.docs.length + finishedGossipReference.docs.length + finishedChainllangeReference.docs.length;

    if(finishedChainsCategory.isNotEmpty){
        updateScrollChainData();
        if(mounted){
          setState(() {
            existingChains = true;
          });
        }
      }

    if(mounted){
      setState(() {
        hasCheckedForExistingChains = true;
      });
    }
  }


  Future<void> updateScrollChainData() async {

    if(allChainsWidget.length >= totalNumberOfChains){
      return;
    }

    for(int i = 0; i < 5; i++){

      int categoryIndex = random.nextInt(finishedChainsCategory.length);
      int index = random.nextInt((finishedChainsCategory[categoryIndex].first as QuerySnapshot).docs.length);

      if(allChainsWidget.length >= totalNumberOfChains){
        break;
      }
      else{

        if(!allChainsWidget.map((e) => e.second).contains((finishedChainsCategory[categoryIndex].first as QuerySnapshot).docs[index].id)){

          allChainsWidget.add(
            Pair(
              first: UnchainedElement(
                userId: widget.exploreData!['userId'], 
                firebase: _firebase, 
                storage: _storage, 
                calledByExplore: true,
                chainIdAndCategoryName: Pair(
                  first: (finishedChainsCategory[categoryIndex].first as QuerySnapshot).docs[index].id, 
                  second: (finishedChainsCategory[categoryIndex].second as String)
                ), 
                chainData: (finishedChainsCategory[categoryIndex].first as QuerySnapshot).docs[index].data() as Map<String, dynamic>, 
                changePageHeader: widget.changePageHeader!, 
                removeIndexFromWidgetList: () {}
              ), 
              second: (finishedChainsCategory[categoryIndex].first as QuerySnapshot).docs[index].id
            )
          );
        }
        else{
          i--;
        }
      }
    }

    scrollController.addListener(() {
      if(scrollController.position.atEdge){
        if(scrollController.position.pixels != 0){
          updateScrollChainData();
        }
      }
    });
  }
}