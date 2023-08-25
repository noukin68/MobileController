import 'package:flutter/material.dart';
import 'package:flutter_application_1/timer_screen.dart';
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as IO;

class LoginPage extends StatefulWidget {
  final IO.Socket socket;

  LoginPage(this.socket);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  TextEditingController uidController = TextEditingController();
  String uid = "";
  String message = "";

  Future<void> authenticate() async {
    final response = await http.post(
      Uri.parse('http://localhost:3000/uidLogin'),
      headers: {'Content-Type': 'application/json'},
      body: '{"uid": "$uid"}',
    );

    if (response.statusCode == 200) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (context) => TimerScreen(socket: widget.socket)),
      );
    } else if (response.statusCode == 401) {
      setState(() {
        message = 'Неверный UID';
      });
    } else {
      setState(() {
        message = 'Ошибка сервера';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFEFCEAD),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(height: 50),
            Center(
              child: Image.asset(
                'assets/logoController.png',
                height: 150,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Введите ваш UID',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color.fromRGBO(119, 75, 36, 1),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 20),
            TextField(
              cursorColor: Color.fromRGBO(119, 75, 36, 1),
              controller: uidController,
              decoration: InputDecoration(
                labelText: 'Введите UID',
                labelStyle: TextStyle(
                  color: Color.fromRGBO(119, 75, 36, 1),
                ),
                border: OutlineInputBorder(),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(119, 75, 36, 1),
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(
                    color: Color.fromRGBO(119, 75, 36, 1),
                  ),
                ),
              ),
              onChanged: (value) {
                setState(() {
                  uid = value;
                });
              },
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: authenticate,
              child: Text('Войти'),
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Color.fromRGBO(119, 75, 36, 1),
                foregroundColor: Color.fromRGBO(239, 206, 173, 1),
              ),
            ),
            SizedBox(height: 20),
            Text(
              message,
              style: TextStyle(
                color: Color.fromRGBO(119, 75, 36, 1),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            Expanded(
              // Use Expanded to fill the remaining space
              child: Padding(
                padding: EdgeInsets.only(bottom: 20),
                child: Column(
                  mainAxisAlignment:
                      MainAxisAlignment.end, // Align to the bottom
                  children: [
                    Text(
                      'при поддержке',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Color.fromRGBO(119, 75, 36, 1),
                        fontFamily: 'Calibri',
                      ),
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset(
                          'assets/pixel.png',
                          width: 90,
                          height: 90,
                        ),
                        SizedBox(
                          width: 10,
                        ),
                        Image.asset(
                          'assets/faz.png',
                          width: 90,
                          height: 90,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
