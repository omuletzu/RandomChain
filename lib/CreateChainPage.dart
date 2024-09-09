import 'package:doom_chain/GlobalColors.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:fluttertoast/fluttertoast.dart';

class CreateChain extends StatefulWidget{

  final void Function(String, Map<String, dynamic>?) changePageHeader;
  Map<String, dynamic>? addData;

  CreateChain({required this.changePageHeader, required this.addData});

  @override
  _CreateChain createState() => _CreateChain();
}

class _CreateChain extends State<CreateChain>{

  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _themeController = TextEditingController();

  late final String themeDescription;

  bool randomOrFriends = true;
  bool allOrPartChain = true;

  bool isStoryCategory = false;

  @override 
  void initState(){
    super.initState();

    if(widget.addData != null){
      if(widget.addData!['categoryType'] == 0){
        isStoryCategory = true;
        themeDescription = 'Choose the central idea to guide the direction of your story';
      }
      else{
        if(widget.addData!['categoryType'] == 1){
          themeDescription = 'Be as random as you want to';
        }
        else{
          themeDescription = 'Set a wild theme to spark quirky, daring, or downright hilarious challenges';
        }
      }
    }

    if(isStoryCategory && widget.addData != null && widget.addData!['title'] != null){
      _titleController.text = widget.addData!['title'];
    }

    if(widget.addData != null && widget.addData!['theme'] != null){
      _themeController.text = widget.addData!['theme']!;
    }
  }

  @override
  Widget build(BuildContext context){
   
    final double width = MediaQuery.of(context).size.width;

    return PopScope(
      canPop: false,
      onPopInvoked: (didPop){
        if(!didPop){
          widget.changePageHeader('New chain (category)', null);
        }
      },
      child: Scaffold(
        backgroundColor: globalBackground,
        resizeToAvoidBottomInset: false,
        body: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            const Spacer(),

            Visibility(
              visible: isStoryCategory,
              child: Padding(
                padding: EdgeInsets.all(width * 0.075),
                child: AnimatedContainer(
                  duration: const Duration(seconds: 2),
                  child: Column(
                    children: [
                      TextField(
                        controller: _titleController,
                        maxLines: 1,
                        maxLength: 12,
                        decoration: InputDecoration(
                          focusedBorder: UnderlineInputBorder(
                            borderRadius: const BorderRadius.all(Radius.circular(10)),
                            borderSide: BorderSide(color: widget.addData!['baseCategoryColor'], width: 2.0)
                          ),
                          label: Center(
                            child: Text(
                              'Chain title',
                              style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                            ),
                          )
                        ),
                        textAlign: TextAlign.center,
                        style: GoogleFonts.nunito(fontSize: width * 0.05, color: widget.addData!['baseCategoryColor'], fontWeight: FontWeight.bold),
                      ),
                      
                      Padding(
                        padding: EdgeInsets.only(top: width * 0.05),
                        child: Text('Give this story a captivating name that hints to what\'s to come', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                      )
                    ],
                  )
                )
              )
            ),
            
            Padding(
              padding: EdgeInsets.all(width * 0.075),
              child: AnimatedContainer(
                duration: const Duration(seconds: 2),
                child: Column(
                  children: [
                    TextField(
                      controller: _themeController,
                      maxLines: null,
                      maxLength: 120,
                      decoration: InputDecoration(
                        focusedBorder: UnderlineInputBorder(
                          borderRadius: const BorderRadius.all(Radius.circular(10)),
                          borderSide: BorderSide(color: widget.addData!['baseCategoryColor'], width: 2.0)
                        ),
                        label: Center(
                          child: Text(
                            (widget.addData!['categoryType'] == 0) ? 'Theme of the chain'
                              : (widget.addData!['categoryType'] == 1) ? 'Random thought' : 'Chainllange theme',
                            style: GoogleFonts.nunito(fontSize: width * 0.05, color: Colors.grey, fontWeight: FontWeight.bold),
                          ),
                        )
                      ),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.nunito(fontSize: width * 0.05, color: widget.addData!['baseCategoryColor'], fontWeight: FontWeight.bold),
                    ),
                    
                    Padding(
                      padding: EdgeInsets.only(top: width * 0.05),
                      child: Text(themeDescription, style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                    )
                  ],
                )
              )
            ),

            const Spacer(flex: 2),

            Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(width * 0.075),
                  child: Material(
                    color: widget.addData!['baseCategoryColor'],
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.all(Radius.circular(15))
                    ),
                    child: InkWell(
                      borderRadius: const BorderRadius.all(Radius.circular(15)),
                      onTap: () async {

                        if(_titleController.text.trim().isEmpty && isStoryCategory){
                          Fluttertoast.showToast(msg: 'Empty title', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
                          return;
                        }

                        if(_themeController.text.trim().isEmpty){
                          Fluttertoast.showToast(msg: 'Empty theme', toastLength: Toast.LENGTH_LONG, backgroundColor: globalBlue);
                          return;
                        }

                        if(widget.addData != null){
                          widget.addData!['title'] = _titleController.text.trim();
                          widget.addData!['theme'] = _themeController.text.trim();
                        }else{
                          widget.addData = {
                            'title' : _titleController.text.trim(),
                            'theme' : _themeController.text.trim()
                          };
                        }

                        if(widget.addData!['categoryType'] == 0){
                          widget.changePageHeader('New chain (details)', widget.addData);
                        }
                        
                        if(widget.addData!['categoryType'] == 1){
                          widget.changePageHeader('New chain (random details)', widget.addData);
                        }

                        if(widget.addData!['categoryType'] == 2){
                          widget.changePageHeader('New chain (challange details)', widget.addData);
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

                Text('> to adding details <', style: GoogleFonts.nunito(fontSize: width * 0.04, color: globalTextBackground, fontWeight: FontWeight.bold))
              ],
            )
          ],
        ),
      )
    );
  }

  @override
  void dispose(){
    super.dispose();
    _titleController.dispose();
    _themeController.dispose();
  }
}