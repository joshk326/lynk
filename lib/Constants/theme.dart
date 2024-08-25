import 'package:flutter/material.dart';

Color flatBlack = const Color.fromARGB(255, 34, 34, 34);
Color lightGrey = const Color.fromARGB(255, 158, 158, 158);
Color white = const Color.fromARGB(255, 255, 255, 255);
Color background = const Color(0xfffffeea);
Color lightGreen = const Color.fromARGB(255, 188, 202, 173);
Color darkGreen = const Color(0xff729B79);

ThemeData appTheme = ThemeData(
    primaryColor: darkGreen,
    scaffoldBackgroundColor: background,
    highlightColor: lightGreen,
    elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
            backgroundColor: WidgetStatePropertyAll(darkGreen),
            foregroundColor: WidgetStatePropertyAll(background),
            shape: const WidgetStatePropertyAll(RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(5)))))),
    scrollbarTheme:
        ScrollbarThemeData(thumbColor: WidgetStatePropertyAll(darkGreen)),
    appBarTheme: AppBarTheme(
      backgroundColor: background,
    ),
    hoverColor: lightGrey,
    floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkGreen, foregroundColor: white));
