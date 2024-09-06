import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class ProfilePage extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final String userId;
  final bool isThisUser;
  final Key? key;

  ProfilePage({
    required this.changePageHeader,
    required this.userId,
    required this.isThisUser,
    required this.key
  }) : super(key: key);

  @override
  _ProfilePage createState() => _ProfilePage();
}

class _ProfilePage extends State<ProfilePage> with SingleTickerProviderStateMixin{

  final FirebaseFirestore _firebase = FirebaseFirestore.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  late AnimationController animationControllerSlide;

  late Map<String, dynamic> profileInfo;

  late String profileImageUrl;
  bool dataRetreived = false;
  bool hasProfileImage = false;
  bool userDataRetreived = false;
  int totalPoints = 0;
  int totalContributions = 0;
  int totalFriends = 0;
  DateFormat format = DateFormat("dd-MM-yyyy");
  late DateTime accountSince;

  @override
  void initState() {
    super.initState();

    animationControllerSlide = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    retreiveDataFirebase();
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: widget.isThisUser,
      onPopInvoked: (didPop) {
        if(!didPop){

        }
      },
      child: Scaffold(
        body: Column(
          children: [
            Wrap(
              children: [
                Align(
                  alignment: Alignment.center,
                  child: Padding(
                    padding: EdgeInsets.all(width * 0.0),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Image.asset('assets/image/roundchain.png', width: width * 0.5, height: width * 0.5, color: Colors.grey),

                        ClipOval(
                          child: dataRetreived 
                            ? (hasProfileImage
                              ? Image.network(
                                  profileImageUrl,
                                  width: width * 0.2,
                                  height: width * 0.2,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if(loadingProgress == null){
                                      return child;
                                    }
                                    else{
                                      return const Center(
                                        child: CircularProgressIndicator(),
                                      );
                                    }
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    print('$error\n$stackTrace');
                                    return Icon(Icons.error, size: width * 0.025);
                                  },
                              )
                              : Image.asset('assets/image/profile.png', width: width * 0.25, height: width * 0.25)
                            )
                            : const CircularProgressIndicator()
                        )
                      ],
                    ),
                  )      
                ),

                Align(
                  alignment: Alignment.center,
                  child: Text(userDataRetreived ? profileInfo['nickname'] : '', style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                )
              ],
            ),

            Padding(
              padding: EdgeInsets.only(top: width * 0.025, bottom: width * 0.01),
              child: Divider(
                height: 2.0,
                color: Colors.grey[200],
              ),
            ),

            Expanded(
              child: Padding(
                padding: EdgeInsets.all(width * 0.025),
                  child: GridView.count(
                    shrinkWrap: true,
                    crossAxisCount: 2,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Image.asset('assets/image/logo.png', width: width * 0.12, height: width * 0.12),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text(userDataRetreived ? totalPoints.toString() : '-', style: GoogleFonts.nunito(fontSize: width * 0.04, color: const Color.fromARGB(255, 102, 0, 255), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text('Total points', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ],
                      ),

                      InkWell(
                        onTap: () {
                          if(userDataRetreived){
                            Map<String, dynamic> profileInfoWithUserId = profileInfo;
                            profileInfoWithUserId['userId'] = widget.userId;
                            widget.changePageHeader('Profile (chains)', profileInfoWithUserId);
                          }
                        },
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Image.asset('assets/image/infinite.png', width: width * 0.12, height: width * 0.12),
                            ),
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Text(userDataRetreived ? totalContributions.toString() : '-', style: GoogleFonts.nunito(fontSize: width * 0.04, color: const Color.fromARGB(255, 102, 0, 255), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                            Padding(
                              padding: EdgeInsets.all(width * 0.01),
                              child: Text('All chains', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                            ),
                          ],
                        )
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Image.asset('assets/image/friends.png', width: width * 0.12, height: width * 0.12),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text(userDataRetreived ? totalFriends.toString() : '-', style: GoogleFonts.nunito(fontSize: width * 0.04, color: const Color.fromARGB(255, 102, 0, 255), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text('Friends', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ],
                      ),

                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Image.asset('assets/image/time.png', width: width * 0.12, height: width * 0.12),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text(userDataRetreived ? format.format(accountSince) : '-', style: GoogleFonts.nunito(fontSize: width * 0.04, color: const Color.fromARGB(255, 102, 0, 255), fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                          Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: Text('User since', style: GoogleFonts.nunito(fontSize: width * 0.04, color: Colors.black87, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ],
                )
              ),
            )
          ],
        ),
      )
    );
  }

  Future<void> retreiveDataFirebase() async {
    try{

      profileInfo = (await _firebase.collection('UserDetails').doc(widget.userId).get()).data() as Map<String, dynamic>;

      int numberOfFriends = (await _firebase.collection('UserDetails').doc(widget.userId).collection('Friends').get()).docs.length;
      Timestamp accountSinceTimestamp = (await _firebase.collection('UserDetails').doc(widget.userId).get()).get('accountSince');

      accountSince = accountSinceTimestamp.toDate();

      setState(() {
        userDataRetreived = true;
        totalPoints = profileInfo['totalPoints'];
        totalContributions = profileInfo['totalContributions'];
        totalFriends = numberOfFriends;
      });

      if(profileInfo['avatarPath'] != '-'){
        Reference avatarPath = _storage.ref().child(profileInfo['avatarPath'] + '.png');
        profileImageUrl = await avatarPath.getDownloadURL();
        setState(() {
          hasProfileImage = true;
        });
      }
      else{
        
      }
    }
    catch(e){
      print(e);
    }

    if(mounted){
      setState(() {
        dataRetreived = true;
      });
    }
  }

  @override
  void dispose() {
    animationControllerSlide.dispose();
    super.dispose();
  }
}