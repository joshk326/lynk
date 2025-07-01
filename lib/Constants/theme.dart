import 'package:flutter/material.dart';

Color flatBlack = const Color.fromARGB(255, 34, 34, 34);
Color lightGrey = const Color.fromARGB(255, 158, 158, 158);
Color white = const Color.fromARGB(255, 255, 255, 255);
Color background = const Color(0xfffffeea);
Color lightGreen = const Color.fromARGB(255, 188, 202, 173);
Color darkGreen = const Color(0xff729B79);
Color flatRed = const Color.fromARGB(255, 230, 101, 92);

ThemeData appTheme = ThemeData(
    primaryColor: darkGreen,
    scaffoldBackgroundColor: background,
    highlightColor: lightGreen,
    bottomAppBarTheme: BottomAppBarTheme(
      color: background,
      shape: const CircularNotchedRectangle(),
      elevation: 0,
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      elevation: 0,
      backgroundColor: Colors.transparent,
      selectedIconTheme: IconThemeData(size: 22, color: darkGreen),
      unselectedIconTheme: IconThemeData(size: 22, color: lightGreen),
      selectedItemColor: darkGreen,
      unselectedItemColor: lightGreen,
    ),
    textSelectionTheme: TextSelectionThemeData(
        selectionColor: lightGreen, cursorColor: flatBlack),
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(darkGreen),
            foregroundColor: WidgetStatePropertyAll(background),
            shape: const WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)))))),
    inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(color: flatBlack),
        focusColor: darkGreen,
        focusedBorder:
            UnderlineInputBorder(borderSide: BorderSide(color: darkGreen))),
    scrollbarTheme: ScrollbarThemeData(
        thumbColor: WidgetStatePropertyAll(darkGreen),
        thumbVisibility: const WidgetStatePropertyAll(true)),
    appBarTheme: AppBarTheme(
      backgroundColor: lightGreen,
    ),
    textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
            foregroundColor: WidgetStatePropertyAll(flatBlack),
            overlayColor: WidgetStatePropertyAll(lightGreen))),
    dialogTheme: DialogTheme(
      backgroundColor: background,
    ),
    hoverColor: lightGrey,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkGreen, foregroundColor: white),
    switchTheme: SwitchThemeData(
        trackColor: WidgetStateProperty.resolveWith((states) {
          return states.contains(WidgetState.selected) ? lightGreen : flatRed;
        }),
        overlayColor: WidgetStatePropertyAll(darkGreen.withAlpha(10)),
        thumbColor: WidgetStatePropertyAll(background)),
    bottomSheetTheme: BottomSheetThemeData(
        modalBackgroundColor: flatBlack,
        modalBarrierColor: flatBlack,
        backgroundColor: lightGreen,
        elevation: 1,
        shadowColor: flatBlack));
