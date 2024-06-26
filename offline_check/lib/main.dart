import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_keyboard_visibility/flutter_keyboard_visibility.dart';
import 'package:offline_check/connectivity_service.dart';
import 'package:provider/provider.dart';
import 'keyboard/custom_keyboard.dart';
import 'keyboard/custom_overlay.dart';
import 'logger/logger.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => ConnectivityService(),
      child: const MyApp(),
      )
    );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  TextEditingController searchController = TextEditingController();
  TextEditingController textController = TextEditingController();
  KeyboardVisibilityController keyboardVisibilityController = KeyboardVisibilityController();
  String sizeText = "";

  @override
  void initState() {
    super.initState();
    var connectivityService = Provider.of<ConnectivityService>(context, listen: false);
    connectivityService.addListener(() {
      if (connectivityService.isConnected) {
        log('Internet Connected');
      } else {
        log('Internet Disconnected');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
      },
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Name',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
              SizedBox(
                height: 45,
                width: MediaQuery.of(context).size.width / 2,
                child: TextField(
                  autofocus: true,
                  controller: textController,
                  onTap: () {
                    showSizeKeyboard(context, textController, () {});
                    Logger.info('i');
                  },
                  onChanged: (value) {
                    setState(() {
                      textController.text = value;
                    });
                  },
                ),
              )
            ],
          ),
        ),
      ),
    );
  }

  void showSizeKeyboard(BuildContext context, TextEditingController controller, VoidCallback setStateCallback) {
    CustomOverlay.start(
      context,
      Overlay(
        initialEntries: [
          OverlayEntry(
            builder: (BuildContext context) {
              return Positioned(
                bottom: 0,
                left: 0,
                child: Material(
                  child: Container(
                    height: 350,
                    width: MediaQuery.of(context).size.width,
                    color: Colors.blue,
                    child: StatefulBuilder(
                      builder: (context, setState) {
                        return CustomKeyboard(
                          backgroundColor: Colors.blue,
                          bottomPaddingColor: Colors.blue,
                          bottomPaddingHeight: 5,
                          keyboardHeight: 345,
                          keyboardWidth: MediaQuery.of(context).size.width,
                          onChange: (value) {
                            controller.text = value;
                            setStateCallback();
                            sizeText = value.toLowerCase();
                          }, 
                          onTapColor: Colors.lightBlue,
                          textColor: Colors.black,
                          keybordButtonColor: Colors.blue,
                          elevation: MaterialStateProperty.all(5),
                          controller: searchController,
                        );
                      },
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
  );
}
}
