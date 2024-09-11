import 'dart:async';
import 'dart:ui';

import 'package:doom_chain/GlobalValues.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CreateChainCategory extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  final String userId;

  CreateChainCategory({required this.changePageHeader, required this.userId});

  @override
  _CreateChainCategory createState() => _CreateChainCategory();
}

class _CreateChainCategory extends State<CreateChainCategory> with TickerProviderStateMixin{

  late AnimationController _animationControllerSlideRight;
  late AnimationController _animationControllerSlideLeft;
  late AnimationController _animationControllerSlideUp;

  late AnimationController _controllerStory;
  late Animation<Color?> _animationColorStory;

  late AnimationController _controllerRandom;
  late Animation<Color?> _animationColorRandom;

  late AnimationController _controllerChainllange;
  late Animation<Color?> _animationColorChainllange;

  late Timer timer;
  bool animationFinished = false;
  late String currentTitle;
  late String currentDesc;
  late Color currentColor;
  late Color lastColor;

  bool storySelected = false;
  bool randomSelected = true;
  bool chainllangeSelected = false;
  int lastCategorySelected = 1;

  int index = 1;

  @override
  void initState(){
    super.initState();

    currentTitle = getTitle(1);
    currentDesc = getDesc(1);
    currentColor = getColor(1);
    lastColor = getColor(1);

    _controllerStory = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationColorStory = ColorTween(
      begin: globalTextBackground,
      end: globalPurple
    ).animate(_controllerStory);

    _controllerRandom = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationColorRandom = ColorTween(
      begin: globalTextBackground,
      end: globalBlue
    ).animate(_controllerRandom);

    _controllerChainllange = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _animationColorChainllange = ColorTween(
      begin: globalTextBackground,
      end: globalGreen
    ).animate(_controllerChainllange);

    _animationControllerSlideUp = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750)
    );

    _animationControllerSlideRight = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750)
    );

    _animationControllerSlideLeft = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 750)
    );

    _animationControllerSlideLeft.forward();
    _animationControllerSlideUp.forward();
    _controllerRandom.forward();

    timer = Timer(const Duration(seconds: 1, milliseconds: 250), () { 
      setState(() {
        if(mounted){
          animationFinished = true;
        }
      });
    });
  }

  @override
  Widget build(BuildContext context){

    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop){
        if(!didPop){
          widget.changePageHeader('Unchained', null);
        }
      },
      child: Scaffold(
        backgroundColor: globalBackground,
        body: Column(
          children: [

            const Spacer(),

            Padding(
              padding: EdgeInsets.all(width * 0.075),
              child: Text('Select a category from below to start a chain', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            ),

            const Spacer(),

            Padding(
              padding: EdgeInsets.all(width * 0.00),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: AnimatedBuilder(
                      animation: _animationColorStory,
                      builder:(context, child) {
                        return AnimatedContainer(
                          duration: const Duration(seconds: 1),
                          child: IconButton(
                            onPressed: () {
                              index = 0;
                              updateUI(index);
                            }, 
                            icon: Image.asset('assets/image/book.png', width: width * 0.1, height: width * 0.1, color: storySelected ? _animationColorStory.value : globalTextBackground)
                          )
                        );
                      },
                    )
                  ),

                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: AnimatedBuilder(
                      animation: _animationColorRandom, 
                      builder: (context, child){
                        return IconButton(
                          onPressed: () {
                            index = 1;
                            updateUI(index);
                          }, 
                          icon: Image.asset('assets/image/random.png', width: width * 0.1, height: width * 0.1, color: randomSelected ? _animationColorRandom.value : globalTextBackground)
                        );
                      }
                    )
                  ),
                  
                  Padding(
                    padding: EdgeInsets.all(width * 0.05),
                    child: AnimatedBuilder(
                      animation: _animationColorChainllange, 
                      builder: (context, child){
                        return IconButton(
                          onPressed: () {
                            index = 2;
                            updateUI(index);
                          }, 
                          icon: Image.asset('assets/image/challange.png', width: width * 0.1, height: width * 0.1, color: chainllangeSelected ? _animationColorChainllange.value : globalTextBackground)
                        );
                      }
                    )
                  )
                ],
              )
            ),

            const Spacer(),

            Padding(
              padding: EdgeInsets.all(width * 0.05),
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                child: Padding(
                  padding: EdgeInsets.all(width * 0.025),
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(width * 0.025),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(-2.0, 0.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideLeft, curve: Curves.easeOut)),
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.0, 0.0), end: const Offset(2.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideRight, curve: Curves.easeOut)),
                            child: Text(currentTitle, style: GoogleFonts.nunito(fontSize: width * 0.06, color: currentColor, fontWeight: FontWeight.bold), textAlign: TextAlign.center)
                          )
                        )
                      ),
              
                      Padding(
                        padding: EdgeInsets.all(width * 0.025),
                        child: SlideTransition(
                          position: Tween<Offset>(begin: const Offset(-2.0, 0.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideLeft, curve: Curves.easeOut)),
                          child: SlideTransition(
                            position: Tween<Offset>(begin: const Offset(0.0, 0.0), end: const Offset(2.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideRight, curve: Curves.easeOut)),
                            child: Text(currentDesc, style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          )
                        )
                      )
                    ],
                  )
                )
              )
            ),

            const Spacer(),

            SlideTransition(
              position: Tween<Offset>(begin: const Offset(0.0, 1.0), end: const Offset(0.0, 0.0)).animate(CurvedAnimation(parent: _animationControllerSlideUp, curve: Curves.easeOut)),
              child: FadeTransition(
                opacity: Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _animationControllerSlideUp, curve: Curves.easeOut)),
                child: Padding(
                  padding: EdgeInsets.all(width * 0.05),
                  child: Material(
                    color: globalPurple,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      onTap: () async {
                        if(index == 0){
                          widget.changePageHeader('New chain (story)', {
                            'categoryType' : 0,
                            'baseCategoryColor' : globalPurple,
                            'splashColor' : globalBlue,
                            'userId' : widget.userId
                          });
                        }

                        if(index == 1){
                          widget.changePageHeader('New chain (random)', {
                            'categoryType' : 1,
                            'baseCategoryColor' : globalBlue,
                            'splashColor' : globalPurple,
                            'userId' : widget.userId
                          });
                        }

                        if(index == 2){
                          widget.changePageHeader('New chain (challange)', {
                            'categoryType' : 2,
                            'baseCategoryColor' : globalGreen,
                            'splashColor' : globalBlue,
                            'userId' : widget.userId
                          });
                        }
                      }, 
                      splashColor: globalBlue,
                      child: Padding(
                        padding: EdgeInsets.all(width * 0.025),
                        child: Text('CONTINUE', style: GoogleFonts.nunito(fontSize: width * 0.06, color: Colors.white, fontWeight: FontWeight.bold))
                      )
                    )
                  )
                )
              )
            ),

            const Spacer()
          ],
        )
      )
    );
  }

  String getTitle(int index){

    if(index == 1){
      return 'RANDOM CHAIN';
    }

    if(index == 2){
      return 'CHAINLLANGE';
    }

    return 'STORY CHAIN';
  }

  String getDesc(int index){
    if(index == 1){
      return 'It\'s random time! Sent a random thought to someone';
    }

    if(index == 2){
      return 'Ready for a surprise? Give someone random a fun challange to spark their day';
    }

    return 'Story time! Start a collaborative story by writing the first line and setting the theme. Each participant adds their own twist, building the narrative one sentence at a time';
  }

  void updateUI(int index) async {

    if(index == lastCategorySelected){
      return;
    }

    if(lastCategorySelected == 0){
      _controllerStory.reverse();
    }

    if(lastCategorySelected == 1){
      _controllerRandom.reverse();
    }

    if(lastCategorySelected == 2){
      _controllerChainllange.reverse();
    }

    if(index == 0){
      _controllerStory.forward();
    }

    if(index == 1){
      _controllerRandom.forward();
    }

    if(index == 2){
      _controllerChainllange.forward();
    }

    await _animationControllerSlideRight.forward();

    _animationControllerSlideLeft.reset();
    _animationControllerSlideRight.reset();

    setState(() {

      updateSelectedValues(false, lastCategorySelected);
      updateSelectedValues(true, index);
      lastCategorySelected = index;

      currentTitle = getTitle(index);
      currentDesc = getDesc(index);
      currentColor = getColor(index);
    });

    _animationControllerSlideLeft.forward(); 
  }

  void updateSelectedValues(bool value, int selectedIndex){
    switch(selectedIndex){
        case 0:
          storySelected = value;
          break;
        case 1:
          randomSelected = value;
          break;
        default:
          chainllangeSelected = value;
      }
  }

  Color getColor(int index){
    if(index == 1){
      return globalBlue;
    }

    if(index == 2){
      return globalGreen;
    }

    return globalPurple;
  }

  @override
  void dispose(){
    _animationControllerSlideLeft.dispose();
    _animationControllerSlideRight.dispose();
    _animationControllerSlideUp.dispose();
    _controllerStory.dispose();
    _controllerRandom.dispose();
    _controllerChainllange.dispose();
    timer.cancel();
    super.dispose();
  }
}