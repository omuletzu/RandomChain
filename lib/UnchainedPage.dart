import 'package:doom_chain/GlobalColors.dart';
import 'package:doom_chain/Pair.dart';
import 'package:doom_chain/UnchainedElement.dart';
import 'package:doom_chain/main.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';


class UnchainedPage extends StatefulWidget{

  final String userId;
  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final Key? key;

  UnchainedPage({required this.changePageHeader, required this.userId, required this.key}) : super(key: key);

  @override
  _UnchainedPage createState() => _UnchainedPage();
}

class _UnchainedPage extends State<UnchainedPage> with SingleTickerProviderStateMixin{

  final FirebaseFirestore firebase = FirebaseFirestore.instance;
  final FirebaseStorage storage = FirebaseStorage.instance;
  bool existingUnchained = false;
  bool hasCheckedForExistingUnchained = false;
  late String userNationality;

  List<Pair> unchainedId = List.empty(growable: true);
  List<UnchainedElement> allUnchainedWidget = List.empty(growable: true);

  int totalNumberOfUnchained = 0;

  @override 
  void initState(){
    super.initState();

    _fetchFirebaseUnchained();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return Scaffold(
      body: Column(
        children: [
       
          Align(
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: Text('Down below are all the chains sent to you ($totalNumberOfUnchained)', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
            )
          ),

          Divider(
            height: 1,
            color: Colors.grey[200],
          ),

          hasCheckedForExistingUnchained ?
            (!existingUnchained 
              ? Expanded(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.075),
                    child: Text('There are no chains at the moment :(\nTry creating a chain yourself', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  )
                ),
              )
              : Expanded(
                child: SingleChildScrollView(
                  child: StaggeredGrid.count(
                  crossAxisCount: 2,
                  children: allUnchainedWidget
                )
                )
              ))
            : const Expanded(
                child: Center(
                  child: CircularProgressIndicator(),
                ),
              ),

          Divider(
            height: 1,
            color: Colors.grey[200],
          ),

          Padding(
              padding: EdgeInsets.only(top: width * 0.05, left: width * 0.2, right: width * 0.2),
              child: Center(
                child: Material(
                  color: globalPurple,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.all(Radius.circular(15))
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
                          Image.asset('assets/image/create.png', width: width * 0.1, height: width * 0.1, color: Colors.white),
                          Text('NEW CHAIN', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.white, fontWeight: FontWeight.bold))
                        ],
                      )
                    )
                  )
                ),
              )
            )
        ],
      ),
    );
  }

  Future<void> _fetchFirebaseUnchained() async {

    QuerySnapshot allUnchained = await firebase.collection('UserDetails').doc(widget.userId).collection('PendingPersonalChains').get();

    if(allUnchained.docs.isNotEmpty && mounted){
      setState(() {
        existingUnchained = true;
        totalNumberOfUnchained = allUnchained.docs.length;
      });

      allUnchained.docs.shuffle();

      for(int index = 0; index < allUnchained.docs.length; index++){

        DocumentSnapshot unchained = allUnchained.docs[index];

        Map<String, dynamic> dataMap = unchained.data() as Map<String, dynamic>;

        UnchainedElement widgetToBeAdded = UnchainedElement(userId: widget.userId, 
          firebase: firebase, 
          storage: storage, 
          calledByExplore: false,
          chainIdAndCategoryName: Pair(first: unchained.id, second: dataMap['categoryName']), 
          chainData: (await firebase.collection('PendingChains').doc(dataMap['categoryName']).collection(dataMap['chainNationality']).doc(unchained.id).get()).data() as Map<String, dynamic>, 
          changePageHeader: widget.changePageHeader,
          removeIndexFromWidgetList: () {}
        );

        widgetToBeAdded.removeIndexFromWidgetList = () {
          setState(() {
            allUnchainedWidget.clear();
            _fetchFirebaseUnchained();
          });
        };

        allUnchainedWidget.add(widgetToBeAdded);
      }
    }

    if(mounted){
      setState(() {
        hasCheckedForExistingUnchained = true;
      });
    }
  }

  @override
  void dispose(){
    super.dispose();
  }
}