
import 'dart:math';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:doom_chain/Pair.dart';
import 'package:doom_chain/UnchainedElement.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ExplorePage extends StatefulWidget{

  static ExplorePage? _explorePageInstance;
  static Key? lastKey;

  final Map<String, dynamic>? exploreData;
  final void Function(String, Map<String, dynamic>?)? changePageHeader;
  final Key? key;
  final void Function(bool)? displayProgress;

  ExplorePage._internal({
    required this.exploreData,
    required this.changePageHeader,
    required this.key,
    required this.displayProgress
  }) : super(key: key);

  factory ExplorePage({
    required Map<String, dynamic>? exploreData,
    required void Function(String, Map<String, dynamic>?)? changePageHeader,
    required Key? key,
    required void Function(bool)? displayProgress
  }) {

    if(lastKey == null || key != null){

      _explorePageInstance = ExplorePage._internal(
        exploreData: exploreData, 
        changePageHeader: changePageHeader, 
        key: key, displayProgress: displayProgress
      );

      lastKey = key;
    }

    key ??= lastKey;

    return _explorePageInstance!;
  }

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
  final List<DocumentSnapshot?> lastDocumentSnapshotCategory = List.filled(3, null);

  int totalNumberOfChains = 0;

  List<UnchainedElement> searchingResults = [];
  bool searchingMode = false;
  bool searchingHasElements = false;
  bool searchFinished = false;
  
  bool scrollListenerAdded = false;
  ScrollPhysics? scrollPhysics;

  int orderForCountryRandomness = 0;  // 0, 1 - same country, 2 - random country
  List<Pair> allForeignCountryWithFinishedChains = [];
  List<Pair> allForeignCountryCategoriesConsumedByAdding = [];
  List<String> allCategoriesName = ['Story', 'Random', 'Chainllange'];

  Random random = Random();

  @override
  void initState() {
    super.initState();

    if((widget.exploreData!['userId'] as String).isEmpty){
      return;
    }

    retreiveDataFromFirebase();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if(!didPop){
          if(_textController.text.isNotEmpty){
            _textController.text = '';
            setState(() {
              searchingMode = false;
            });
          }
          else{
            Navigator.of(context).pop();
          }
        }
      },
      child: Scaffold(
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
                    physics: scrollPhysics,
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
      )
    );
  }

  Future<void> retreiveDataFromFirebase() async {

    if(widget.exploreData == null){
      return;
    }

    userNationality = (await _firebase.collection('UserDetails').doc(widget.exploreData!['userId']).get()).get('countryName');

    QuerySnapshot finishedStoryReference = await _firebase.collection('FinishedChains')
        .doc('Story')
        .collection(userNationality)
        .orderBy('randomIndex')
        .limit(6)
        .get();
    QuerySnapshot finishedRandomReference = await _firebase.collection('FinishedChains')
        .doc('Random')
        .collection(userNationality)
        .orderBy('randomIndex')
        .limit(6)
        .get();
    QuerySnapshot finishedChainllangeReference = await _firebase.collection('FinishedChains')
        .doc('Chainllange')
        .collection(userNationality)
        .orderBy('randomIndex')
        .limit(6)
        .get();

    if(finishedStoryReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: Pair(first: finishedStoryReference, second: 'Story'), second: 0));
    }

    if(finishedRandomReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: Pair(first: finishedRandomReference, second: 'Random'), second: 0));
    }

    if(finishedChainllangeReference.docs.isNotEmpty){
      finishedChainsCategory.add(Pair(first: Pair(first: finishedChainllangeReference, second: 'Chainllange'), second: 0));
    }

    QuerySnapshot allCountryFinishedChainsSnapshot = await _firebase.collection('AllCountryFinishedChains').get();
    
    allCountryFinishedChainsSnapshot.docs.removeWhere((element) => element.id.compareTo(userNationality) == 0);

    for(DocumentSnapshot country in allCountryFinishedChainsSnapshot.docs){
      if(country.id != userNationality){
        allForeignCountryWithFinishedChains.add(Pair(first: Pair(first: country.id, second: ''), second: Pair(first: 0, second: null)));
      }
    }

    if(finishedChainsCategory.isNotEmpty || allForeignCountryWithFinishedChains.isNotEmpty){
     
      await updateScrollChainData();
      await updateScrollChainData();

      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted){
          setState(() {
            existingChains = true;
          });
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted){
        setState(() {
          hasCheckedForExistingChains = true;
        });
      }
    });
  }

  void _searchByTag(String tagToSearch) async {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted){
        setState(() {
          searchFinished = false;
          searchingHasElements = false;
        });
      }
    });

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
      
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if(mounted){
          setState(() {
            searchingHasElements = true;
          });
        }
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if(mounted){
        setState(() {
          searchFinished = true;
          searchingResults.addAll(tempSearchingResults);
        });
      }
    });
  }

  Future<void> updateScrollChainData() async {
    
    if(orderForCountryRandomness == 0 && finishedChainsCategory.isNotEmpty){
      _addDataFromSameCountry();
    }
    else if(allForeignCountryWithFinishedChains.isNotEmpty){
      _addDataFromDifferentCountry();
    }

    orderForCountryRandomness = (orderForCountryRandomness + 1) % 2;

    if(!scrollListenerAdded){
      scrollController.addListener(() {
        _scrollListenerFunction();
      });

      scrollListenerAdded = true;
    }
  }

  void _scrollListenerFunction(){

    if(scrollController.position.pixels >= scrollController.position.maxScrollExtent){

      updateScrollChainData();
    }
  }

  void _addDataFromSameCountry() async {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.displayProgress!(true);
    });

    for(int i = 0; i < 9; i++){

      if(finishedChainsCategory.isEmpty){
        WidgetsBinding.instance.addPostFrameCallback((_) {
          widget.displayProgress!(false);
        });
        return;
      }

      int categoryIndex = random.nextInt(finishedChainsCategory.length);

      QuerySnapshot selectedQueryReference = (finishedChainsCategory[categoryIndex].first as Pair).first as QuerySnapshot;
      String selectedCategoryName = (finishedChainsCategory[categoryIndex].first as Pair).second as String;
      int selectedLastIndex = finishedChainsCategory[categoryIndex].second as int;

      allChainsWidget.add(
        Pair(
          first: UnchainedElement(
            userId: widget.exploreData!['userId'], 
            firebase: _firebase, 
            storage: _storage, 
            calledByExplore: true,
            chainIdAndCategoryName: Pair(
              first: selectedQueryReference.docs[selectedLastIndex].id, 
              second: selectedCategoryName
            ), 
            chainData: selectedQueryReference.docs[selectedLastIndex].data() as Map<String, dynamic>, 
            changePageHeader: widget.changePageHeader!, 
            removeIndexFromWidgetList: () {}
          ), 
          second: selectedQueryReference.docs[selectedLastIndex].id
        )
      );
      
      selectedLastIndex++;

      if(selectedLastIndex >= selectedQueryReference.docs.length){
        QuerySnapshot tempSnapshot = await _firebase.collection('FinishedChains')
          .doc(selectedCategoryName)
          .collection(userNationality)
          .orderBy('randomIndex')
          .startAfterDocument(selectedQueryReference.docs.last)
          .limit(6)
          .get();

        if(mounted){
          setState(() {
            if(tempSnapshot.docs.isEmpty){
              finishedChainsCategory.removeAt(categoryIndex);
            }
            else{
              (finishedChainsCategory[categoryIndex].first as Pair).first = tempSnapshot;
              finishedChainsCategory[categoryIndex].second = 0;
            }
          });
        }
      }
      else{
        if(mounted){
          setState(() {
            finishedChainsCategory[categoryIndex].second = selectedLastIndex;
          });
        }
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.displayProgress!(false);
    });
  }

  void _addDataFromDifferentCountry() async {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.displayProgress!(true);
    });

    List<Pair> tempList = [];

    for(int i = 0; i < 9 && allForeignCountryWithFinishedChains.isNotEmpty; i++){

      int randomUserIndex = random.nextInt(allForeignCountryWithFinishedChains.length);
      String countryName = (allForeignCountryWithFinishedChains[randomUserIndex].first as Pair).first as String;

      String selectedLastCategory = (allForeignCountryWithFinishedChains[randomUserIndex].first as Pair).second as String;
      int selectedCountryLastIndex = (allForeignCountryWithFinishedChains[randomUserIndex].second as Pair).first as int;
      QuerySnapshot? selectedCountryLastQuerySnapshot = (allForeignCountryWithFinishedChains[randomUserIndex].second as Pair).second as QuerySnapshot?;

      int randomCategoryNameIndex = random.nextInt(allCategoriesName.length);

      if(selectedCountryLastQuerySnapshot == null){

        if(!_checkIfPairContainedInList(allForeignCountryCategoriesConsumedByAdding, Pair(first: countryName, second: allCategoriesName[randomCategoryNameIndex]))){
          selectedCountryLastQuerySnapshot = await _firebase.collection('FinishedChains').doc(allCategoriesName[randomCategoryNameIndex])
          .collection(countryName)
          .orderBy('randomIndex')
          .limit(6)
          .get();
        }

        int categoryCounter = 0;

        while(selectedCountryLastQuerySnapshot != null && selectedCountryLastQuerySnapshot.docs.isEmpty && categoryCounter < 2){
          randomCategoryNameIndex = (randomCategoryNameIndex + 1) % allCategoriesName.length;

          if(!_checkIfPairContainedInList(allForeignCountryCategoriesConsumedByAdding, Pair(first: countryName, second: allCategoriesName[randomCategoryNameIndex]))){
            selectedCountryLastQuerySnapshot = await _firebase.collection('FinishedChains').doc(allCategoriesName[randomCategoryNameIndex])
            .collection(countryName)
            .orderBy('randomIndex')
            .limit(6)
            .get();
          }

            categoryCounter++;
        }

        if(categoryCounter >= 2){
          allForeignCountryWithFinishedChains.removeAt(randomUserIndex);
          i--;
          continue;
        }

        selectedLastCategory = (allForeignCountryWithFinishedChains[randomUserIndex].first as Pair).second = allCategoriesName[randomCategoryNameIndex];
        (allForeignCountryWithFinishedChains[randomUserIndex].second as Pair).second = selectedCountryLastQuerySnapshot;
        selectedCountryLastIndex = (allForeignCountryWithFinishedChains[randomUserIndex].second as Pair).first = 0;
      }

      if(selectedCountryLastQuerySnapshot == null){
        allForeignCountryWithFinishedChains.removeAt(randomUserIndex);
        i--;
        continue;
      }

      tempList.add(
        Pair(
          first: UnchainedElement(
            userId: widget.exploreData!['userId'], 
            firebase: _firebase, 
            storage: _storage, 
            calledByExplore: true, 
            chainIdAndCategoryName: Pair(
              first: selectedCountryLastQuerySnapshot!.docs[selectedCountryLastIndex].id, 
              second: selectedLastCategory
            ), 
            chainData: selectedCountryLastQuerySnapshot.docs[selectedCountryLastIndex].data() as Map<String, dynamic>, 
            changePageHeader: widget.changePageHeader!, 
            removeIndexFromWidgetList: () {}
          ), 
          second: selectedCountryLastQuerySnapshot.docs[selectedCountryLastIndex].id
        )
      );
      
      selectedCountryLastIndex++;

      if(selectedCountryLastIndex >= selectedCountryLastQuerySnapshot.docs.length){
        QuerySnapshot tempSnapshot = await _firebase.collection('FinishedChains')
          .doc(selectedLastCategory)
          .collection(countryName)
          .orderBy('randomIndex')
          .startAfterDocument(selectedCountryLastQuerySnapshot.docs.last)
          .limit(6)
          .get();

        if(tempSnapshot.docs.isEmpty){
          (allForeignCountryWithFinishedChains[randomUserIndex].second as Pair).second = null;
          allForeignCountryCategoriesConsumedByAdding.add(
            Pair(first: countryName, second: selectedLastCategory)
          );
        }
        else{
          (allForeignCountryWithFinishedChains[randomUserIndex].second as Pair).second = tempSnapshot;
        }

        (allForeignCountryWithFinishedChains[randomUserIndex].second as Pair).first = 0;
      }
      else{
        (allForeignCountryWithFinishedChains[randomUserIndex].second as Pair).first = selectedCountryLastIndex;
      }
    }

    if(mounted){
      setState(() {
        allChainsWidget.addAll(tempList);
      });
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.displayProgress!(false);
    });
  }

  bool _checkIfPairContainedInList(List<Pair> listPair, Pair pair){
    for(Pair indexPair in listPair){
      if(indexPair.first == pair.first && indexPair.second == pair.second){
        return true;
      }
    }

    return false;
  }

  @override
  void dispose(){
    scrollController.removeListener(_scrollListenerFunction);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.displayProgress!(false);
    });
    super.dispose();
  }
}