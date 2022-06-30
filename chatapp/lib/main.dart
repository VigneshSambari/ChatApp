// ignore_for_file: prefer_const_constructors

import 'package:chatapp/backend/firebase/online_database_management/clouddatamanager.dart';
import 'package:chatapp/frontend/authui/signin.dart';
import 'package:chatapp/frontend/authui/signup.dart';
import 'package:chatapp/frontend/mainscreens/homepage.dart';
import 'package:chatapp/frontend/mainscreens/mainscreen.dart';
import 'package:chatapp/frontend/newuserentry/newuserentry.dart';
import 'package:chatapp/global_uses/foregroundnotificationmanagement.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  await notificationInitialize();

  //  Background Message
  FirebaseMessaging.onBackgroundMessage(backgroundMsgAction);

  //  Foreground Message
  FirebaseMessaging.onMessage.listen((messageEvent) {
    print(
        "Message Data is: ${messageEvent.notification!.title}     ${messageEvent.notification!.body}");

    _receiveAndShowNotificationInitialization(
        title: messageEvent.notification!.title.toString(),
        body: messageEvent.notification!.body.toString());
  });

  runApp(MaterialApp(
    title: "Chat App",
    debugShowCheckedModeBanner: false,
    home: await navigator(),
  ));
}

Future<Widget> navigator() async {
  if (FirebaseAuth.instance.currentUser == null) {
    return SignIn();
  } else {
    final CloudStorage cloudStorage = CloudStorage();
    final bool userData = await cloudStorage.userRecordExist(
        email: FirebaseAuth.instance.currentUser!.email.toString());
    if (userData) return MainScreen();
  }
  return PrimaryUserData();
}

Future<void> notificationInitialize() async {
  await FirebaseMessaging.instance.subscribeToTopic("Chat_Application");

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );
}

void _receiveAndShowNotificationInitialization(
    {required String title, required String body}) async {
  final ForegroundNotificationManagement _fgNotifyManagement =
      ForegroundNotificationManagement();

  print("Notification Activated");

  await _fgNotifyManagement.showNotification(title: title, body: body);
}

Future<void> backgroundMsgAction(RemoteMessage message) async {
  await Firebase.initializeApp();

  _receiveAndShowNotificationInitialization(
      title: message.notification!.title.toString(),
      body: message.notification!.body.toString());
}
