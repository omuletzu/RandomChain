import 'package:doom_chain/GlobalValues.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateChainTagsPage extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final Map<String, dynamic>? addData;

  CreateChainTagsPage({required this.changePageHeader, required this.addData});

  @override
  _CreateChainTagsPage createState() => _CreateChainTagsPage();
}

class _CreateChainTagsPage extends State<CreateChainTagsPage> with TickerProviderStateMixin {

  final TextEditingController _chainPiecesController = TextEditingController(text: '10');
  late final AnimationController _animationControllerIcon;

  bool randomOrFriends = true;
  bool allOrPartChain = true;
  int chainPieces = 10;

  List<String> tagList = List.empty(growable: true);

  @override
  void initState(){
    super.initState();

    if(widget.addData != null && widget.addData!['randomOrFriends'] != null){
      randomOrFriends = widget.addData!['randomOrFriends'];
      allOrPartChain = widget.addData!['allOrPartChain'];
      chainPieces = widget.addData!['chainPieces'];

      _chainPiecesController.text = chainPieces.toString();
    }

    _animationControllerIcon = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1)
    );
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) {
        if(!didPop){
          if(widget.addData != null){
            widget.addData!['randomOrFriends'] = randomOrFriends;
            widget.addData!['allOrPartChain'] = allOrPartChain;
            widget.addData!['chainPieces'] = chainPieces;
            
            if(widget.addData!['categoryType'] == 0){
              widget.changePageHeader('New chain (story)', widget.addData);
            }
            
            if(widget.addData!['categoryType'] == 1){
              widget.changePageHeader('New chain (random)', widget.addData);
            }

            if(widget.addData!['categoryType'] == 2){
              widget.changePageHeader('New chain (challange)', widget.addData);
            }
          }
        }
      },
      child: Scaffold(
        backgroundColor: globalBackground,
        resizeToAvoidBottomInset: false,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Padding(
              padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.01),
                    child: Text('This will be send to either one of your random friends or a stranger', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: width * 0.05, top: width * 0.075, bottom: width * 0.075),
                        child: Material(
                          color: randomOrFriends ? widget.addData!['baseCategoryColor'].withOpacity(0.75) : Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15)),
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(15)),
                              onTap: () async {
                                setState(() {
                                  randomOrFriends = true;
                                });
                              },
                              splashColor: randomOrFriends ? globalBlue : widget.addData!['baseCategoryColor'],
                              child: Padding(
                                padding: EdgeInsets.all(width * 0.01),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(width * 0.01),
                                      child: Image.asset('assets/image/random.png', width: width * 0.12, height: width * 0.12, color: randomOrFriends ? Colors.white : globalTextBackground),
                                    ),
                                    Text('Random', style: GoogleFonts.nunito(fontSize: width * 0.04, color: randomOrFriends ? Colors.white : globalTextBackground, fontWeight: FontWeight.bold))
                                  ],
                                )
                              )
                            ),
                          )
                        )
                      ),
                      
                      Padding(
                        padding: EdgeInsets.only(left: width * 0.05, top: width * 0.075, bottom: width * 0.075),
                        child: Material(
                          color: !randomOrFriends ? widget.addData!['baseCategoryColor'].withOpacity(0.75) : Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15))
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(15)),
                              onTap: () async {
                                setState(() {
                                  randomOrFriends = false;
                                });
                              },
                              splashColor: !randomOrFriends ? globalBlue : widget.addData!['baseCategoryColor'],
                              child: Padding(
                                padding: EdgeInsets.all(width * 0.01),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(width * 0.01),
                                      child: Image.asset('assets/image/friends.png', width: width * 0.12, height: width * 0.12, color: !randomOrFriends ? Colors.white : globalTextBackground),
                                    ),
                                    Text('Friends', style: GoogleFonts.nunito(fontSize: width * 0.04, color: !randomOrFriends ? Colors.white : globalTextBackground, fontWeight: FontWeight.bold))
                                  ],
                                )
                              )
                            ),
                          )
                        ),
                      )
                    ],
                  )
                ],
              )
            ),

            Padding(
              padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.01),
                    child: Text('Contributors can see either what the person before did or the whole chain', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.only(right: width * 0.05, top: width * 0.075, bottom: width * 0.075),
                        child: Material(
                          color: allOrPartChain ? widget.addData!['baseCategoryColor'].withOpacity(0.75) : Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15))
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(15)),
                              onTap: () async {
                                setState(() {
                                  allOrPartChain = true;
                                });
                              },
                              splashColor: allOrPartChain ? globalBlue : widget.addData!['baseCategoryColor'],
                              child: Padding(
                                padding: EdgeInsets.all(width * 0.01),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(width * 0.01),
                                      child: Image.asset('assets/image/logo.png', width: width * 0.12, height: width * 0.12, color: allOrPartChain ? Colors.white : globalTextBackground),
                                    ),
                                    Text('Whole chain', style: GoogleFonts.nunito(fontSize: width * 0.04, color: allOrPartChain ? Colors.white : globalTextBackground, fontWeight: FontWeight.bold))
                                  ],
                                )
                              )
                            ),
                          )
                        ),
                      ),

                      Padding(
                        padding: EdgeInsets.only(left: width * 0.05, top: width * 0.075, bottom: width * 0.075),
                        child: Material(
                          color: !allOrPartChain ? widget.addData!['baseCategoryColor'].withOpacity(0.75) : Colors.transparent,
                          shape: const RoundedRectangleBorder(
                            borderRadius: BorderRadius.all(Radius.circular(15))
                          ),
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.01),
                            child: InkWell(
                              borderRadius: const BorderRadius.all(Radius.circular(15)),
                              onTap: () async {
                                setState(() {
                                  allOrPartChain = false;
                                });
                              },
                              splashColor: !allOrPartChain ? globalBlue : widget.addData!['baseCategoryColor'],
                              child: Padding(
                                padding: EdgeInsets.all(width * 0.01),
                                child: Row(
                                  children: [
                                    Padding(
                                      padding: EdgeInsets.all(width * 0.01),
                                      child: Image.asset('assets/image/one.png', width: width * 0.12, height: width * 0.12, color: !allOrPartChain ? Colors.white : globalTextBackground),
                                    ),
                                    Text('Last piece', style: GoogleFonts.nunito(fontSize: width * 0.04, color: !allOrPartChain ? Colors.white : globalTextBackground, fontWeight: FontWeight.bold))
                                  ],
                                )
                              )
                            ),
                          )
                        )
                      )
                    ],
                  )
                ],
              )
            ), 

            Padding(
              padding: EdgeInsets.only(left: width * 0.05, right: width * 0.05),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.01),
                    child: Text('Number of people to contribute', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                  ),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      IconButton(
                        onPressed: () {
                          if(chainPieces > 1){
                            setState(() {
                              chainPieces--;
                              _chainPiecesController.text = chainPieces.toString();
                            });
                          }
                        }, 
                        icon: Image.asset('assets/image/minus.png', width: width * 0.1, height: width * 0.1, color: globalTextBackground)
                      ),

                      Padding(
                        padding: EdgeInsets.all(width * 0.05),
                        child: AnimatedContainer(
                          duration: const Duration(seconds: 2),
                          child: Padding(
                            padding: EdgeInsets.all(width * 0.00),
                            child: SizedBox(
                              width: width * 0.1,
                              height: width * 0.05,
                              child: TextField(
                                controller: _chainPiecesController,
                                maxLines: 1,
                                textAlign: TextAlign.center,
                                style: GoogleFonts.nunito(fontSize: width * 0.05, color: globalTextBackground, fontWeight: FontWeight.bold),
                              )
                            ),
                          )
                        )
                      ),

                      IconButton(
                        onPressed: () {
                          if(chainPieces < 20){
                            setState(() {
                              chainPieces++;
                              _chainPiecesController.text = chainPieces.toString();
                            });
                          }
                        }, 
                        icon: Image.asset('assets/image/add.png', width: width * 0.1, height: width * 0.1, color: globalTextBackground)
                      )
                    ],
                  )
                ]
              )
            ),

            Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top: width * 0.075, left: width * 0.075, right: width * 0.075, bottom: width * 0.3),
                  child: Material(
                    color: widget.addData!['baseCategoryColor'],
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      onTap: () async {

                        if(widget.addData != null){
                          widget.addData!['randomOrFriends'] = randomOrFriends;
                          widget.addData!['allOrPartChain'] = allOrPartChain;
                          widget.addData!['chainPieces'] = chainPieces;

                          if(widget.addData!['categoryType'] == 0){
                          widget.changePageHeader('New chain (tags)', widget.addData);
                          }
                          
                          if(widget.addData!['categoryType'] == 1){
                            widget.changePageHeader('New chain (random tags)', widget.addData);
                          }

                          if(widget.addData!['categoryType'] == 2){
                            widget.changePageHeader('New chain (challange tags)', widget.addData);
                          }
                        }
                      }, 
                      splashColor: widget.addData!['splashColor'],
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.025),
                        child: Text('CONTINUE', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                      )
                    )
                  )
                ),

                Text('> to adding tags <', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold))
              ],
            )
          ],
        )
      )
    );
  }

  @override
  void dispose(){
    super.dispose();
    _chainPiecesController.dispose();
    _animationControllerIcon.dispose();
  }
}