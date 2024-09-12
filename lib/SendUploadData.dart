import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:doom_chain/GlobalValues.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SendUploadData{
  static Future<bool> uploadData({
    required FirebaseFirestore firebase,
    required FirebaseStorage storage,
    required Map<String, dynamic>? addData,
    required Map<String, dynamic>? chainMap,
    required List<List<String>>? contributorsList,
    required bool disableFirstPhraseForChallange,
    required String theme,
    required String title,
    required bool photoSkipped,
    required String chainIdentifier,
    required String categoryName,
    required bool chainSkipped,
    required String? photoPath,
    required bool mounted,
    required BuildContext? context,
    required void Function(String, Map<String, dynamic>?)? changePageHeader,
    required newChainOrExtend}
  ) async {

    String userId = addData!['userId'];
    DocumentSnapshot userDetails = await firebase.collection('UserDetails').doc(userId).get();
    String userNationality = userDetails.get('countryName');

    QuerySnapshot? allUsersFromSameCountry;
    QuerySnapshot? allUserNotFromSameCountry;
    QuerySnapshot? allFriends;

    //UPLOADING

    if(newChainOrExtend){
  
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      userId = sharedPreferences.getString('userId') ?? 'root';

      if(userDetails.exists){  
        
        allUsersFromSameCountry = await firebase.collection('UserDetails').where('countryName', isEqualTo: userNationality).get();   
        allUserNotFromSameCountry = await firebase.collection('UserDetails').where('countryName', isNotEqualTo: userNationality).get();

        if(addData['randomOrFriends']){

          if(addData['chainPieces'] > allUserNotFromSameCountry.docs.length && addData['chainPieces'] > allUsersFromSameCountry.docs.length){
            Fluttertoast.showToast(msg: 'Not enough users', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
            return Future.value(false);
          }
        }
        else{
          allFriends = await firebase.collection('UserDetails').doc(newChainOrExtend ? addData['userId'] : chainMap!['userIdForFriendList']).collection('Friends').get();

          if(addData['chainPieces'] > allFriends.docs.length){
            Fluttertoast.showToast(msg: 'Not enough users', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
            return Future.value(false);
          }
        }

        String? tagJSON;

        if(addData!['tagList'] != null){
          tagJSON = jsonEncode(addData['tagList']);
        }

        updateGlobalTagList(addData['tagList'], chainIdentifier, categoryName, userNationality, firebase);

        contributorsList = List.empty(growable: true);
        String firstPhrase = ' ';

        String finalPhotoStorageId = '-';

        if(!photoSkipped){
          finalPhotoStorageId = 'uploads/$chainIdentifier/${addData['chainPieces']}_$userId';
        }

        if(disableFirstPhraseForChallange){
          firstPhrase = theme;
        }
        else{
          firstPhrase = title;
        }

        contributorsList.add([userId, firstPhrase, finalPhotoStorageId]);

        chainMap = {
          'random' : addData['randomOrFriends'],
          'allPieces' : addData['allOrPartChain'],
          'remainingOfContrib' : addData['chainPieces'],
          'totalContrib' : addData['chainPieces'],
          'tagList' : tagJSON,
          'theme' : addData['theme'],
          'title' : addData['title'].isEmpty ? categoryName : addData['title'] ,
          'contributions' : jsonEncode(contributorsList),
          'userIdForFriendList' : userId,
          'totalPoints' : 0,
          'totalContributions' : 0,
          'likes' : 0,
          'chainNationality' : userNationality};

        firebase.collection('PendingChains').doc(categoryName).collection(userNationality).doc(chainIdentifier).set(chainMap);
      }
      else{
        return Future.value(false);
      }

      if(!photoSkipped){
        Reference reference = storage.ref().child('uploads/$chainIdentifier/${addData['chainPieces']}_$userId');
        reference.putFile(File(photoPath!));
      }
    }

    //SENDING TO

    Random random = Random();
    String userIdToSendChain = '';

    if(addData['randomOrFriends']){
      userIdToSendChain = await selectRandomUserToSend(firebase, random, allUsersFromSameCountry, allUserNotFromSameCountry, userNationality, userIdToSendChain, userId);
    }
    else{
      userIdToSendChain = await selectFriendUserToSend(firebase, random, allFriends, chainMap!, newChainOrExtend, userIdToSendChain, userId);
    }

    print(userIdToSendChain);

    if(userIdToSendChain.isNotEmpty){
      sendToSpecificUser(userIdToSendChain, chainIdentifier, firebase, categoryName, chainMap!['chainNationality'], chainMap['userIdForFriendList'], chainMap['contributions'], newChainOrExtend ? addData['randomOrFriends'] : chainMap['random']);
    }

    if(!chainSkipped){

      int categoryTypeContributions = userDetails.get('${categoryName}Contributions');
      int totalContributions = userDetails.get('totalContributions');

      firebase.collection('UserDetails').doc(userId).update({
        '${categoryName}Contributions' : categoryTypeContributions + 1,
        'totalContributions' : totalContributions + 1
      });
    }

    if(context != null && mounted && context.mounted){
      Navigator.of(context).popUntil((route) => route.isFirst);
    }

    if(changePageHeader != null){
      changePageHeader('Unchained (refresh)', null);
    }

    if(newChainOrExtend){
      Fluttertoast.showToast(msg: 'Chain sent', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
    }

    return Future.value(true);
  }

  static Future<String> selectRandomUserToSend(FirebaseFirestore firebase, Random random, QuerySnapshot? allUsersFromSameCountry, QuerySnapshot? allUserNotFromSameCountry, String userNationality, String userIdToSendChain, String userId) async {
    List<int> userRandomIndexes = [-1, -1, -1];

    allUsersFromSameCountry ??= await firebase.collection('UserDetails').where('countryName', isEqualTo: userNationality).get();
    allUserNotFromSameCountry ??= await firebase.collection('UserDetails').where('countryName', isNotEqualTo: userNationality).get();

    if(allUsersFromSameCountry.docs.isNotEmpty){
      userRandomIndexes[0] = random.nextInt(allUsersFromSameCountry.docs.length);

      if(allUsersFromSameCountry.docs.length > 1){
        userRandomIndexes[1] = random.nextInt(allUsersFromSameCountry.docs.length);

        while(userRandomIndexes[0] == userRandomIndexes[1]){
          userRandomIndexes[1] = random.nextInt(allUsersFromSameCountry.docs.length);
        }
      }
    }

    if(allUserNotFromSameCountry.docs.isNotEmpty){
      userRandomIndexes[2] = random.nextInt(allUserNotFromSameCountry.docs.length);
    }

    int randomFinalUserIndex = random.nextInt(userRandomIndexes.length);

    if(allUserNotFromSameCountry.docs.isEmpty){
      randomFinalUserIndex %= 2;
    }

    if(userRandomIndexes[0] != -1 && userRandomIndexes[1] == -1 && userRandomIndexes[2] == -1){
      return allUsersFromSameCountry.docs[userRandomIndexes[0]].id;
    }

    if(randomFinalUserIndex == 0 && userRandomIndexes[0] != -1){ 
      if(allUsersFromSameCountry.docs[userRandomIndexes[0]].id == userId){
        if(userRandomIndexes[1] != -1){
          return allUsersFromSameCountry.docs[userRandomIndexes[1]].id;
        }
        else{
          if(userRandomIndexes[2] != -1){
            return allUserNotFromSameCountry.docs[userRandomIndexes[2]].id;
          }
        }
      }
      else{
        return allUsersFromSameCountry.docs[userRandomIndexes[0]].id;
      }
    }
    
    if(randomFinalUserIndex == 1 && userRandomIndexes[1] != -1){
      if(allUsersFromSameCountry.docs[userRandomIndexes[1]].id == userId){
        if(userRandomIndexes[0] != -1){
          return allUsersFromSameCountry.docs[userRandomIndexes[0]].id;
        }
        else{
          if(userRandomIndexes[2] != -1){
            return allUserNotFromSameCountry.docs[userRandomIndexes[2]].id;
          }
        }
      }
      else{
        return allUsersFromSameCountry.docs[userRandomIndexes[1]].id;
      }
    }

    if(randomFinalUserIndex == 2 && userRandomIndexes[2] != -1){
      return allUserNotFromSameCountry.docs[userRandomIndexes[2]].id;
    }

    Fluttertoast.showToast(msg: 'Please retry', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
    return Future.value('');
  }

  static Future<String> selectFriendUserToSend(FirebaseFirestore firebase, Random random, QuerySnapshot? allFriends, Map<String, dynamic> chainMap, bool newChainOrExtend, String userIdToSendChain, String userId) async {
    allFriends ??= await firebase.collection('UserDetails').doc(newChainOrExtend ? userId : chainMap!['userIdForFriendList']).collection('Friends').get();

      if(allFriends.docs.isEmpty){
        return Future.value('');
      }

      int randomFriendIndex = random.nextInt(allFriends.docs.length);

      while((chainMap['contributions'] as String).contains(allFriends.docs[randomFriendIndex].id)){
        randomFriendIndex = random.nextInt(allFriends.docs.length);
      }

      return allFriends.docs[randomFriendIndex].id;
  }
  
  static void sendToSpecificUser(String userId, String chainId, FirebaseFirestore firebase, String categoryName, String chainNationality, String chainAuthor, String contributors, bool randomOrFriend) async {
    firebase.collection('UserDetails').doc(userId).collection('PendingPersonalChains').doc(chainId).set({
      'categoryName' : categoryName,
      'chainNationality' : chainNationality,
      'receivedTime' : Timestamp.now(),
      'userIdForFriendList' : chainAuthor,
      'contributions' : contributors,
      'randomOrFriend' : randomOrFriend
    });
  }

  static void updateGlobalTagList(List<String> tagList, String chainId, String categoryName, String chainNationality, FirebaseFirestore firebase) async {

    if(tagList.isEmpty){
      return;
    }

    await firebase.collection('ChainTags').doc(tagList.first.toLowerCase().trim()).set({
      chainId : jsonEncode([categoryName, chainNationality])
    });

    for(int i = 1; i < tagList.length; i++){
      firebase.collection('ChainTags').doc(tagList[i].toLowerCase().trim()).update({
        chainId : jsonEncode([categoryName, chainNationality])
      });
    }
  }
}