import 'dart:async';
// import 'dart:io';

import 'package:flutter/material.dart';
import 'package:game/home_screen.dart';
import 'package:game/models/touch_points.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'final_leaderboard.dart';
import 'models/mu_custom_painter.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';
import 'waiting_lobby_screen.dart';
import 'sidebar/player_score_drawer.dart';

class PaintScreen extends StatefulWidget {
  final Map<String, String> data;
  final String screenFrom;
  PaintScreen({required this.data, required this.screenFrom});

  @override
  State<PaintScreen> createState() => _PaintScreenState();
}

class _PaintScreenState extends State<PaintScreen> {
  @override
  late IO.Socket _socket;
  Map dataOfoom = {};
  List<TouchPoints> points = [];
  StrokeCap strokeType = StrokeCap.round;
  Color selectedColor = Colors.black;
  double opacity = 1;
  double strokeWidth = 2;
  List<Widget> textBlankWidget = [];
  ScrollController _scrollController = ScrollController();
  List<Map> message = [];
  TextEditingController controller = TextEditingController();
  int guessedUserCtr = 0;
  int _start = 60;
  late Timer _timer;
  var scaffoldKey = GlobalKey<ScaffoldState>();
  List<Map> scoreBoard = [];
  bool isTextInputReadOnly = false;
  int maxPoints = 0;
  String winner = '';
  bool isShowFinalLeaderBoard = false;
  void initState() {
    // TODO: implement initState
    super.initState();
    connect();
  }

  void startTimer() {
    const oneSec = const Duration(seconds: 1);
    _timer = Timer.periodic(oneSec, (Timer time) {
      if (_start == 0) {
        _socket.emit('change-turn', dataOfoom['name']);
        setState(() {
          _timer.cancel();
        });
      } else {
        setState(() {
          _start--;
        });
      }
    });
  }

  void renderTextBlank(String text) {
    textBlankWidget.clear();
    for (int i = 0; i < text.length; i++) {
      textBlankWidget.add(Text(
        '_',
        style: TextStyle(fontSize: 30),
      ));
    }
  }

// socket io client connection
  void connect() {
    try {
      _socket = IO.io('http://192.168.1.56:3000', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false
      });
      _socket.connect();
    } catch (e) {
      print(e);
    }

    if (widget.screenFrom == 'createRoom') {
      _socket.emit('create-game', widget.data);
    } else {
      _socket.emit('join-game', widget.data);
    }

