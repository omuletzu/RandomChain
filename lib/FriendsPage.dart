import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/FriendElement.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

class FriendsPage extends StatefulWidget{

  final Key key;
  final String userId;
  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final bool isThisRequests;

  FriendsPage({
    required this.key,
    required this.userId,
    required this.changePageHeader,
    required this.isThisRequests
  }) : super(key: key);

  @override
  _FriendsPage createState() => _FriendsPage();
}

class _FriendsPage extends State<FriendsPage>{

  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final TextEditingController _textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  bool hasCheckedForExistingFriends = false;
  bool searchingMode = false;
  bool scrollListenerAdded = false;

  int index = 0;

  List<FriendElement> allFriendsList = [];
  List<FriendElement> tempListToDisplay = [];
  Future<List<FriendElement>>? listToDisplay;

  int numberOfResults = 0;
  String userNickname = '';

  QuerySnapshot? queryFriends;
  QuerySnapshot? filteredFriends;
  String filterNickname = '';

  @override
  void initState() {
    super.initState();
    retreiveFriendsFirebase();
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

            Visibility(
              visible: !widget.isThisRequests,
              child: Padding(
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
                        });
                        listToDisplay = Future.value(allFriendsList);
                      }
                      else{
                        setState(() {
                          searchingMode = true;
                          hasCheckedForExistingFriends = false;
                        });
                        filterNickname = value.toLowerCase().trim();
                        tempListToDisplay = [];
                        filteredFriends = null;
                        listToDisplay = _searchByNickname();
                      }
                    },
                  )
                ),
              )
            ),

            Align(
              alignment: Alignment.center,
                child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Text(widget.isThisRequests ? 'Check your friend requests' : 'Here you can see your friends ($numberOfResults)', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
              )
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

                    if(hasCheckedForExistingFriends){
                      return Center(
                        child: Text(widget.isThisRequests ? 'You have no friend requests' : 'You have no friends :(\nTry adding someone', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.grey, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
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

  Future<List<FriendElement>> retreiveFriendsFirebase() async {
  
    if(userNickname == ''){
      Map<String, dynamic> userData = (await _firebase.collection('UserDetails').doc(widget.userId).get()).data() as Map<String, dynamic>;
      userNickname = userData['nickname'];
      if(mounted){
        setState(() {
          numberOfResults = userData['friendsCount'];
        });
      }
    }
    
    String sourceForQuery = 'Friends';

    if(widget.isThisRequests){
      sourceForQuery = 'FriendRequests';
    }

    if(queryFriends == null){
      queryFriends = await _firebase.collection('UserDetails')
        .doc(widget.userId)
        .collection(sourceForQuery)
        .limit(13)
        .get(const GetOptions(source: Source.server));
    }
    else{
      queryFriends = await _firebase.collection('UserDetails')
        .doc(widget.userId)
        .collection(sourceForQuery)
        .limit(13)
        .startAfterDocument(queryFriends!.docs.last)
        .get(const GetOptions(source: Source.server));
    }

    if(queryFriends!.docs.isNotEmpty){
      _addFriendsElements(queryFriends!);
    }

    if(mounted && !hasCheckedForExistingFriends){
      setState(() {
        hasCheckedForExistingFriends = true;
      });
    }

    if(!scrollListenerAdded){
      scrollController.addListener(() {
        _scrollListenerFunction();
      });

      scrollListenerAdded = true;
    }

    return allFriendsList;
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
      _addFriendsElements(filteredFriends!);
    }

    if(mounted && !hasCheckedForExistingFriends){
      setState(() {
        hasCheckedForExistingFriends = true;
      });
    }

    return tempListToDisplay;
  }

  void _scrollListenerFunction(){

    if(scrollController.position.pixels >= scrollController.position.maxScrollExtent){
      if(searchingMode){
        _searchByNickname();
      }
      else{
        retreiveFriendsFirebase();
      }
    }
  }

  void increaseFriendCount(bool addOrSub) async {
    if(addOrSub){
      numberOfResults++;
    }
    else{
      numberOfResults--;
    }
  }

  void _addFriendsElements(QuerySnapshot queryUsers) async {

    List<FriendElement> tempList = [];

    for(DocumentSnapshot friend in queryUsers.docs){

      Map<String, dynamic> friendData = (await _firebase.collection('UserDetails').doc(friend.id).get()).data() as Map<String, dynamic>;

      tempList.add(
        FriendElement(
          userId: widget.userId, 
          friendId: friend.id,
          firebase: _firebase, 
          storage: _storage,
          friendData: friendData,
          changePageHeader: widget.changePageHeader,
          friendOrStranger : true,
          isThisRequests : widget.isThisRequests,
          userNickname : userNickname,
          increaseFriendCount: increaseFriendCount
        )
      );
    }

    if(mounted){
      setState(() {
          searchingMode 
            ? tempListToDisplay.addAll(tempList)
            : allFriendsList.addAll(tempList);
        }
      );
    }
  }

  @override
  void dispose(){

    _firebase.collection('UserDetails').doc(widget.userId).update({
      'friendsCount' : numberOfResults
    });

    _textController.dispose();
    
    if(scrollListenerAdded){
      scrollController.removeListener(_scrollListenerFunction);
      scrollListenerAdded = false;
    }
    scrollController.dispose();
    super.dispose();
  }
}