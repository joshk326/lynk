import 'dart:io';

import 'package:app/Constants/theme.dart';
import 'package:app/Constants/variables.dart';
import 'package:app/Screens/client_dashboard.dart';
import 'package:app/Screens/server_dashboard.dart';
import 'package:app/Screens/settings.dart';
import 'package:app/Widgets/alert.dart';
import 'package:flutter/material.dart';

class Navigation extends StatefulWidget {
  const Navigation({super.key});

  @override
  State<Navigation> createState() => _NavigationState();
}

class _NavigationState extends State<Navigation> {
  int _currentIndex = 0;

  bool _navHidden = false;
  double _navWidth = 200;
  @override
  Widget build(BuildContext context) {
    final screens = [const ServerDashboard(), const ClientDashboard(), Settings(nav: this)];

    return Scaffold(
      extendBody: true,
      body: (Platform.isMacOS || Platform.isWindows || Platform.isLinux)
          ? SafeArea(
              child: desktopNavigation(screens),
            )
          : IndexedStack(
              index: _currentIndex,
              children: screens,
            ),
      bottomNavigationBar:
          (Platform.isMacOS || Platform.isWindows || Platform.isLinux) ? const SizedBox.shrink() : mobileNavigation(),
    );
  }

  Widget desktopNavigation(List<StatefulWidget> screens) {
    return Row(
      children: <Widget>[
        Container(
          height: double.infinity,
          width: _navWidth,
          color: flatBlack,
          child: LayoutBuilder(builder: (BuildContext context, BoxConstraints constraints) {
            return Column(
              mainAxisSize: MainAxisSize.max,
              children: [
                Visibility(
                  visible: !_navHidden,
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    children: [
                      // Company Logo
                      Container(
                        color: Colors.transparent,
                        width: double.infinity,
                        height: 150,
                        margin: const EdgeInsets.only(bottom: 20),
                        child: const Image(image: AssetImage('assets/images/logo.png')),
                      ),
                      // Nav Buttons
                      Column(
                        children: [
                          creatNavButton(context, "Server", 0, Icons.router, () {
                            clientConnected
                                ? createDialogPopUp(
                                    context, "Lynk", "Unable to access server dashboard while client is connected")
                                : screenChange(0);
                          }),
                          creatNavButton(context, "Client", 1, Icons.connect_without_contact, () {
                            serverRunning
                                ? createDialogPopUp(
                                    context, "Lynk", "Unable to access client dashboard while server is running")
                                : screenChange(1);
                          }),
                          creatNavButton(context, "Settings", 2, Icons.settings, () {
                            screenChange(2);
                          }),
                        ],
                      )
                    ],
                  ),
                ),
                // Nav Close Button
                SizedBox(width: 10, height: _navHidden ? (MediaQuery.sizeOf(context).height / 2) - 30 : 0),
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
                    !_navHidden ? Icons.keyboard_double_arrow_left : Icons.keyboard_double_arrow_right,
                    color: lightGreen,
                    size: 30,
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
    );
  }

  Widget mobileNavigation() {
    return SizedBox(
      height: 85,
      child: BottomAppBar(
        color: flatBlack,
        child: BottomNavigationBar(
          type: BottomNavigationBarType.fixed,
          enableFeedback: false,
          currentIndex: _currentIndex,
          showSelectedLabels: showNavLabels,
          showUnselectedLabels: true,
          onTap: (index) {
            if (clientConnected && (index == 0)) {
              createDialogPopUp(context, "Lynk", "Unable to access server dashboard while client is connected");
              return;
            } else if (serverRunning && (index == 1)) {
              createDialogPopUp(context, "Lynk", "Unable to access client dashboard while server is running");
              return;
            }
            screenChange(index);
          },
          items: [
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.router,
              ),
              label: showNavLabels ? 'Server' : '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.connect_without_contact,
              ),
              label: showNavLabels ? 'Client' : '',
            ),
            BottomNavigationBarItem(
              icon: const Icon(
                Icons.settings,
              ),
              label: showNavLabels ? 'Settings' : '',
            ),
          ],
        ),
      ),
    );
  }

  TextButton creatNavButton(BuildContext context, String label, int navIndex, IconData icon, Function callback) {
    return TextButton.icon(
      iconAlignment: IconAlignment.start,
      icon: Icon(
        icon,
        size: 40,
        color: _currentIndex == navIndex ? darkGreen : lightGreen,
      ),
      onPressed: () {
        setState(() {
          callback();
        });
      },
      label: showNavLabels
          ? Text(label)
          : const Text(
              "",
            ),
      style: ButtonStyle(
          padding: const WidgetStatePropertyAll(EdgeInsets.zero),
          foregroundColor:
              _currentIndex == navIndex ? WidgetStatePropertyAll(darkGreen) : WidgetStatePropertyAll(lightGreen),
          overlayColor: const WidgetStatePropertyAll(Colors.transparent)),
    );
  }

  void screenChange(int index) {
    setState(() {
      _currentIndex = index;
    });
  }
}
