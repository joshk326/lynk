import 'package:app/Constants/theme.dart';
import 'package:app/Screens/home.dart';
import 'package:app/Screens/settings.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _currentIndex = 0;
  final screens = [const Home(), const Settings()];
  bool _navHidden = Platform.isIOS || Platform.isAndroid ? true : false;
  double _navWidth = Platform.isIOS || Platform.isAndroid ? 50 : 200;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Row(
          children: <Widget>[
            Container(
              height: double.infinity,
              width: _navWidth,
              color: flatBlack,
              child: LayoutBuilder(
                  builder: (BuildContext context, BoxConstraints constraints) {
                double height = constraints.maxHeight;
                return Column(
                  children: [
                    Visibility(
                      visible: !_navHidden,
                      child: Column(
                        children: [
                          // Company Logo
                          Container(
                            color: background,
                            width: double.infinity,
                            height: 150,
                            margin: const EdgeInsets.only(bottom: 20),
                            child: Image.network(
                              "https://koontzcoding.com/images/logo",
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              screenChange(0);
                            },
                            iconSize: 30,
                            icon: Icon(
                              Icons.home,
                              color:
                                  _currentIndex == 0 ? darkGreen : lightGreen,
                            ),
                          ),
                          IconButton(
                            onPressed: () {
                              screenChange(1);
                            },
                            iconSize: 30,
                            icon: Icon(
                              Icons.settings,
                              color:
                                  _currentIndex == 1 ? darkGreen : lightGreen,
                            ),
                          )
                        ],
                      ),
                    ),
                    SizedBox(
                      height: _navHidden ? height / 2 : height - 320,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _navHidden = !_navHidden;

                          if (_navHidden) {
                            _navWidth = 50;
                          } else {
                            _navWidth = 200;
                          }
                        });
                      },
                      icon: Icon(
                        !_navHidden
                            ? Icons.keyboard_double_arrow_left
                            : Icons.keyboard_double_arrow_right,
                        color: lightGreen,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: Center(
                child: screens[_currentIndex],
              ),
            )
          ],
        ),
      ),
    );
  }

  void screenChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
