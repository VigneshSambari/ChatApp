// ignore_for_file: unused_local_variable, unnecessary_string_interpolations, non_constant_identifier_names, curly_braces_in_flow_control_structures, prefer_conditional_assignment
import 'package:chatapp/backend/sqlitemanagement/localdatabasemanagement.dart';
import 'package:chatapp/global_uses/constants.dart';
import 'package:chatapp/global_uses/enums.dart';
import 'package:chatapp/global_uses/sendnotificationmanagement.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';

class CloudStorage {
  final collection_Name = 'chat_users';
  final SendNotification _sendNotification = SendNotification();

  Future<bool> chechUserExists({required String userName}) async {
    try {
      final QuerySnapshot<Map<String, dynamic>> resultSnapshots =
          await FirebaseFirestore.instance
              .collection(collection_Name)
              .where('user_name', isEqualTo: userName)
              .get();
      if (resultSnapshots.docs.isNotEmpty) {
        print("UserName Already Exists");
        return true;
      } else {
        return false;
      }
    } catch (e) {
      print("Error in checking if username present or not");
      return false;
    }
  }

  Future<Stream<DocumentSnapshot<Map<String, dynamic>>>?>
      fetchRealTimeMessages() async {
    try {
      return FirebaseFirestore.instance
          .collection(collection_Name)
          .doc(FirebaseAuth.instance.currentUser!.email.toString())
          .snapshots();
    } catch (e) {
      print('Error in Fetch Real Time Data : ${e.toString()}');
      return null;
    }
  }

