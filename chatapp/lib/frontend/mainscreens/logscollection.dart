// ignore_for_file: prefer_const_constructors, prefer_final_fields

import 'package:flutter/material.dart';
import 'package:cupertino_icons/cupertino_icons.dart';
import 'package:loading_overlay/loading_overlay.dart';

class LogsControl extends StatefulWidget {
  @override
  State<LogsControl> createState() => _LogsControlState();
}

class _LogsControlState extends State<LogsControl> {
  bool _isLoading = false;
  final List<String> callHistory = [];
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: const Color.fromRGBO(34, 48, 60, 1),
        //floatingActionButton: _externalConnectionManagement(),
        body: LoadingOverlay(
          color: const Color.fromRGBO(0, 0, 0, 0.5),
          progressIndicator: const CircularProgressIndicator(
            backgroundColor: Colors.black87,
          ),
          isLoading: this._isLoading,
          child: Container(
            padding: EdgeInsets.all(12),
            width: double.maxFinite,
            height: double.maxFinite,
            child: ListView.builder(
                itemCount: callHistory.length,
                itemBuilder: (context, index) => connectionHistory(index)),
          ),
        ),
      ),
    );
  }

  Widget connectionHistory(int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 10),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        CircleAvatar(
          backgroundColor: const Color.fromRGBO(34, 48, 60, 1),
          backgroundImage: ExactAssetImage('assets/images/google.png'),
          radius: MediaQuery.of(context).orientation == Orientation.portrait
              ? MediaQuery.of(context).size.height * (1.2 / 8) / 2.5
              : MediaQuery.of(context).size.height * (2.5 / 8) / 2.5,
        ),
        Text(
          callHistory[index],
          style: TextStyle(color: Colors.white, fontSize: 28),
        ),
        IconButton(
            color: Colors.green,
            onPressed: () {},
            icon: Icon(
              Icons.call,
              size: 30,
            ))
      ]),
    );
  }
}
