// ignore_for_file: prefer_const_literals_to_create_immutables, prefer_const_constructors

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

class AboutSection extends StatelessWidget {
  const AboutSection({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color.fromRGBO(34, 48, 60, 1),
      body: Container(
        width: MediaQuery.of(context).size.width,
        height: MediaQuery.of(context).size.height,
        alignment: Alignment.center,
        child: ListView(
          shrinkWrap: true,
          children: [
            Padding(
              padding: EdgeInsets.only(top: 20.0, bottom: 10.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  'About this App',
                  style: TextStyle(color: Colors.white, fontSize: 20.0),
                ),
              ),
            ),
            Padding(
              padding: EdgeInsets.only(
                  bottom: 20.0, left: 20.0, right: 20.0, top: 10.0),
              child: Align(
                alignment: Alignment.center,
                child: Text(
                  "A fully functional Chat Application with Status sharing, file sharing, and location sharing with custom notifications.",
                  textAlign: TextAlign.justify,
                  style: TextStyle(color: Colors.white70, fontSize: 16.0),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
