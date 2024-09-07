import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  late AnimationController _controllerGossip;
  late Animation<Color?> _animationColorGossip;

  late AnimationController _controllerChainllange;
  late Animation<Color?> _animationColorChainllange;

  late Color currentColor;

  bool storySelected = true;
  bool gossipSelected = false;
  bool chainllangeSelected = false;
  int lastCategorySelected = 0;

  List<String> categoryNameByIndex = List.from({'Story', 'Gossip', 'Chainllange'});

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
      begin: Colors.black87,
      end: const Color.fromARGB(255, 102, 0, 255),
    ).animate(_controllerStory);

    _controllerGossip = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationColorGossip = ColorTween(
      begin: Colors.black87,
      end: const Color.fromARGB(255, 30, 144, 255),
    ).animate(_controllerGossip);

    _controllerChainllange = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationColorChainllange = ColorTween(
      begin: Colors.black87,
      end: const Color.fromARGB(255, 0, 150, 136),
    ).animate(_controllerChainllange);

    _controllerStory.forward();
  }

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: EdgeInsets.all(width * 0.05),
            child: Text('Select a chain category from below',
                style: GoogleFonts.nunito(
                    fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
          ),
          Padding(
            padding: EdgeInsets.all(width * 0.00),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildCategoryIcon(width, 0, 'assets/image/book.png', _animationColorStory),
                _buildCategoryIcon(width, 1, 'assets/image/gossip.png', _animationColorGossip),
                _buildCategoryIcon(width, 2, 'assets/image/challange.png', _animationColorChainllange),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(bottom: width * 0.01),
            child: Divider(
              height: 2.0,
              color: Colors.grey[200],
            ),
          ),

          _buildChainList(0, width, storySelected),
          _buildChainList(1, width, gossipSelected),
          _buildChainList(2, width, chainllangeSelected),
        ],
      ),
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
              : const Expanded(
                  child: Center(
                    child: CircularProgressIndicator(),
                  )
                )
          ) 
              
        )
      )
    );
  }

  Padding _buildCategoryIcon(double width, int catIndex, String asset, Animation<Color?> animation) {
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
            icon: Image.asset(asset, width: width * 0.1, height: width * 0.1, color: getColorForIndex(catIndex)),
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
      _controllerGossip.reverse();
    }

    if(lastCategorySelected == 2){
      _controllerChainllange.reverse();
    }

    await _animationControllerSlideRight.forward();

    if(index == 0){
      _controllerStory.forward();
    }

    if(index == 1){
      _controllerGossip.forward();
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
          gossipSelected = value;
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
        return gossipSelected ? _animationColorGossip.value : null;
      case 2:
        return chainllangeSelected ? _animationColorChainllange.value : null;
      default:
        return null;
    }
  }

  Color getColor(int index) {
    if (index == 1) {
      return const Color.fromARGB(255, 30, 144, 255);
    }

    if (index == 2) {
      return const Color.fromARGB(255, 0, 150, 136);
    }

    return const Color.fromARGB(255, 102, 0, 255); // Default color for Story
  }

  @override
  void dispose() {
    _animationControllerSlideLeft.dispose();
    _animationControllerSlideRight.dispose();
    _controllerStory.dispose();
    _controllerGossip.dispose();
    _controllerChainllange.dispose();
    super.dispose();
  }
}