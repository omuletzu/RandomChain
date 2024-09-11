import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:doom_chain/Pair.dart';
import 'package:doom_chain/UnchainedElement.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class ProfileViewChains extends StatefulWidget {
  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final Map<String, dynamic> userData;
  final int personalLikedSavedChains; // 0 - personal, 1 - liked, 2 - saved

  ProfileViewChains({
    required this.changePageHeader,
    required this.userData,
    required this.personalLikedSavedChains
  });

  @override
  _ProfileViewChains createState() => _ProfileViewChains();
}

class _ProfileViewChains extends State<ProfileViewChains> with TickerProviderStateMixin {
  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  late AnimationController _animationControllerSlideRight;
  late AnimationController _animationControllerSlideLeft;

  late AnimationController _controllerStory;
  late Animation<Color?> _animationColorStory;

  late AnimationController _controllerRandom;
  late Animation<Color?> _animationColorRandom;

  late AnimationController _controllerChainllange;
  late Animation<Color?> _animationColorChainllange;

  late Color currentColor;

  bool storySelected = false;
  bool randomSelected = true;
  bool chainllangeSelected = false;
  int lastCategorySelected = 1;

  List<String> categoryNameByIndex = List.from({'Story', 'Random', 'Chainllange'});

  List<List<Widget>> allCategoryChains = [[], [], []];
  List<bool> hasCheckedCategory = [false, false, false];
  List<bool> hasElementsCategory = [false, false, false];

