import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/FriendElement.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FriendsPageStrangers extends StatefulWidget{

  final String userId;
  final void Function(String, Map<String, dynamic>?) changePageHeader;

  FriendsPageStrangers({
    required this.userId,
    required this.changePageHeader,
  });

  @override
  _FriendsPageStrangers createState() => _FriendsPageStrangers();
}

class _FriendsPageStrangers extends State<FriendsPageStrangers>{

  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool hasCheckedForExistingFriends = false;
  bool searchingMode = false;
  bool scrollListenerAdded = false;

  int index = 0;

  List<FriendElement> allFriendsList = [];
  Future<List<FriendElement>>? listToDisplay;
  List<FriendElement> tempListToDisplay = [];

  Map<String, dynamic>? userDetails;
  QuerySnapshot? queryAllPeopleDifferentCountry;
  QuerySnapshot? queryAllPeopleSameCountry;
  QuerySnapshot? filteredFriends;
  String filterNickname = '';
  bool queryOrder = false;

  @override
  void initState() {
    super.initState();

    retreiveFriendsFirebase(false);
    retreiveFriendsFirebase(true);
    listToDisplay = Future.value(allFriendsList);
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop){
        if(!didPop){
          if(_textController.text.isNotEmpty){
            _textController.text = '';
            setState(() {
              searchingMode = false;
              listToDisplay = Future.value(allFriendsList);
            });
          }
          else{
            widget.changePageHeader('Go Back', null);
          }
        }
      },
      child: Scaffold(
        backgroundColor: globalBackground,
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [

            Align(
              alignment: Alignment.center,
                child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Text('Find out new people', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
              )
            ),

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
                        'Nickname',
                        style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold),
                      ),
                    ),
                    contentPadding: EdgeInsets.symmetric(vertical: width * 0.01)
                  ),
                  
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalPurple, fontWeight: FontWeight.bold),
                  onChanged: (value) async {
                    if(mounted && value.isEmpty){
                      setState(() {
                        searchingMode = false;
                        listToDisplay = Future.value(allFriendsList);
                      });
                    }
                    else{
                      setState(() {
                        filterNickname = value.toLowerCase().trim();
                        searchingMode = true;
                        hasCheckedForExistingFriends = false;
                      });
                      tempListToDisplay = [];
                      filteredFriends = null;
                      listToDisplay = _searchByNickname();
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

            Expanded(
              child: FutureBuilder<List<FriendElement>>(
                future: listToDisplay,
                builder: (context, snapshot) {

                  if(!snapshot.hasData || snapshot.data!.isEmpty){

                    if(searchingMode){
                      return Center(
                        child: Text('No users found\nPlease type the full nickname', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                      );
                    }

                    if(hasCheckedForExistingFriends && allFriendsList.isEmpty){
                      return Center(
                        child: Text('No users at the moment', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                      );
                    }

                    return const Center(
                      child: CircularProgressIndicator()
                    );

                  } else if(snapshot.hasError){
                    return const Center(
                      child: Icon(Icons.error),
                    );
                  }
                  
                  return SingleChildScrollView(
                    child: StaggeredGrid.count(
                      crossAxisCount: 3,
                      children: snapshot.data!,
                    )
                  );
                },
              ),
            )
          ],
        ),
      )
    );
  }

  Future<List<FriendElement>> retreiveFriendsFirebase(bool queryOrder) async {
  
    userDetails ??= (await _firebase.collection('UserDetails').doc(widget.userId).get()).data() as Map<String, dynamic>;

    if(!queryOrder){
      if(queryAllPeopleSameCountry == null){
        queryAllPeopleSameCountry = await _firebase.collection('UserDetails')
          .where('countryName', isEqualTo: userDetails!['countryName'])
          .orderBy('randomIndex')
          .limit(13)
          .get();
      }
      else{
        queryAllPeopleSameCountry = await _firebase.collection('UserDetails')
          .where('countryName', isEqualTo: userDetails!['countryName'])
          .orderBy('randomIndex')
          .startAfterDocument(queryAllPeopleSameCountry!.docs.last)
          .limit(13)
          .get();
      }
    }
    else{
      if(queryAllPeopleDifferentCountry == null){
        queryAllPeopleDifferentCountry = await _firebase.collection('UserDetails')
          .where('countryName', isNotEqualTo: userDetails!['countryName'])
          .orderBy('randomIndex')
          .limit(13)
          .get();
      }
      else{
        queryAllPeopleDifferentCountry = await _firebase.collection('UserDetails')
          .where('countryName', isNotEqualTo: userDetails!['countryName'])
          .orderBy('randomIndex')
          .startAfterDocument(queryAllPeopleDifferentCountry!.docs.last)
          .limit(13)
          .get();
      }
    }

    if(!queryOrder){
      if(queryAllPeopleSameCountry != null && queryAllPeopleSameCountry!.docs.isNotEmpty){
        _addUserElements(queryAllPeopleSameCountry!);
      }
    }
    else{
      if(queryAllPeopleDifferentCountry != null && queryAllPeopleDifferentCountry!.docs.isNotEmpty){
        _addUserElements(queryAllPeopleDifferentCountry!);
      }
    }

    queryOrder = !queryOrder;

    if(!scrollListenerAdded){   
      scrollController.addListener(scrollListenerFunction);
      scrollListenerAdded = true;
    }

    if(mounted && !hasCheckedForExistingFriends){
      setState(() {
        hasCheckedForExistingFriends = true;
      });
    }

    return allFriendsList;
  }

  void _addUserElements(QuerySnapshot queryUsers) async {

    List<FriendElement> tempList = [];

    for(DocumentSnapshot user in queryUsers.docs){

      if(user.id == widget.userId){
        continue;
      }

      if((await _firebase.collection('UserDetails').doc(widget.userId).collection('Friends').doc(user.id).get()).exists){
        continue;
      }
      
      Map<String, dynamic> friendData = (await _firebase.collection('UserDetails').doc(user.id).get()).data() as Map<String, dynamic>;

      tempList.add(
        FriendElement(
          userId: widget.userId, 
          friendId: user.id,
          firebase: _firebase, 
          storage: _storage,
          friendData: friendData,
          changePageHeader: widget.changePageHeader,
          friendOrStranger : false,
          isThisRequests: false,
          userNickname: '',
          increaseFriendCount: (x) {},
        )
      );
    }

    if(mounted){
      setState(() {
        searchingMode 
          ? tempListToDisplay.addAll(tempList) 
          : allFriendsList.addAll(tempList);
      });
    }
  }
  
  void scrollListenerFunction(){
    if(scrollController.position.pixels == scrollController.position.maxScrollExtent){
      if(searchingMode){
        _searchByNickname();
      }
      else{
        retreiveFriendsFirebase(queryOrder);
        queryOrder = !queryOrder;
      }
    }
  }

  Future<List<FriendElement>> _searchByNickname() async {

    if(filteredFriends == null){
      filteredFriends = await _firebase.collection('UserDetails')
        .where('nicknameLowercase', isEqualTo: filterNickname)
        .limit(13)
        .get();
    }
    else{
      filteredFriends = await _firebase.collection('UserDetails')
        .where('nicknameLowercase', isEqualTo: filterNickname)
        .startAfterDocument(filteredFriends!.docs.last)
        .limit(13)
        .get();
    }
  
    if(filteredFriends!.docs.isNotEmpty){
      _addUserElements(filteredFriends!);
    }

    if(mounted && !hasCheckedForExistingFriends){
      setState(() {
        hasCheckedForExistingFriends = true;
      });
    }

    return tempListToDisplay;
  }

  @override
  void dispose(){
    _textController.dispose();
    if(scrollListenerAdded){
      scrollController.removeListener(scrollListenerFunction);
      scrollListenerAdded = false;
    }
    scrollController.dispose();
    super.dispose();
  }
}