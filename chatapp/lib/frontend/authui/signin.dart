// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, unnecessary_import, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, sized_box_for_whitespace

import 'package:chatapp/backend/firebase/auth/emailandpassword.dart';
import 'package:chatapp/backend/firebase/auth/googleauth.dart';
import 'package:chatapp/frontend/authui/signup.dart';
import 'package:chatapp/frontend/mainscreens/homepage.dart';
import 'package:chatapp/frontend/newuserentry/newuserentry.dart';
import 'package:chatapp/global_uses/enums.dart';
import 'package:chatapp/global_uses/regexp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:loading_overlay/loading_overlay.dart';

class SignIn extends StatefulWidget {
  @override
  State<SignIn> createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final GlobalKey<FormState> _signinKey = GlobalKey();
  final TextEditingController email = TextEditingController();
  final TextEditingController pwd = TextEditingController();
  final EmailAndPasswordAuth emailAndPasswordAuth = EmailAndPasswordAuth();
  final GoogleAuthentication googleAuthentication = GoogleAuthentication();

  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Color.fromRGBO(34, 48, 60, 1),
        body: LoadingOverlay(
          isLoading: isLoading,
          child: Container(
            child: ListView(
              shrinkWrap: true,
              children: [
                SizedBox(
                  height: 100,
                ),
                Center(
                  child: Text(
                    "Sign In",
                    style: TextStyle(
                      fontSize: 30,
                      color: Colors.white,
                    ),
                  ),
                ),
                Container(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  padding: EdgeInsets.only(top: 45),
                  child: Form(
                    key: _signinKey,
                    child: ListView(
                      children: [
                        formfield(
                            hinttext: "Email",
                            controller: email,
                            validator: (input) {
                              if (!emailRegex.hasMatch(input.toString())) {
                                return "Email format doesnot match.";
                              }
                              return null;
                            }),
                        formfield(
                            hinttext: "Password",
                            controller: pwd,
                            validator: (input) {
                              if (input!.length < 6) {
                                return "Password must be atleast 6 characters.";
                              }
                              return null;
                            }),
                        //formfield(hinttext: "Confirm Password"),
                        SizedBox(
                          height: 20,
                        ),
                        button(),
                        SizedBox(
                          height: 10,
                        ),
                        Container(
                          child: Center(
                            child: Text(
                              "or continue with",
                              style: TextStyle(
                                color: Colors.white60,
                                fontSize: 17,
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          height: 10,
                        ),
                        socialmedia(),
                        SizedBox(
                          height: 25,
                        ),
                        navsignin(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget navsignin() {
    return Padding(
      padding: EdgeInsets.all(10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "Don't have an account?",
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
          SizedBox(
            width: 10,
          ),
          InkWell(
            onTap: () {
              Navigator.pushReplacement(
                  context, MaterialPageRoute(builder: (_) => SignUp()));
            },
            child: Text(
              "Sign Up",
              style: TextStyle(
                color: Colors.blue,
                fontSize: 16,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget formfield(
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

  Widget button() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 30),
      child: InkWell(
        onTap: () async {
          String msg = "";
          if (_signinKey.currentState!.validate()) {
            print("Validated");
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }

            emailSignInResults signinresult = await emailAndPasswordAuth
                .signInAuth(email: email.text, password: pwd.text);
            if (signinresult == emailSignInResults.SignInCompleted) {
              Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => PrimaryUserData()),
                  (route) => false);
            } else if (signinresult == emailSignInResults.EmailNotVerified) {
              msg == "Email not verified";
            } else if (signinresult ==
                emailSignInResults.EmailorPasswordInvalid) {
              msg = "Email or Password invalid";
            } else if (signinresult == emailSignInResults.UnexpectedError) {
              msg = "Unexpected Error";
            }
          } else {
            msg = "SignIn not completed";
            print("Not validated");
          }
          if (msg != "") {
            ScaffoldMessenger.of(context)
                .showSnackBar(SnackBar(content: Text(msg)));
          }

          if (mounted) {
            setState(() {
              isLoading = false;
            });
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
              "Sign In",
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

  Widget socialmedia() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 30),
      width: MediaQuery.of(context).size.width,
      height: 50,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          InkWell(
            onTap: () async {
              if (mounted) {
                setState(() {
                  isLoading = true;
                });
              }
              String msg = "";
              final googleSignInResults _googleSignInresults =
                  await googleAuthentication.signInWithGoogle();
              if (_googleSignInresults == googleSignInResults.SignInCompleted) {
              } else if (_googleSignInresults ==
                  googleSignInResults.SignInNotCompleted) {
                msg = "SignIn not complated";
              } else if (_googleSignInresults ==
                  googleSignInResults.UnexpectedError) {
                msg = "Unexpected error";
              } else {
                msg = "Already Signed In";
              }

              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(msg)));

              if (_googleSignInresults == googleSignInResults.SignInCompleted) {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => PrimaryUserData()),
                    result: (route) => false);
              }

              if (mounted) {
                setState(() {
                  isLoading = false;
                });
              }
            },
            child: Image.asset(
              'assets/images/google.png',
              width: 40,
            ),
          ),
          SizedBox(
            width: 30,
          ),
          Image.asset(
            'assets/images/fbook.png',
            width: 40,
          )
        ],
      ),
    );
  }
}
