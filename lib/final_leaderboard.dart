import 'package:flutter/material.dart';

class FinalLeaderBoard extends StatelessWidget {
  final List<Map> scoreBoard;
  final String winner;
  // const FinalLeaderBoard({Key? key}) : super(key: key);
  FinalLeaderBoard({required this.scoreBoard, required this.winner});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: EdgeInsets.all(8),
        height: double.maxFinite,
        child: Column(
          children: [
            ListView.builder(
                itemCount: scoreBoard.length,
                itemBuilder: (context, index) {
                  var data = scoreBoard[index].values;
                  return ListTile(
                    title: Text(
                      data.elementAt(0),
                      style: TextStyle(color: Colors.black, fontSize: 23),
                    ),
                    trailing: Text(
                      data.elementAt(1),
                      style: TextStyle(
                          color: Colors.grey,
                          fontSize: 20,
                          fontWeight: FontWeight.bold),
                    ),
                  );
                }),
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: Text(
                '$winner was won the game!',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
              ),
            )
          ],
        ),
      ),
    );
  }
}
