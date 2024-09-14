import 'package:doom_chain/GlobalValues.dart';
import 'package:doom_chain/Pair.dart';
import 'package:doom_chain/UnchainedElement.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


class UnchainedPage extends StatefulWidget{

  final String userId;
  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final Key? key;
  final void Function(bool)? displayProgress;

  UnchainedPage({required this.changePageHeader, required this.userId, required this.key, required this.displayProgress}) : super(key: key);

  @override
  _UnchainedPage createState() => _UnchainedPage();
}

class _UnchainedPage extends State<UnchainedPage> with SingleTickerProviderStateMixin{

  final FirebaseFirestore firebase = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  final ScrollController scrollController = ScrollController();
  late QuerySnapshot? allUnchained;

  bool scrollListenerAdded = false;
  bool existingUnchained = false;
  bool hasCheckedForExistingUnchained = false;
  late String userNationality;

  List<Pair> unchainedId = List.empty(growable: true);
  List<UnchainedElement> allUnchainedWidget = List.empty(growable: true);

  int index = 0;

  @override 
  void initState(){
    super.initState();
    _fetchFirebaseUnchained();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: globalBackground,
      body: Column(
        children: [
       
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Text('Down below are all the chains sent to you', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
            )
          ),

          Padding(
            padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.025),
            child: Divider(
              height: 1,
              color: globalDrawerBackground,
            )
          ),

          Expanded(
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.topCenter,
                  child: hasCheckedForExistingUnchained
                      ? (!existingUnchained
                          ? Center(
                              child: Padding(
                                padding: EdgeInsets.all(width * 0.075),
                                child: Text(
                                  'There are no chains at the moment :(\nTry creating a chain yourself',
                                  style: GoogleFonts.nunito(
                                    fontSize: width * 0.04,
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            )
                          : SingleChildScrollView(
                              controller: scrollController,
                              child: Column(
                                children: [
                                  StaggeredGrid.count(
                                    crossAxisCount: 2,
                                    children: allUnchainedWidget,
                                  ),
                                  SizedBox(
                                    width: width,
                                    height: width * 0.3,
                                  )
                                ],
                              ),
                            ))
                      : const Center(
                          child: CircularProgressIndicator(),
                        ),
                ),

                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: EdgeInsets.only(
                      bottom: width * 0.3,  
                      left: width * 0.2,
                      right: width * 0.2,
                    ),
                    child: Material(
                      color: globalPurple.withOpacity(0.95),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.all(Radius.circular(15)),
                      ),
                      child: InkWell(
                        borderRadius: const BorderRadius.all(Radius.circular(15)),
                        onTap: () {
                          widget.changePageHeader('New chain (category)', null);
                        },
                        splashColor: globalBlue,
                        child: Padding(
                          padding: EdgeInsets.all(width * 0.02),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/image/create.png',
                                width: width * 0.1,
                                height: width * 0.1,
                                color: Colors.white,
                              ),
                              Text(
                                'NEW CHAIN',
                                style: GoogleFonts.nunito(
                                  fontSize: width * 0.05,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            )
          )
        ],
      ),
    );
  }

  Future<void> _fetchFirebaseUnchained() async {

    allUnchained = await firebase.collection('UserDetails')
      .doc(widget.userId)
      .collection('PendingPersonalChains')
      .orderBy('randomIndex')
      .limit(9)
      .get();

    if(allUnchained != null && allUnchained!.docs.isNotEmpty && mounted){
      setState(() {
        existingUnchained = true;
      });

      allUnchained!.docs.shuffle();

      updateScrollChainData();
    }

    if(mounted){
      setState(() {
        hasCheckedForExistingUnchained = true;
      });
    }
  }

  Future<void> updateScrollChainData() async {
    
    if(allUnchained!.docs.isNotEmpty){
      _addUnchainedData();
    }

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

  Future<void> _addUnchainedData() async {

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.displayProgress!(true);
    });

    List<UnchainedElement> tempList = [];

    for(DocumentSnapshot unchained in allUnchained!.docs){

      Map<String, dynamic> chainMap = unchained.data() as Map<String, dynamic>;

      UnchainedElement widgetToBeAdded = UnchainedElement(userId: widget.userId, 
        firebase: firebase, 
        storage: storage, 
        calledByExplore: false,
        chainIdAndCategoryName: Pair(first: unchained.id, second: chainMap['categoryName']), 
        chainData:  chainMap,
        changePageHeader: widget.changePageHeader,
        removeIndexFromWidgetList: () {}
      );

      tempList.add(widgetToBeAdded);
    }

    if(mounted){
      setState(() {
        allUnchainedWidget.addAll(tempList);
      });
    }

    allUnchained = await firebase.collection('UserDetails')
      .doc(widget.userId)
      .collection('PendingPersonalChains')
      .orderBy('randomIndex')
      .limit(9)
      .startAfterDocument(allUnchained!.docs.last)
      .get();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.displayProgress!(false);
    });
  }

  @override
  void dispose(){
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.displayProgress!(false);
    });
    super.dispose();
  }
}