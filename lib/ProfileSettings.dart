import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ProfileSettings extends StatefulWidget{

  final void Function(String, Map<String, dynamic>) changePageHeader;
  final String userId;

  ProfileSettings({
    required this.changePageHeader,
    required this.userId
  });

  @override
  _ProfileSettings createState() => _ProfileSettings();
}

class _ProfileSettings extends State<ProfileSettings> {
  @override
  Widget build(BuildContext context){
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if(!didPop){
          widget.changePageHeader('Profile', {
            'userId' : widget.userId
          });
        }
      },
      child: Scaffold(

      )
    );
  }
}