    // listen to socket
    _socket.onConnect((data) {
      print('Connected!');
      _socket.on('updateRoom', (roomData) {
        setState(() {
          renderTextBlank(roomData['word']);
          dataOfoom = roomData;
        });

        if (roomData['isJoin'] != true) {
          startTimer();
        }
        scoreBoard.clear();
        for (int i = 0; i < roomData['players'].length; i++) {
          setState(() {
            scoreBoard.add({
              'username': roomData['players'][i]['nickname'],
              'points': roomData['players'][i]['points'].toString(),
            });
          });
        }
      });

      _socket.on('points', (point) {
        if (point['details'] != null) {
          setState(() {
            points.add(TouchPoints(
                points: Offset((point['details']['dx']).toDouble(),
                    (point['details']['dy']).toDouble()),
                paint: Paint()
                  ..strokeCap = strokeType
                  ..isAntiAlias = true
                  ..color = selectedColor.withOpacity(opacity)
                  ..strokeWidth = strokeWidth));
          });
        }
      });

      _socket.on('color-change', (colorString) {
        int value = int.parse(colorString, radix: 16);
        Color otherColor = new Color(value);
        setState(() {
          selectedColor = otherColor;
        });
      });
      _socket.on('stroke-width', (value) {
        setState(() {
          strokeWidth = value;
        });
      });

      _socket.on('clear-screen', (data) {
        setState(() {
          points.clear();
        });
      });

      _socket.on('msg', (msgData) {
        print(msgData);
        setState(() {
          message.add(msgData);
          guessedUserCtr = msgData['gussedUserCtr'];
          print(guessedUserCtr);
        });
        if (guessedUserCtr == dataOfoom['players'].length - 1) {
          _socket.emit('change-turn', dataOfoom['name']);
        }
        _scrollController.animateTo(
            _scrollController.position.maxScrollExtent + 40,
            duration: Duration(milliseconds: 200),
            curve: Curves.easeInOut);
      });

      _socket.on('change-turn', (data) {
        String oldWord = dataOfoom['word'];
        showDialog(
            context: context,
            builder: (context) {
              Future.delayed(Duration(seconds: 3), () {
                setState(() {
                  dataOfoom = data;
                  renderTextBlank(dataOfoom['word']);
                  isTextInputReadOnly = false;
                  guessedUserCtr = 0;
                  points.clear();
                  _start = 60;
                });
                Navigator.of(context).pop();
                _timer.cancel();
                startTimer();
              });
              return AlertDialog(
                title: Center(
                  child: Text('Word was $oldWord'),
                ),
              );
            });
      });
      _socket.on('close-input', (_) {
        _socket.emit('updateScore', widget.data['name']);
        setState(() {
          isTextInputReadOnly = true;
        });
      });

      _socket.on('updateScore', (roomData) {
        scoreBoard.clear();
        for (int i = 0; i < roomData['players'].length; i++) {
          setState(() {
            scoreBoard.add({
              'username': roomData['players'][i]['nickname'],
              'points': roomData['players'][i]['points'].toString()
            });
          });
        }
      });

      _socket.on('show-leaderboard', (roompPlayers) {
        scoreBoard.clear();
        for (int i = 0; i < roompPlayers.length; i++) {
          setState(() {
            scoreBoard.add({
              'username': roompPlayers[i]['nickname'],
              'points': roompPlayers[i]['points'].toString()
            });
          });
          if (maxPoints < int.parse(scoreBoard[i]['points'])) {
            winner = scoreBoard[i]['username'];
            maxPoints = int.parse(scoreBoard[i]['points']);
          }
        }
        setState(() {
          _timer.cancel();
          isShowFinalLeaderBoard = true;
        });
      });

      _socket.on('user-disconnected', (roomData) {
        scoreBoard.clear();
        for (int i = 0; i < roomData['players'].length; i++) {
          setState(() {
            scoreBoard.add({
              'username': roomData['players'][i]['nickname'],
              'points': roomData['players'][i]['points'].toString()
            });
          });
        }
      });

      _socket.on(
          'notCorrectGame',
          (data) => Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (context) => HomeScreen()),
              (route) => false));
    });
  }

  @override
  void dispose() {
    // TODO: implement dispos
    _socket.dispose();
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    final height = MediaQuery.of(context).size.height;

    void selectColor() {
      showDialog(
          context: context,
          builder: (context) => AlertDialog(
                title: Text('Choose Color'),
                content: SingleChildScrollView(
                  child: BlockPicker(
                      pickerColor: selectedColor,
                      onColorChanged: (color) {
                        String colorString = color.toString();
                        String valueString =
                            colorString.split('(0x')[1].split(')')[0];

                        Map map = {
                          'color': valueString,
                          'roomName': dataOfoom['name']
                        };
                        _socket.emit('color-change', map);
                      }),
                ),
                actions: [
                  TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text('Close'))
                ],
              ));
    }

    return Scaffold(
      key: scaffoldKey,
      drawer: PlayerScore(scoreBoard),
      backgroundColor: Colors.white,
      body: dataOfoom != null
          ? dataOfoom['isJoin'] != true
              ? !isShowFinalLeaderBoard
                  ? Stack(children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Container(
                            width: width,
                            height: height * 0.55,
                            child: GestureDetector(
                              onPanUpdate: (details) {
                                _socket.emit('paint', {
                                  'details': {
                                    'dx': details.localPosition.dx,
                                    'dy': details.localPosition.dy
                                  },
                                  'roomName': widget.data['name']
                                });
                              },
                              onPanStart: (details) {
                                _socket.emit('paint', {
                                  'details': {
                                    'dx': details.localPosition.dx,
                                    'dy': details.localPosition.dy
                                  },
                                  'roomName': widget.data['name']
                                });
                              },
                              onPanEnd: (details) {
                                _socket.emit('paint', {
                                  'details': null,
                                  'roomName': widget.data['name'],
                                });
                              },
                              child: SizedBox.expand(
                                child: ClipRRect(
                                  borderRadius:
                                      BorderRadius.all(Radius.circular(20)),
                                  child: RepaintBoundary(
                                    child: CustomPaint(
                                      size: Size.infinite,
                                      painter:
                                          MycustomPainter(pointsList: points),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: Icon(Icons.color_lens),
                                color: selectedColor,
                                onPressed: () {
                                  selectColor();
                                },
                              ),
                              Expanded(
                                child: Slider(
                                  min: 1.0,
                                  max: 10,
                                  label: "Strokewidht $strokeWidth",
                                  activeColor: selectedColor,
                                  value: strokeWidth,
                                  onChanged: (double value) {
                                    Map map = {
                                      'strokeWidth': value,
                                      'roomName': dataOfoom['name']
                                    };
                                    _socket.emit('stroke-width', map);
                                  },
                                ),
                              ),
                              IconButton(
                                icon: Icon(Icons.layers_clear),
                                color: selectedColor,
                                onPressed: () {
                                  _socket.emit(
                                      'clear-screen', dataOfoom['name']);
                                },
                              ),
                            ],
                          ),
                          widget.data != null &&
                                  dataOfoom != null &&
                                  dataOfoom['turn'] != null &&
                                  dataOfoom['word'] != null &&
                                  dataOfoom['turn']['nickname'] !=
                                      widget.data['nickname']
                              ? Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: textBlankWidget,
                                )
                              : Center(
                                  child: Text(
                                    dataOfoom['word'] != null
                                        ? dataOfoom['word']
                                        : '',
                                    style: TextStyle(fontSize: 30),
                                  ),
                                ),

                          // displaying messages
                          Container(
                            height: MediaQuery.of(context).size.height * 0.3,
                            child: ListView.builder(
                                controller: _scrollController,
                                shrinkWrap: true,
                                itemCount: message.length,
                                itemBuilder: (context, index) {
                                  var msg = message[index].values;

                                  if (msg != null) {
                                    return ListTile(
                                      title: Text(
                                        msg.elementAt(0) ?? '',
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontSize: 19,
                                            fontWeight: FontWeight.bold),
                                      ),
                                      subtitle: Text(
                                        msg.elementAt(1) ?? '',
                                        style: TextStyle(
                                            color: Colors.grey, fontSize: 16),
                                      ),
                                    );
                                  }
                                }),
                          ),
                        ],
                      ),
                      widget.data != null &&
                              dataOfoom != null &&
                              dataOfoom['turn'] != null &&
                              dataOfoom['word'] != null &&
                              dataOfoom['turn']['nickname'] !=
                                  widget.data['nickname']
                          ? Align(
                              alignment: Alignment.bottomCenter,
                              child: Container(
                                margin: EdgeInsets.symmetric(horizontal: 20),
                                child: TextField(
                                  readOnly: isTextInputReadOnly,
                                  controller: controller,
                                  onSubmitted: (value) {
                                    if (value.trim().isNotEmpty) {
                                      Map map = {
                                        'username': widget.data['nickname'],
                                        'msg': value.trim(),
                                        'word': dataOfoom['word'],
                                        'roomName': dataOfoom['name'],
                                        'gussedUserCtr': guessedUserCtr,
                                        'totalTime': 60,
                                        'timeTaken': 60 - _start,
                                      };

                                      _socket.emit('msg', map);
                                      controller.clear();
                                    }
                                  },
                                  autocorrect: false,
                                  decoration: InputDecoration(
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(8),
                                        borderSide: BorderSide(
                                            color: Colors.transparent),
                                      ),
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 14, horizontal: 16),
                                      filled: true,
                                      fillColor: Color.fromARGB(15, 21, 21, 30),
                                      hintText: 'Your Guess',
                                      hintStyle: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w400,
                                      )),
                                  textInputAction: TextInputAction.done,
                                ),
                              ),
                            )
                          : Container(),
                      SafeArea(
                          child: IconButton(
                        icon: Icon(
                          Icons.menu,
                          color: Colors.black,
                        ),
                        onPressed: () => scaffoldKey.currentState!.openDrawer(),
                      ))
                    ])
                  : FinalLeaderBoard(
                      scoreBoard: scoreBoard,
                      winner: winner,
                    )
              : WaitingLobbyScreen(
                  lobbyName: dataOfoom['name'],
                  noOfPlayers: dataOfoom['players'].length,
                  occupancy: dataOfoom['occupancy'],
                  players: dataOfoom['players'],
                )
          : Center(
              child: CircularProgressIndicator(),
            ),
      floatingActionButton: Container(
        margin: EdgeInsets.only(bottom: 30),
        child: FloatingActionButton(
          onPressed: () {},
          elevation: 7,
          backgroundColor: Colors.white,
          child: Text(
            '$_start',
            style: TextStyle(color: Colors.black, fontSize: 22),
          ),
        ),
      ),
    );
  }
}
