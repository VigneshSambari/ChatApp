// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, curly_braces_in_flow_control_structures, non_constant_identifier_names, unnecessary_string_interpolations

import 'package:chatapp/backend/firebase/online_database_management/clouddatamanager.dart';
import 'package:chatapp/backend/sqlitemanagement/localdatabasemanagement.dart';
import 'package:chatapp/frontend/authui/commonui.dart';
import 'package:chatapp/frontend/mainscreens/homepage.dart';
import 'package:chatapp/frontend/mainscreens/mainscreen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:loading_overlay/loading_overlay.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PrimaryUserData extends StatefulWidget {
  @override
  State<PrimaryUserData> createState() => _PrimaryUserDataState();
}

class _PrimaryUserDataState extends State<PrimaryUserData> {
  bool isLoading = false;
  final CloudStorage CloudStorageDataManager = CloudStorage();
  final LocalDatabase localDatabase = LocalDatabase();
  final GlobalKey<FormState> userDataFormKey = GlobalKey<FormState>();
  final TextEditingController userNameController = TextEditingController();
  final TextEditingController userAboutController = TextEditingController();
  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(34, 48, 60, 1),
        body: LoadingOverlay(
          isLoading: isLoading,
          child: Container(
            width: MediaQuery.of(context).size.width,
            height: MediaQuery.of(context).size.height,
            child: Form(
              key: userDataFormKey,
              child: ListView(
                shrinkWrap: true,
                children: [
                  upperHead(),
                  Commonformfield(
                    hinttext: "User Name",
                    validator: (value) {
                      final RegExp exp = RegExp(r'[a-zA-Z0-9]');
                      if (value!.length < 6)
                        return "Length should be atleast 6 characters";
                      else if (value.contains(' '))
                        return "User Name should not have spaces";
                      else if (value.contains('@'))
                        return "User Name should not contain @";
                      else if (value.contains('__'))
                        return "Use _ instead donot use __";
                      else if (!exp.hasMatch(value))
                        return "Sorry emojis are not supported";
                      return null;
                    },
                    controller: userNameController,
                  ),
                  SizedBox(
                    height: 20,
                  ),
                  Commonformfield(
                      hinttext: "About",
                      validator: (value) {
                        if (value!.length > 100)
                          return "Length should be max 100 characters";
                        return null;
                      },
                      controller: userAboutController),
                  SizedBox(
                    height: 30,
                  ),
                  saveInfo(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget upperHead() {
    return Padding(
      padding: EdgeInsets.only(top: 30, bottom: 50),
      child: Center(
        child: Text(
          "Set up your profile",
          style: TextStyle(
            fontSize: 23,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget saveInfo() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: InkWell(
        onTap: () async {
          if (userDataFormKey.currentState!.validate()) {
            print("Validated");
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            //print(FirebaseAuth.instance.currentUser)
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
            final bool userNamePresent =
                await CloudStorageDataManager.chechUserExists(
                    userName: userNameController.text);

            if (userNamePresent) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("UserName already exists!"),
                ),
              );
            } else {
              String msg = "";
              final bool userResponse =
                  await CloudStorageDataManager.registerUser(
                      userName: userNameController.text,
                      userAbout: userAboutController.text,
                      userEmail:
                          FirebaseAuth.instance.currentUser!.email.toString());

              if (userResponse) {
                msg = "User data updated";

                //SQlite CRUB
                Map<String, dynamic> tempdata = <String, dynamic>{};
                tempdata = await CloudStorageDataManager.getToken(
                    mail: FirebaseAuth.instance.currentUser!.email.toString());

                await localDatabase.createTableToStoreImportantData();
                await localDatabase.insertOrUpdateDataForThisAccount(
                    userName: userNameController.text,
                    userMail:
                        FirebaseAuth.instance.currentUser!.email.toString(),
                    userToken: tempdata["token"],
                    userAbout: userAboutController.text,
                    userAccCreationTime: tempdata["currTime"],
                    userAccCreationDate: tempdata["currDate"]);

                await localDatabase.createTableForUserActivity(
                    tableName: userNameController.text);

                Navigator.pushAndRemoveUntil(
                    context,
                    MaterialPageRoute(builder: (builder) => MainScreen()),
                    (route) => false);
                print("UserData updated");
              } else {
                msg = "User data updation failed";
                print("UserData update failed");
              }
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));
            }

            if (mounted) {
              setState(() {
                isLoading = false;
              });
            }
          }
        },
        child: Container(
          width: MediaQuery.of(context).size.width - 200,
          height: 45,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            color: Colors.blueGrey,
          ),
          child: Center(
            child: Text(
              "Save",
              style: TextStyle(
                color: Colors.white,
                fontSize: 22.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
