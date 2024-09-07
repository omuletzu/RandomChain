import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/FriendElement.dart';
import 'package:doom_chain/GlobalColors.dart';
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
  bool hasFriends = false;
  bool lastHasFriends = false;
  bool searchingMode = false;
  bool scrollListenerAdded = false;

  int index = 0;

  List<FriendElement> allFriendsList = List.empty(growable: true);
  Future<List<FriendElement>>? listToDisplay;

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
            widget.changePageHeader('Profile', {
              'userId' : widget.userId
            });
          }
        }
      },
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        body: Column(
          children: [

            Align(
              alignment: Alignment.center,
                child: Padding(
                padding: EdgeInsets.all(width * 0.05),
                child: Text('Find out new people', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
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
                      listToDisplay = _searchByNickname(value.toLowerCase().trim());
                    }
                  },
                )
              ),
            ),

            Padding(
              padding: EdgeInsets.only(bottom: width * 0.01),
              child: Divider(
                height: 2.0,
                color: Colors.grey[200],
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

                    if(hasCheckedForExistingFriends){
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

  Future<List<FriendElement>> retreiveFriendsFirebase() async {
  
    QuerySnapshot peopleToSearchDetails = await _firebase.collection('UserDetails').get();

    for(int i = 0; i < 9 && index < peopleToSearchDetails.docs.length; i++, index++){

      DocumentSnapshot friend = peopleToSearchDetails.docs[index];

      if(friend.id == widget.userId){
        continue;
      }

      if((await _firebase.collection('UserDetails').doc(widget.userId).collection('Friends').doc(friend.id).get()).exists){
        i--;
      }
      else{
        Map<String, dynamic> friendData = (await _firebase.collection('UserDetails').doc(friend.id).get()).data() as Map<String, dynamic>;

        if(mounted){
          setState(() {
            allFriendsList.add(
                FriendElement(
                  userId: widget.userId, 
                  friendId: friend.id,
                  firebase: _firebase, 
                  storage: _storage,
                  friendData: friendData,
                  changePageHeader: widget.changePageHeader,
                  friendOrStranger : false
                )
              );
            }
          );
        }
      }

      if(mounted){
        setState(() {
          hasCheckedForExistingFriends = true;
        });
      }
    }

    if(!scrollListenerAdded){   // executed only once

      scrollController.addListener(() {
        if(scrollController.position.pixels == scrollController.position.maxScrollExtent){
          retreiveFriendsFirebase();
        }
      });

      scrollListenerAdded = true;
    }

    return allFriendsList;
  }

  Future<List<FriendElement>> _searchByNickname(String filterNickname) async {

    List<FriendElement> tempListToDisplay = List.empty(growable: true);

    QuerySnapshot filteredFriends = await _firebase.collection('UserDetails').where('nicknameLowercase', isEqualTo: filterNickname).get();

    for(DocumentSnapshot friend in filteredFriends.docs){

      Map<String, dynamic> friendData = (await _firebase.collection('UserDetails').doc(friend.id).get()).data() as Map<String, dynamic>;

      tempListToDisplay.add(
        FriendElement(
          userId: widget.userId, 
          friendId: friend.id, 
          storage: _storage, 
          firebase: _firebase, 
          friendData: friendData, 
          changePageHeader: widget.changePageHeader,
          friendOrStranger: false, 
        )
      );
    }

    if(mounted){

      setState(() {
        if(tempListToDisplay.isEmpty){
          hasFriends = false;
        }

        searchingMode = true;
      });
    }

    return tempListToDisplay;
  }

  @override
  void dispose(){
    _textController.dispose();
    scrollController.dispose();
    super.dispose();
  }
}