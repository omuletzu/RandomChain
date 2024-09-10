import 'dart:convert';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalColors.dart';
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

  List<UnchainedElement> searchingResults = [];
  bool searchingMode = false;
  bool searchingHasElements = false;
  bool searchFinished = false;
  
  bool scrollListenerAdded = false;

  int orderForCountryRandomness = 0;  // 0, 1 - same country, 2 - random country
  List<String> allForeignCountryWithFinishedChains = [];
  List<String> allCategoriesName = ['Story', 'Random', 'Chainllange'];

  Random random = Random();

  @override
  void initState() {

    if((widget.exploreData!['userId'] as String).isEmpty){
      return;
    }

    retreiveDataFromFirebase();
    super.initState();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: globalBackground,
      resizeToAvoidBottomInset: false,
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
                  focusColor: globalBlue,
                  suffixIcon: const Icon(Icons.search),
                  suffixIconColor: globalTextBackground,
                  label: Center(
                    child: Text(
                      'Search tag',
                      style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold),
                    ),
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: width * 0.01)
                ),
                
                textAlign: TextAlign.center,
                style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalPurple, fontWeight: FontWeight.bold),
                onChanged: (value) {
                  if(mounted){
                    if(value.isEmpty){
                      setState(() {
                        searchingMode = false;
                      });
                    }
                    else{
                      setState(() {
                        _searchByTag(value.toLowerCase().trim());
                        searchingMode = true;
                      });
                    }
                  }
                },
              )
            ),
          ),

          Padding(
            padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025),
            child: Divider(
              height: 1,
              color: globalDrawerBackground,
            ),
          ),

          !searchingMode 
            ? hasCheckedForExistingChains ?
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
              )
          : searchFinished ?
            (
              searchingHasElements ?
                Expanded(
                  child: SingleChildScrollView(
                    controller: scrollController,
                    child: StaggeredGrid.count(
                    crossAxisCount: 2,
                    children: searchingResults
                  )
                )
              )
              : Expanded(
                child: Center(
                  child: Text('No chains found :(', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                ),
              )
            )
            : const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              )
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
    QuerySnapshot finishedrandomReference = await _firebase.collection('FinishedChains').doc('Random').collection(userNationality).get();
    QuerySnapshot finishedChainllangeReference = await _firebase.collection('FinishedChains').doc('Chainllange').collection(userNationality).get();

    if(finishedStoryReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: finishedStoryReference, second: 'Story'));
    }

    if(finishedrandomReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: finishedrandomReference, second: 'Random'));
    }

    if(finishedChainllangeReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: finishedChainllangeReference, second: 'Chainllange'));
    }

    totalNumberOfChains = finishedStoryReference.docs.length + finishedrandomReference.docs.length + finishedChainllangeReference.docs.length;

    QuerySnapshot allCountryFinishedChainsSnapshot = await _firebase.collection('AllCountryFinishedChains').get();

    for(DocumentSnapshot country in allCountryFinishedChainsSnapshot.docs){
      allForeignCountryWithFinishedChains.add(country.id);
    }

    if(finishedChainsCategory.isNotEmpty || allForeignCountryWithFinishedChains.isNotEmpty){

      await updateScrollChainData();
      if(allChainsWidget.length >= totalNumberOfChains){
        updateScrollChainData();
      }

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

  void _searchByTag(String tagToSearch) async {

    if(mounted){
      setState(() {
        searchFinished = false;
        searchingHasElements = false;
      });
    }

    searchingResults.clear();
    List<UnchainedElement> tempSearchingResults = [];

    DocumentSnapshot searchingDocuments = await _firebase.collection('ChainTags').doc(tagToSearch).get();
    
    if(searchingDocuments.exists){
      for(var mapEntry in (searchingDocuments.data() as Map<String, dynamic>).entries){

        List<dynamic> chainMiniDetails = jsonDecode(mapEntry.value);
        
        Map<String, dynamic> chainDetails = (await _firebase.collection('FinishedChains').doc(chainMiniDetails[0]).collection(chainMiniDetails[1]).doc(mapEntry.key).get()).data() as Map<String, dynamic>;

        tempSearchingResults.add(
          UnchainedElement(
            userId: widget.exploreData!['userId'], 
            firebase: _firebase, 
            storage: _storage, 
            calledByExplore: true, 
            chainIdAndCategoryName: Pair(first: mapEntry.key, second: chainMiniDetails[0]), 
            chainData: chainDetails, 
            changePageHeader: widget.changePageHeader!, 
            removeIndexFromWidgetList: () {})
        );
      };
      
      if(mounted){
        setState(() {
          searchingHasElements = true;
        });
      }
    }

    if(mounted){
      setState(() {
        searchFinished = true;
        searchingResults.addAll(tempSearchingResults);
      });
    }
  }


  Future<void> updateScrollChainData() async {

    if(allChainsWidget.length >= totalNumberOfChains){
      _addDataFromDifferentCountry();
    }
    else{
      if(orderForCountryRandomness == 0){
        _addDataFromSameCountry();
      }
      else{
        _addDataFromDifferentCountry();
      }

      orderForCountryRandomness = (orderForCountryRandomness + 1) % 2;
    }

    if(!scrollListenerAdded){
      scrollController.addListener(() {
        _scrollListenerFunction();
      });

      scrollListenerAdded = true;
    }
  }

  void _scrollListenerFunction(){
    if(scrollController.position.atEdge){
      if(scrollController.position.pixels != 0){
        updateScrollChainData();
      }
    }
  }

  void _addDataFromSameCountry() async {

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
  }

  void _addDataFromDifferentCountry() async {

    List<Pair> tempList = [];

    for(int i = 0; i < 5; i++){
      int randomUserIndex = random.nextInt(allForeignCountryWithFinishedChains.length);
      String countryName = allForeignCountryWithFinishedChains[randomUserIndex];

      if(countryName == userNationality){
        continue;
      }

      int randomCategoryNameIndex = random.nextInt(allCategoriesName.length);
      QuerySnapshot randomForeignChains = await _firebase.collection('FinishedChains').doc(allCategoriesName[randomCategoryNameIndex]).collection(countryName).get();

      while(randomForeignChains.docs.isEmpty){
        randomCategoryNameIndex = (randomCategoryNameIndex + 1) % allCategoriesName.length;
        randomForeignChains = await _firebase.collection('FinishedChains').doc(allCategoriesName[randomCategoryNameIndex]).collection(countryName).get();
      }

      int randomChainIndexFromFinalChainList = random.nextInt(randomForeignChains.docs.length);

      if(!allChainsWidget.map((e) => e.second).contains(randomForeignChains.docs[randomChainIndexFromFinalChainList].id)){
        if(!tempList.map((e) => e.second).contains(randomForeignChains.docs[randomChainIndexFromFinalChainList].id)){
          tempList.add(
            Pair(
              first: UnchainedElement(
                userId: widget.exploreData!['userId'], 
                firebase: _firebase, 
                storage: _storage, 
                calledByExplore: true, 
                chainIdAndCategoryName: Pair(
                  first: randomForeignChains.docs[randomChainIndexFromFinalChainList].id, 
                  second: allCategoriesName[randomCategoryNameIndex]
                ), 
                chainData: randomForeignChains.docs[randomChainIndexFromFinalChainList].data() as Map<String, dynamic>, 
                changePageHeader: widget.changePageHeader!, 
                removeIndexFromWidgetList: () {}
              ), 
              second: randomForeignChains.docs[randomChainIndexFromFinalChainList].id
            )
          );
        }
      }
    }

    if(mounted){
      setState(() {
        allChainsWidget.addAll(tempList);
      });
    }
  }

  @override
  void dispose(){
    scrollController.removeListener(_scrollListenerFunction);
    super.dispose();
  }
}