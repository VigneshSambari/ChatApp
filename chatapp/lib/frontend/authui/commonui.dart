// ignore_for_file: prefer_const_constructors, non_constant_identifier_names

import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

Widget Commonformfield(
    {required String hinttext,
    required String? Function(String?)? validator,
    required TextEditingController controller}) {
  return Container(
    padding: EdgeInsets.only(
      left: 20,
      right: 20,
      bottom: 20,
      top: 10,
    ),
    child: TextFormField(
      obscureText: hinttext == "Password" ? true : false,
      maxLines: null,
      validator: validator,
      controller: controller,
      style: TextStyle(
        color: Colors.white,
      ),
      decoration: InputDecoration(
        contentPadding: EdgeInsets.symmetric(horizontal: 10),
        hintText: hinttext,
        hintStyle: TextStyle(
          color: Colors.white70,
        ),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(
            color: Colors.lightBlue,
            width: 2,
          ),
        ),
      ),
    ),
  );
}
