import 'package:app/Constants/theme.dart';
import 'package:app/Constants/variables.dart';
import 'package:app/Screens/client_dashboard.dart';
import 'package:app/Screens/server_dashboard.dart';
import 'package:app/Screens/settings.dart';
import 'package:app/Widgets/alert.dart';
import 'package:flutter/material.dart';
import 'dart:io' show Platform;

double desktopNavWidth = 200;
double desktopNavClsoed = 50;

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _currentIndex = 0;

  bool _navHidden = Platform.isIOS || Platform.isAndroid ? true : false;
  double _navWidth =
      Platform.isIOS || Platform.isAndroid ? 30 : desktopNavWidth;
  @override
  Widget build(BuildContext context) {
    final screens = [
      const ServerDashboard(),
      const ClientDashboard(),
      Settings(nav: this)
    ];

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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Visibility(
                      visible: !_navHidden,
                      child: Column(
                        children: [
                          Visibility(
                            visible: Platform.isIOS || Platform.isAndroid
                                ? true
                                : false,
                            child: SizedBox(
                              height: height / 10,
                            ),
                          ),
                          // Company Logo
                          Visibility(
                            visible: Platform.isIOS || Platform.isAndroid
                                ? false
                                : true,
                            child: Container(
                              color: Colors.transparent,
                              width: double.infinity,
                              height: 150,
                              margin: const EdgeInsets.only(bottom: 20),
                              child: const Image(
                                  image: AssetImage('assets/images/logo.png')),
                            ),
                          ),
                          // Nav Buttons
                          creatNavButton(context, "Server", 0, Icons.router,
                              () {
                            clientConnected
                                ? createDialogPopUp(context, "Lynk",
                                    "Unable to access server dashboard while client is connected")
                                : screenChange(0);
                          }),
                          creatNavButton(context, "Client", 1,
                              Icons.connect_without_contact, () {
                            serverRunning
                                ? createDialogPopUp(context, "Lynk",
                                    "Unable to access client dashboard while server is running")
                                : screenChange(1);
                          }),
                          creatNavButton(context, "Settings", 2, Icons.settings,
                              () {
                            screenChange(2);
                          }),
                        ],
                      ),
                    ),
                    // Nav Close Button
                    SizedBox(
                      height: _navHidden
                          ? height / 2
                          : Platform.isIOS || Platform.isAndroid
                              ? height / 1.65
                              : height - 370,
                    ),
                    IconButton(
                      onPressed: () {
                        setState(() {
                          _navHidden = !_navHidden;

                          if (_navHidden) {
                            _navWidth = Platform.isIOS || Platform.isAndroid
                                ? 30
                                : desktopNavClsoed;
                          } else {
                            _navWidth = Platform.isIOS || Platform.isAndroid
                                ? 50
                                : desktopNavWidth = 200;
                          }
                        });
                      },
                      icon: Icon(
                        !_navHidden
                            ? Icons.keyboard_double_arrow_left
                            : Icons.keyboard_double_arrow_right,
                        color: lightGreen,
                        size: Platform.isIOS || Platform.isAndroid
                            ? _navHidden
                                ? 15
                                : 30
                            : 30,
                      ),
                    ),
                  ],
                );
              }),
            ),
            const VerticalDivider(thickness: 1, width: 1),
            Expanded(
              child: screens[_currentIndex],
            )
          ],
        ),
      ),
    );
  }

  TextButton creatNavButton(BuildContext context, String label, int navIndex,
      IconData icon, Function callback) {
    return TextButton.icon(
      iconAlignment: IconAlignment.start,
      icon: Icon(
        icon,
        size: 30,
        color: _currentIndex == navIndex ? darkGreen : lightGreen,
      ),
      onPressed: () {
        setState(() {
          callback();
        });
      },
      label: (showNavLabels &&
              (Platform.isWindows || Platform.isLinux || Platform.isMacOS))
          ? Text(label)
          : const Text(
              "",
            ),
      style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          foregroundColor: _currentIndex == navIndex
              ? WidgetStatePropertyAll(darkGreen)
              : WidgetStatePropertyAll(lightGreen),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
    );
  }

  void screenChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