  @override
  void initState() {
    super.initState();

    retreiveChainsFromFirebase(0);
    retreiveChainsFromFirebase(1);
    retreiveChainsFromFirebase(2);

    _animationControllerSlideRight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750)
    );

    _animationControllerSlideLeft = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750)
    );

    _animationControllerSlideLeft.forward();

    _controllerStory = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationColorStory = ColorTween(
      begin: globalTextBackground,
      end: globalPurple,
    ).animate(_controllerStory);

    _controllerRandom = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationColorRandom = ColorTween(
      begin: globalTextBackground,
      end: globalBlue,
    ).animate(_controllerRandom);

    _controllerChainllange = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationColorChainllange = ColorTween(
      begin: globalTextBackground,
      end: globalGreen,
    ).animate(_controllerChainllange);

    _controllerRandom.forward();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: ((didPop) {
        if(!didPop){
          widget.changePageHeader('Go Back', null);
        }
      }),
      child: Scaffold(
        backgroundColor: globalBackground,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [
            Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Text('Select a chain category from below',
                  style: GoogleFonts.nunito(
                      fontSize: width * 0.04, fontWeight: FontWeight.bold, color: globalTextBackground),
                  textAlign: TextAlign.center),
            ),
            Padding(
              padding: EdgeInsets.all(width * 0.00),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildCategoryIcon(width, 0, 'assets/image/book.png', _animationColorStory, storySelected),
                  _buildCategoryIcon(width, 1, 'assets/image/random.png', _animationColorRandom, randomSelected),
                  _buildCategoryIcon(width, 2, 'assets/image/challange.png', _animationColorChainllange, chainllangeSelected),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025),
              child: Divider(
                height: 2.0,
                color: globalDrawerBackground,
              ),
            ),

            _buildChainList(0, width, storySelected),
            _buildChainList(1, width, randomSelected),
            _buildChainList(2, width, chainllangeSelected),
          ],
        ),
      )
    );
  }

  Future<void> retreiveChainsFromFirebase(int categoryIndex) async {

    String personalLikedSavedChainsCategory;

    switch (widget.personalLikedSavedChains) {
      case 0:
        personalLikedSavedChainsCategory = 'FinishedChains${categoryNameByIndex[categoryIndex]}';
        break;
      case 1:
        personalLikedSavedChainsCategory = 'LikedChains${categoryNameByIndex[categoryIndex]}';
        break;
      case 2:
        personalLikedSavedChainsCategory = 'SavedChains${categoryNameByIndex[categoryIndex]}';
        break;
      default:
        personalLikedSavedChainsCategory = 'FinishedChains${categoryNameByIndex[categoryIndex]}';
    }

    QuerySnapshot allChains = await _firebase.collection('UserDetails').doc(widget.userData['userId']).collection(personalLikedSavedChainsCategory).get();

    for (DocumentSnapshot chain in allChains.docs) {
      Map<String, dynamic> chainMiniData = chain.data() as Map<String, dynamic>;

      allCategoryChains[categoryIndex].add(
        UnchainedElement(
          userId: widget.userData['userId'],
          firebase: _firebase,
          storage: _storage,
          calledByExplore: true,
          chainIdAndCategoryName: Pair(first: chain.id, second: categoryNameByIndex[categoryIndex]),
          chainData: (await _firebase
                  .collection('FinishedChains')
                  .doc(chainMiniData['categoryName'])
                  .collection(chainMiniData['chainNationality'])
                  .doc(chain.id)
                  .get())
              .data() as Map<String, dynamic>,
          changePageHeader: widget.changePageHeader,
          removeIndexFromWidgetList: () {},
        ),
      );
    }

    if(mounted){
      setState(() {
        hasCheckedCategory[categoryIndex] = true;

        if(allCategoryChains[categoryIndex].isNotEmpty){
          hasElementsCategory[categoryIndex] = true;
        }
      });
    }
  }

  Widget _buildChainList(int categoryIndex, double width, bool visible) {
    return Visibility(
      visible: visible,
      child: Expanded(
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(-2.0, 0.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideLeft, curve: Curves.easeOut)),
          child: SlideTransition(
            position: Tween<Offset>(begin: const Offset(0.0, 0.0), end: const Offset(2.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideRight, curve: Curves.easeOut)),
            child: hasCheckedCategory[categoryIndex] 
              ? (
                hasElementsCategory[categoryIndex] 
                  ? SingleChildScrollView(
                    child: StaggeredGrid.count(
                      crossAxisCount: 2,
                      children: allCategoryChains[categoryIndex],
                    ),
                  )
                  : Center(
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.1),
                        child: Text('This user has no ${categoryNameByIndex[categoryIndex]} chains in this category', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center))
                    )
              )
              : const Center(
                  child: Center(
                    child: CircularProgressIndicator(),
                  )
                )
          ) 
              
        )
      )
    );
  }

  Padding _buildCategoryIcon(double width, int catIndex, String asset, Animation<Color?> animation, bool categorySelectedBool) {
    return Padding(
      padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
      child: AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return IconButton(
            onPressed: () async {

              if(catIndex == lastCategorySelected){
                return;
              }

              updateUI(catIndex);
            },
            icon: Image.asset(asset, width: width * 0.1, height: width * 0.1, color: categorySelectedBool ? getColorForIndex(catIndex) : globalTextBackground),
          );
        },
      ),
    );
  }

  void updateUI(int index) async {

    if(lastCategorySelected == 0){
      _controllerStory.reverse();
    }

    if(lastCategorySelected == 1){
      _controllerRandom.reverse();
    }

    if(lastCategorySelected == 2){
      _controllerChainllange.reverse();
    }

    await _animationControllerSlideRight.forward();

    if(index == 0){
      _controllerStory.forward();
    }

    if(index == 1){
      _controllerRandom.forward();
    }

    if(index == 2){
      _controllerChainllange.forward();
    }

    if(mounted){
      setState(() {
        updateSelectedValues(false, lastCategorySelected);
        updateSelectedValues(true, index);
        lastCategorySelected = index;

        currentColor = getColor(index);
      });
    }


    _animationControllerSlideLeft.reset();
    _animationControllerSlideRight.reset();

    await _animationControllerSlideLeft.forward(); 

    lastCategorySelected = index;
  }

  void updateSelectedValues(bool value, int selectedIndex){
    switch(selectedIndex){
        case 0:
          storySelected = value;
          break;
        case 1:
          randomSelected = value;
          break;
        default:
          chainllangeSelected = value;
      }
  }

  Color? getColorForIndex(int catIndex) {
    switch (catIndex) {
      case 0:
        return storySelected ? _animationColorStory.value : null;
      case 1:
        return randomSelected ? _animationColorRandom.value : null;
      case 2:
        return chainllangeSelected ? _animationColorChainllange.value : null;
      default:
        return null;
    }
  }

  Color getColor(int index) {
    if (index == 1) {
      return globalBlue;
    }

    if (index == 2) {
      return globalGreen;
    }

    return globalPurple; // Default color for Story
  }

  @override
  void dispose() {
    _animationControllerSlideLeft.dispose();
    _animationControllerSlideRight.dispose();
    _controllerStory.dispose();
    _controllerRandom.dispose();
    _controllerChainllange.dispose();
    super.dispose();
  }
}