  Future<bool> registerUser(
      {required String userName,
      required String userAbout,
      required String userEmail}) async {
    try {
      final String currDate = DateFormat('dd-MM-yyyy').format(DateTime.now());
      final String? Token = await FirebaseMessaging.instance.getToken();
      final String currTime = "${DateFormat('hh:mm a').format(DateTime.now())}";
      await FirebaseFirestore.instance
          .collection(collection_Name)
          .doc(userEmail)
          .set({
        "about": userAbout,
        "activity": [],
        "connection_request": [],
        "connections": {},
        "creation_date": currDate,
        "creation_time": currTime,
        "phone_number": "",
        "profile_pic": "",
        "token": Token,
        "total_connections": "",
        "user_name": userName,
      });
      return true;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<void> removeOldMessages({required String connectionEmail}) async {
    try {
      final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection(collection_Name)
              .doc(currentUserEmail)
              .get();

      final Map<String, dynamic>? connectedUserData = documentSnapshot.data();

      connectedUserData![FirestoreFieldConstants().connections]
          [connectionEmail.toString()] = [];

      print(
          "After Remove: ${connectedUserData[FirestoreFieldConstants().connections]}");

      await FirebaseFirestore.instance
          .collection(collection_Name)
          .doc(currentUserEmail)
          .update({
        FirestoreFieldConstants().connections:
            connectedUserData[FirestoreFieldConstants().connections],
      }).whenComplete(() {
        print('Data Deletion Completed');
      });
    } catch (e) {
      print('error in Send Data: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> _getCurrentAccountAllData(
      {required String email}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection(collection_Name)
              .doc(email)
              .get();

      return documentSnapshot.data();
    } catch (e) {
      print('Error in getCurrentAccountAll Data: ${e.toString()}');
      return {};
    }
  }

  Future<bool> userRecordExist({required String email}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> docSnapshot =
          await FirebaseFirestore.instance
              .collection(collection_Name)
              .doc(email)
              .get();
      return docSnapshot.exists;
    } catch (e) {
      print(e.toString());
      return false;
    }
  }

  Future<Map<String, dynamic>> getToken({required String mail}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> docSnapshots =
          await FirebaseFirestore.instance
              .collection(collection_Name)
              .doc(mail)
              .get();
      Map<String, dynamic> data = <String, dynamic>{};
      data["token"] = docSnapshots.data()!["token"];
      data["currTime"] = docSnapshots.data()!["creation_time"];
      data["currDate"] = docSnapshots.data()!["creation_date"];
      return data;
    } catch (e) {
      return {};
    }
  }

  Future<List<Map<String, dynamic>>> getUsersAll({required userMail}) async {
    try {
      List<Map<String, dynamic>> lst = [];
      QuerySnapshot<Map<String, dynamic>> data =
          await FirebaseFirestore.instance.collection(collection_Name).get();
      data.docs
          .forEach((QueryDocumentSnapshot<Map<String, dynamic>> docSnapshot) {
        if (userMail != docSnapshot.id) {
          lst.add({
            docSnapshot.id:
                "${docSnapshot.get("user_name")}[user-name-about-divider]${docSnapshot.get("about")}}"
          });
        }
      });
      return lst;
    } catch (e) {
      print("Error retrieving users");
      return [];
    }
  }

  Future<void> changeConnectionStatus({
    required String oppositeUserMail,
    required String currentUserMail,
    required String connectionUpdatedStatus,
    required List<dynamic> currentUserUpdatedConnectionRequest,
    bool storeDataAlsoInConnections = false,
  }) async {
    try {
      print('Come here');

      /// Opposite Connection database Update
      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection(collection_Name)
              .doc(oppositeUserMail)
              .get();

      Map<String, dynamic>? map = documentSnapshot.data();

      print('Map: $map');

      List<dynamic> _oppositeConnectionsRequestsList =
          map!["connection_request"];

      int index = -1;

      _oppositeConnectionsRequestsList.forEach((element) {
        if (element.keys.first.toString() == currentUserMail)
          index = _oppositeConnectionsRequestsList.indexOf(element);
      });

      if (index > -1) _oppositeConnectionsRequestsList.removeAt(index);

      print('Opposite Connections: $_oppositeConnectionsRequestsList');

      _oppositeConnectionsRequestsList.add({
        currentUserMail: connectionUpdatedStatus,
      });

      print('Opposite Connections: $_oppositeConnectionsRequestsList');

      map["connection_request"] = _oppositeConnectionsRequestsList;

      await FirebaseFirestore.instance
          .collection(collection_Name)
          .doc(oppositeUserMail)
          .update(map);

      /// Current User Connection Database Update
      final Map<String, dynamic>? currentUserMap =
          await _getCurrentAccountAllData(email: currentUserMail);

      currentUserMap!["connection_request"] =
          currentUserUpdatedConnectionRequest;

      await FirebaseFirestore.instance
          .collection(collection_Name)
          .doc(currentUserMail)
          .update(currentUserMap);
    } catch (e) {
      print('Error in Change Connection Status: ${e.toString()}');
    }
  }

  Future<Map<String, dynamic>?> getAllCurrentUserData(
      {required String mail}) async {
    try {
      final DocumentSnapshot<Map<String, dynamic>> data =
          await FirebaseFirestore.instance
              .collection(collection_Name)
              .doc(mail)
              .get();
      return data.data();
    } catch (e) {
      print("Error in retieving all accounts data: ${e.toString}");
      return {};
    }
  }

  Future<List<dynamic>> curentUserConnLst({required String mail}) async {
    try {
      Map<String, dynamic>? userData = await getAllCurrentUserData(mail: mail);
      final List<dynamic> connectionRequests = userData!["connection_request"];
      return connectionRequests;
    } catch (e) {
      print("Error in connection requests{$e.toString()");
      return [];
    }
  }

  Future<Stream<QuerySnapshot<Map<String, dynamic>>>?>
      fetchRealTimeDataFromFirestore() async {
    try {
      return FirebaseFirestore.instance.collection(collection_Name).snapshots();
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadMediaToStorage(File filePath,
      {required String reference}) async {
    try {
      String? downLoadUrl;

      final String fileName =
          '${FirebaseAuth.instance.currentUser!.uid}${DateTime.now().day}${DateTime.now().month}${DateTime.now().year}${DateTime.now().hour}${DateTime.now().minute}${DateTime.now().second}${DateTime.now().millisecond}';

      final Reference firebaseStorageRef =
          FirebaseStorage.instance.ref(reference).child(fileName);

      print('Firebase Storage Reference: $firebaseStorageRef');

      final UploadTask uploadTask = firebaseStorageRef.putFile(filePath);

      await uploadTask.whenComplete(() async {
        print("Media Uploaded");
        downLoadUrl = await firebaseStorageRef.getDownloadURL();
        print("Download Url: $downLoadUrl}");
      });

      return downLoadUrl!;
    } catch (e) {
      print("Error: Firebase Storage Exception is: ${e.toString()}");
      return null;
    }
  }

  Future<void> sendMessageToConnection(
      {required String connectionUserName,
      required Map<String, Map<String, String>> sendMessageData,
      required ChatMessageTypes chatMessageTypes}) async {
    try {
      final LocalDatabase _localDatabase = LocalDatabase();

      final String? currentUserEmail = FirebaseAuth.instance.currentUser!.email;

      final String? _getConnectedUserEmail =
          await _localDatabase.getParticularFieldDataFromImportantTable(
              userName: connectionUserName,
              getField: GetFieldForImportantDataLocalDatabase.UserEmail);

      final DocumentSnapshot<Map<String, dynamic>> documentSnapshot =
          await FirebaseFirestore.instance
              .collection(collection_Name)
              .doc(_getConnectedUserEmail)
              .get();

      final Map<String, dynamic>? connectedUserData = documentSnapshot.data();

      List<dynamic>? getOldMessages =
          connectedUserData![FirestoreFieldConstants().connections]
              [currentUserEmail.toString()];
      if (getOldMessages == null) getOldMessages = [];

      getOldMessages.add(sendMessageData);

      connectedUserData[FirestoreFieldConstants().connections]
          [currentUserEmail.toString()] = getOldMessages;

      print(
          "Data checking: ${connectedUserData[FirestoreFieldConstants().connections]}");

      await FirebaseFirestore.instance
          .collection(collection_Name)
          .doc(_getConnectedUserEmail)
          .update({
        FirestoreFieldConstants().connections:
            connectedUserData[FirestoreFieldConstants().connections],
      }).whenComplete(() async {
        print('Data Send Completed');

        final String? connectionToken =
            await _localDatabase.getParticularFieldDataFromImportantTable(
                userName: connectionUserName,
                getField: GetFieldForImportantDataLocalDatabase.Token);

        final String? currentAccountUserName =
            await _localDatabase.getUserNameForCurrentUser(
                FirebaseAuth.instance.currentUser!.email.toString());
        if (chatMessageTypes != "Location") {
          await _sendNotification.messageNotificationClassifier(
              chatMessageTypes,
              connectionToken: connectionToken ?? "",
              currAccountUserName: currentAccountUserName ?? "");
        }
      });
    } catch (e) {
      print('error in Send Data: ${e.toString()}');
    }
  }
}
