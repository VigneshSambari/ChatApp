// ignore_for_file: use_key_in_widget_constructors, prefer_const_constructors, unnecessary_import, prefer_const_literals_to_create_immutables, avoid_unnecessary_containers, sized_box_for_whitespace, non_constant_identifier_names, curly_braces_in_flow_control_structures

import 'package:chatapp/backend/firebase/auth/emailandpassword.dart';
import 'package:chatapp/backend/firebase/auth/googleauth.dart';
import 'package:chatapp/frontend/authui/signin.dart';
import 'package:chatapp/frontend/mainscreens/homepage.dart';
import 'package:chatapp/frontend/newuserentry/newuserentry.dart';
import 'package:chatapp/global_uses/enums.dart';
import 'package:chatapp/global_uses/regexp.dart';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:loading_overlay/loading_overlay.dart';

class SignUp extends StatefulWidget {
  @override
  State<SignUp> createState() => _SignUpState();
}

class _SignUpState extends State<SignUp> {
  final TextEditingController email = TextEditingController();
  final TextEditingController pwd = TextEditingController();
  final TextEditingController cpwd = TextEditingController();
  final EmailAndPasswordAuth _emailAndPasswordAuth = EmailAndPasswordAuth();
  final GoogleAuthentication googleAuthentication = GoogleAuthentication();
  bool isLoading = false;

  final GlobalKey<FormState> _signupKey = GlobalKey();
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
                    "Sign Up",
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
                    key: _signupKey,
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
                                return "Password should be atleast 6 characters.";
                              }
                              return null;
                            }),
                        formfield(
                            hinttext: "Confirm Password",
                            controller: cpwd,
                            validator: (input) {
                              if (input!.length < 6) {
                                return "Password should be atleast 6 characters.";
                              }
                              if (pwd.text != cpwd.text)
                                return "Password and confirm password must be same.";
                              return null;
                            }),
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
            "Already have an account?",
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
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => SignIn()));
            },
            child: Text(
              "Sign In",
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
        obscureText: hinttext == "Password" || hinttext == "Confirm Password"
            ? true
            : false,
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
          if (_signupKey.currentState!.validate()) {
            SystemChannels.textInput.invokeMethod('TextInput.hide');
            print("validate");
            emailSignupResults response = await _emailAndPasswordAuth
                .signUpAuth(email: email.text, password: pwd.text);
            if (response == emailSignupResults.SignUpCompleted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("Verification sent to email.")));
              Navigator.push(
                  context, MaterialPageRoute(builder: (_) => SignIn()));
            } else {
              String res = response == emailSignupResults.EmailAlreadyPresent
                  ? "Email already present"
                  : "Problem Signing up";
              ScaffoldMessenger.of(context)
                  .showSnackBar(SnackBar(content: Text(res)));
            }
          } else {
            print("Not validated");
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
              "Sign Up",
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
