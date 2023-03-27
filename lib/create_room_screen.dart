import 'package:flutter/material.dart';
import 'package:game/paint_screen.dart';
import 'package:game/widget/custom_text_field.dart';

class CreateRoomScreen extends StatefulWidget {
  const CreateRoomScreen({super.key});

  @override
  State<CreateRoomScreen> createState() => _CreateRoomScreenState();
}

class _CreateRoomScreenState extends State<CreateRoomScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _roomController = TextEditingController();
  late String? _maxRoundVlaue;
  late String? _roomSizedValue;
  void createRoom() {
    if (_nameController.text.isNotEmpty &&
        _roomController.text.isNotEmpty &&
        _maxRoundVlaue != null &&
        _roomSizedValue != null) {
      Map<String, String> data = {
        'nickname': _nameController.text,
        'name': _roomController.text,
        'occupancy': _roomSizedValue!,
        'maxround': _maxRoundVlaue!,
      };
      Navigator.of(context).push(MaterialPageRoute(
          builder: (context) =>
              PaintScreen(data: data, screenFrom: 'createRoom')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Create Room",
            style: TextStyle(
              color: Colors.black,
              fontSize: 30,
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.08,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: CustomTextField(_nameController, "Enter your Name"),
          ),
          SizedBox(
            height: 20,
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 20),
            child: CustomTextField(_roomController, "Enter Room Name"),
          ),
          SizedBox(
            height: 20,
          ),
          DropdownButton<String>(
            focusColor: Color.fromARGB(15, 21, 21, 30),
            items: <String>["2", "5", "10", "15"]
                .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(color: Colors.black),
                          ),
                        ))
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _maxRoundVlaue = value;
              });
            },
            hint: Text(
              "Select Max Round",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            height: 20,
          ),
          DropdownButton<String>(
            focusColor: Color.fromARGB(15, 21, 21, 30),
            items: <String>["2", "3", "4", "5", "6", "7", "8"]
                .map<DropdownMenuItem<String>>(
                    (String value) => DropdownMenuItem(
                          value: value,
                          child: Text(
                            value,
                            style: TextStyle(color: Colors.black),
                          ),
                        ))
                .toList(),
            onChanged: (String? value) {
              setState(() {
                _roomSizedValue = value;
              });
            },
            hint: Text(
              "Select Room Size",
              style: TextStyle(
                  color: Colors.black,
                  fontSize: 14,
                  fontWeight: FontWeight.w500),
            ),
          ),
          SizedBox(
            height: 40,
          ),
          ElevatedButton(
              onPressed: () {
                createRoom();
                // print('hey');
              },
              style: ButtonStyle(
                backgroundColor: MaterialStateProperty.all(Colors.blue),
                // textStyle: MaterialStateProperty.all(
                //   TextStyle(color: Colors.white),
                // ),
                minimumSize: MaterialStateProperty.all(
                    Size(MediaQuery.of(context).size.width / 2.5, 50)),
              ),
              child: Text(
                "Create",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ))
        ],
      ),
    );
  }
}
