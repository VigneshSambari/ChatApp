import 'dart:convert';

import 'package:chatapp/global_uses/enums.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart';

class SendNotification {
  Future<void> messageNotificationClassifier(ChatMessageTypes messageTypes,
      {String textMsg = "",
      required String connectionToken,
      required String currAccountUserName}) async {
    switch (messageTypes) {
      case ChatMessageTypes.None:
        break;
      case ChatMessageTypes.Text:
        await sendNotification(
            token: connectionToken,
            title: "$currAccountUserName Send a Message",
            body: textMsg);
        break;
      case ChatMessageTypes.Image:
        await sendNotification(
            token: connectionToken,
            title: "$currAccountUserName Sent a Image",
            body: "");
        break;
      case ChatMessageTypes.Video:
        await sendNotification(
            token: connectionToken,
            title: "$currAccountUserName Sent a Video",
            body: "");
        break;
      case ChatMessageTypes.Document:
        await sendNotification(
            token: connectionToken,
            title: "$currAccountUserName Sent a Document",
            body: "");
        break;
      case ChatMessageTypes.Audio:
        await sendNotification(
            token: connectionToken,
            title: "$currAccountUserName Sent a Audio",
            body: "");
        break;
      case ChatMessageTypes.Location:
        await sendNotification(
            token: connectionToken,
            title: "$currAccountUserName Sent a Location",
            body: "");
        break;
    }
  }

  Future<int> sendNotification(
      {required String token,
      required String title,
      required String body}) async {
    try {
      print("In Notification");

      final String _serverKey =
          "AAAAzux-oZE:APA91bEov5Ut9YqzpouJwaXOINfbGzVgUAx9u9qCrbfHjIT4FuqDdmwDW0RKHvE5A388M0bo9RSp-nMS5rykpgg9wkof3BhvMSiVcEXZ-qfwBxjVxMiTowOHR1IespO6ZhCYGqE6ZlZL";

      final Response response = await post(
        Uri.parse("https://fcm.googleapis.com/fcm/send"),
        headers: <String, String>{
          "Content-Type": "application/json",
          "Authorization": "key=$_serverKey",
        },
        body: jsonEncode(<String, dynamic>{
          "notification": <String, dynamic>{
            "body": body,
            "title": title,
          },
          "priority": "high",
          "data": <String, dynamic>{
            "click": "FLUTTER_NOTIFICATION_CLICK",
            "id": "1",
            "status": "done",
            "collapse_key": "type_a",
          },
          "to": token,
        }),
      );

      print("Response is: ${response.statusCode}   ${response.body}");

      return response.statusCode;
    } catch (e) {
      print("Error in Notification Send: ${e.toString()}");
      return 404;
    }
  }
}
