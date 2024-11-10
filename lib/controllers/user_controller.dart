import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class UserController {
 
  static User? user = FirebaseAuth.instance.currentUser; //is there a user
  
    static Future<User?> loginWithGoogle() async {
      final googleAccount = await GoogleSignIn().signIn();

      final googleAuth = await googleAccount?.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth?.accessToken,
        idToken: googleAuth?.idToken,
      );

      final userCredential = await FirebaseAuth.instance.signInWithCredential(
        credential,
      );

      final User? user = userCredential.user;

      if (user != null) {
      // Check if the user document exists
      final userDoc = FirebaseFirestore.instance.collection('users').doc(user.uid);
      final docSnapshot = await userDoc.get();

      if (docSnapshot.exists) {
        // Merge new data with existing data
        await userDoc.set({
          'uid': user.uid,
          'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
        }, SetOptions(merge: true));
      } else {
        // Initialize new user document
        await userDoc.set({
          'uid': user.uid,
          'displayName': user.displayName,
          'email': user.email,
          'photoURL': user.photoURL,
          'lastSignInTime': user.metadata.lastSignInTime?.toIso8601String(),
          'creationTime': user.metadata.creationTime?.toIso8601String(),
          'additionalInfo': 'Some additional info', // Add additional info
          'listOfHabits': [], // Initializing it with an empty list
          'listOfGroups': [], // init an empty list
        });
      }
    }

    return user;
  }
 

  static Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    await GoogleSignIn().signOut();
  }
}

