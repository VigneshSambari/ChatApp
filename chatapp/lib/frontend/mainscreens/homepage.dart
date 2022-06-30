import 'package:chatapp/backend/firebase/auth/emailandpassword.dart';
import 'package:chatapp/backend/firebase/auth/googleauth.dart';
import 'package:chatapp/frontend/authui/signin.dart';
import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  @override
  final GoogleAuthentication googleAuthentication = GoogleAuthentication();
  final EmailAndPasswordAuth emailAndPasswordAuth = EmailAndPasswordAuth();
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        alignment: Alignment.center,
        child: ElevatedButton(
          onPressed: () async {
            final bool res = await googleAuthentication.logOut();
            if (!res) {
              await emailAndPasswordAuth.logOut();
            }

            Navigator.pushAndRemoveUntil(context,
                MaterialPageRoute(builder: (_) => SignIn()), (route) => false);
          },
          child: Text(
            "Log Out",
            style: TextStyle(color: Colors.white),
          ),
        ),
      ),
    );
  }
}
