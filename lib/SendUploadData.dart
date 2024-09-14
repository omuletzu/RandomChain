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

    Random random = Random();

    String userId = addData!['userId'];
    DocumentSnapshot userDetailsDocument = await firebase.collection('UserDetails').doc(userId).get();
    Map<String, dynamic> userDetails = userDetailsDocument.data() as Map<String, dynamic>;
    String userNationality = userDetails['countryName'];

    QuerySnapshot? allUsersFromSameCountry;
    QuerySnapshot? allUserNotFromSameCountry;
    QuerySnapshot? allFriends;

    //UPLOADING

    if(newChainOrExtend){
  
      SharedPreferences sharedPreferences = await SharedPreferences.getInstance();
      userId = sharedPreferences.getString('userId') ?? 'root';

      if(userDetailsDocument.exists){  

        if(addData['randomOrFriends']){

          allUsersFromSameCountry = await firebase.collection('UserDetails').where('countryName', isEqualTo: userNationality).get();   
          allUserNotFromSameCountry = await firebase.collection('UserDetails').where('countryName', isNotEqualTo: userNationality).get();

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

        if(addData['tagList'] != null){
          tagJSON = jsonEncode(addData['tagList']);
        }

        updateGlobalTagList(addData['tagList'], random, chainIdentifier, categoryName, userNationality, firebase);

        String finalPhotoStorageId = '-';
        if(!photoSkipped){
          finalPhotoStorageId = 'uploads/$chainIdentifier/${addData['chainPieces']}_$userId';
        }

        String firstPhrase = ' ';

        if(disableFirstPhraseForChallange){
          firstPhrase = theme;
        }
        else{
          firstPhrase = title;
        }
        
        contributorsList = List.empty(growable: true);
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
          'chainNationality' : userNationality,
          'categoryName' : categoryName,
          'userIdForFriendList' : userId,
          'totalPoints' : 0,
          'totalContributions' : 0,
          'likes' : 0,
          'randomIndex' : random.nextDouble(),
          'receivedTime' : Timestamp.now()
        };
      }
      else{
        return Future.value(false);
      }
    }

    //SENDING

    String userIdToSendChain = '';

    if(addData['randomOrFriends']){
      userIdToSendChain = await selectRandomUserToSend(firebase, random, allUsersFromSameCountry, allUserNotFromSameCountry, chainMap!, userNationality, userId);
    }
    else{
      userIdToSendChain = await selectFriendUserToSend(firebase, random, allFriends, chainMap!, newChainOrExtend, userIdToSendChain, userId);
    }

    if(userIdToSendChain.isNotEmpty){
      sendToSpecificUser(firebase, userIdToSendChain, userId, chainIdentifier, chainMap);
    }
    else{
      return Future.value(false);
    }

    if(!photoSkipped){
      int indexOfCurrentPhoto = newChainOrExtend ? addData['chainPieces'] : chainMap['remainingOfContrib'];
      Reference reference = storage.ref().child('uploads/$chainIdentifier/${indexOfCurrentPhoto}_$userId');
      await reference.putFile(File(photoPath!));
    }

    if(!chainSkipped){

      int categoryTypeContributions = userDetails['${categoryName}Contributions'];
      int totalContributions = userDetails['totalContributions'];

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

  static Future<String> selectRandomUserToSend(FirebaseFirestore firebase, Random random, QuerySnapshot? allUsersFromSameCountry, QuerySnapshot? allUserNotFromSameCountry, Map<String, dynamic> chainMap, String userNationality, String userId) async {
    List<int> userRandomIndexes = [-1, -1, -1];

    allUsersFromSameCountry ??= await firebase.collection('UserDetails').where('countryName', isEqualTo: userNationality).get();
    allUserNotFromSameCountry ??= await firebase.collection('UserDetails').where('countryName', isNotEqualTo: userNationality).get();

    if(allUsersFromSameCountry.docs.isNotEmpty){
      userRandomIndexes[0] = random.nextInt(allUsersFromSameCountry.docs.length);

      if(allUsersFromSameCountry.docs.length > 1){

        int whileCounter = 0;

        while(whileCounter <= allUsersFromSameCountry.docs.length && (chainMap['contributions'] as String).contains(allUsersFromSameCountry.docs[userRandomIndexes[0]].id)){
          userRandomIndexes[0] = (userRandomIndexes[0] + 1) % allUsersFromSameCountry.docs.length;
        }

        if(whileCounter > allUsersFromSameCountry.docs.length){
          userRandomIndexes[0] = -1;
        }
        else{
          userRandomIndexes[1] = random.nextInt(allUsersFromSameCountry.docs.length);
          whileCounter = 0;

          while(whileCounter <= allUsersFromSameCountry.docs.length && (userRandomIndexes[0] == userRandomIndexes[1] || (chainMap['contributions'] as String).contains(allUsersFromSameCountry.docs[userRandomIndexes[1]].id))){
            userRandomIndexes[1] = (userRandomIndexes[1] + 1) % allUsersFromSameCountry.docs.length;
            whileCounter++;
          }

          if(whileCounter > allUsersFromSameCountry.docs.length){
            userRandomIndexes[1] = -1;
          }
        }
      }
    }

    if(allUserNotFromSameCountry.docs.isNotEmpty){
      userRandomIndexes[2] = random.nextInt(allUserNotFromSameCountry.docs.length);
      int whileCounter = 0;

      while(whileCounter <= allUserNotFromSameCountry.docs.length && (chainMap['contributions'] as String).contains(allUserNotFromSameCountry.docs[userRandomIndexes[2]].id)){
        userRandomIndexes[2] = (userRandomIndexes[2] + 1) % allUserNotFromSameCountry.docs.length;
        whileCounter++;
      }

      if(whileCounter > allUserNotFromSameCountry.docs.length){
        userRandomIndexes[2] = -1;
      }
    }

    if(userRandomIndexes[0] == -1 && userRandomIndexes[1] == -1 && userRandomIndexes[2] == -1){
      return Future.value('');
    }

    int randomFinalUserIndex = random.nextInt(userRandomIndexes.length);

    if(allUserNotFromSameCountry.docs.isEmpty){
      randomFinalUserIndex %= 2;
    }

    if(userRandomIndexes[0] != -1 && userRandomIndexes[1] == -1 && userRandomIndexes[2] == -1){
      return allUsersFromSameCountry.docs[userRandomIndexes[0]].id;
    }

    if(randomFinalUserIndex == 0 && userRandomIndexes[0] != -1){ 
      return allUsersFromSameCountry.docs[userRandomIndexes[0]].id;
    }
    
    if(randomFinalUserIndex == 1 && userRandomIndexes[1] != -1){
      return allUsersFromSameCountry.docs[userRandomIndexes[1]].id;
    }

    if(userRandomIndexes[2] != -1){
      return allUserNotFromSameCountry.docs[userRandomIndexes[2]].id;
    }

    Fluttertoast.showToast(msg: 'Please retry', toastLength: Toast.LENGTH_SHORT, backgroundColor: globalBlue);
    return Future.value('');
  }

  static Future<String> selectFriendUserToSend(FirebaseFirestore firebase, Random random, QuerySnapshot? allFriends, Map<String, dynamic> chainMap, bool newChainOrExtend, String userIdToSendChain, String userId) async {
    allFriends ??= await firebase.collection('UserDetails').doc(newChainOrExtend ? userId : chainMap['userIdForFriendList']).collection('Friends').get();

      if(allFriends.docs.isEmpty){
        return Future.value('');
      }

      int randomFriendIndex = random.nextInt(allFriends.docs.length);
      int whileCounter = 0;

      while(whileCounter <= allFriends.docs.length && (chainMap['contributions'] as String).contains(allFriends.docs[randomFriendIndex].id)){
        randomFriendIndex = (randomFriendIndex + 1) % allFriends.docs.length;
        whileCounter++;
      }

      if(whileCounter > allFriends.docs.length){
        return Future.value('');
      }

      return allFriends.docs[randomFriendIndex].id;
  }
  
  static void sendToSpecificUser(FirebaseFirestore firebase, String userId, String originalUser, String chainId, Map<String, dynamic> chainMap) async {
    firebase.collection('UserDetails').doc(originalUser).collection('PendingPersonalChains').doc(chainId).delete();
    firebase.collection('UserDetails').doc(userId).collection('PendingPersonalChains').doc(chainId).set(chainMap); 
  }

  static void updateGlobalTagList(List<String> tagList, Random random, String chainId, String categoryName, String chainNationality, FirebaseFirestore firebase) async {

    for(String tag in tagList){
      firebase.collection('ChainTags').doc('ChainTags').collection(tag.toLowerCase().trim()).doc(chainId).set({
        categoryName : chainNationality,
        'randomIndex' : random.nextDouble()
      });
    }
  }
}