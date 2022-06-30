import 'package:chatapp/global_uses/enums.dart';
import "package:google_sign_in/google_sign_in.dart";
import 'package:firebase_auth/firebase_auth.dart';

class GoogleAuthentication {
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Future<bool> logOut() async {
    try {
      await _googleSignIn.disconnect();
      await _googleSignIn.signOut();
      await FirebaseAuth.instance.signOut();
      print("Logged out");
      return true;
    } catch (e) {
      print("Error in signing out ${e.toString()}");
      return false;
    }
  }

  Future<googleSignInResults> signInWithGoogle() async {
    try {
      if (await _googleSignIn.isSignedIn()) {
        await logOut();
        return googleSignInResults.AlreadySignedIn;
      } else {
        final GoogleSignInAccount? _googleSignInAccount =
            await _googleSignIn.signIn();
        if (_googleSignInAccount == null) {
          print("Google SignIn not completed");
          return googleSignInResults.SignInNotCompleted;
        } else {
          final GoogleSignInAuthentication _googleSignInAuthentication =
              await _googleSignInAccount.authentication;
          final OAuthCredential _authCredential = GoogleAuthProvider.credential(
              accessToken: _googleSignInAuthentication.accessToken,
              idToken: _googleSignInAuthentication.idToken);
          final UserCredential userCredential =
              await FirebaseAuth.instance.signInWithCredential(_authCredential);

          if (userCredential.user!.email != null) {
            print("Google SignIn completed");
            return googleSignInResults.SignInCompleted;
          } else {
            print("Probem signing in with google");
            return googleSignInResults.UnexpectedError;
          }
        }
      }
    } catch (e) {
      print("Error signing in with google ${e.toString()}");
      return googleSignInResults.UnexpectedError;
    }
  }
}
