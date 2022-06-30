import 'package:chatapp/global_uses/enums.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailAndPasswordAuth {
  Future<emailSignupResults> signUpAuth(
      {required String email, required String password}) async {
    try {
      final userCredentials = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);
      if (userCredentials.user!.email != null) {
        await userCredentials.user!.sendEmailVerification();
        return emailSignupResults.SignUpCompleted;
      }

      return emailSignupResults.SignUpNotCompleted;
    } catch (e) {
      print("Error in signup: ${e.toString()}");
      return emailSignupResults.EmailAlreadyPresent;
    }
  }

  Future<emailSignInResults> signInAuth(
      {required String email, required String password}) async {
    try {
      final userCredentials = await FirebaseAuth.instance
          .signInWithEmailAndPassword(email: email, password: password);
      if (userCredentials.user!.emailVerified) {
        return emailSignInResults.SignInCompleted;
      } else {
        bool logOutRes = await logOut();
        if (logOutRes) return emailSignInResults.EmailNotVerified;
        return emailSignInResults.UnexpectedError;
      }
      return emailSignInResults.EmailNotVerified;
    } catch (e) {
      print("Error in Signing In ${e.toString()}");
      return emailSignInResults.EmailorPasswordInvalid;
    }
  }

  Future<bool> logOut() async {
    try {
      FirebaseAuth.instance.signOut();
      return true;
    } catch (e) {
      return false;
    }
    return true;
  }
}
