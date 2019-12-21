import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:encrypt/encrypt.dart' as encrypt;
import 'package:shared_preferences/shared_preferences.dart';

//
// helper class to manage the auth state
class MyAuthState with ChangeNotifier {
  // for the auth creds
  String _username;
  String _password;
  //
  final _auth = FirebaseAuth.instance;
  static const _prevAuthKey = 'PreviouslyAuthenticatedAs';
  //
  // constructor
  MyAuthState() {
    _listenForAuthChanges();
  }
  //
  void _listenForAuthChanges() {
    _auth.onAuthStateChanged.listen((newUser) async {
      _authUser = newUser;
      //
      if (isValid) {
        final prefs = await SharedPreferences.getInstance();
        final prevUser = prefs.getString(_prevAuthKey);
        if (prevUser == null) {
          // this situation occurs only if the app has been re-installed and was
          //  previously authenticated at the time the app was deleted.
          //  iOS has this behaviour, as the auth session is stored in
          //  KeyChain and not cleared when the app is deleted. I want to start
          //  the app as signed-out in this case
          // must use this direct _auth.signOut() call - so that notifyListeners() is not called
          //  until the subsequent stream-update completes (when _authUser == null)
          await _auth.signOut();
          return;
        }
      }
      notifyListeners();
    });
  }

  //
  // state
  FirebaseUser _authUser;
  bool _hasError = false;
  bool _isWaiting = false;
  //
  // public properties/methods
  bool get isValid => _authUser != null;
  bool get hasError => _hasError;
  bool get isWaiting => _isWaiting;
  FirebaseUser get authUser => _authUser;
  String get userName => _authUser == null ? 'none' : _authUser.email;
  //
  Future<void> _fetchStaticCreds() async {
    // this doc must be world-read
    final credDoc = await Firestore.instance.collection('/config').document('private').get(source: Source.server);
    final dbUser = credDoc.data['mangledStaticUser'].toString();
    final dbPass = credDoc.data['mangledStaticPass'].toString();
    //
    // boiler-plate code for encrypt/decrypt - keep always
    final key = encrypt.Key.fromLength(32);
    final iv = encrypt.IV.fromLength(16);
    final encrypter = encrypt.Encrypter(encrypt.AES(key));
    //
    // // 1. assuming the DB fields initially contain the plain-text user/pass, then
    // // 2. uncomment these lines (to 3. below) & run to produce encrypted values:
    // final mangledUser = encrypter.encrypt(dbUser, iv: iv);
    // print('encrypted user: ${mangledUser.base16}');
    // _username = dbUser;
    // final mangledPass = encrypter.encrypt(dbPass, iv: iv);
    // print('encrypted password: ${mangledPass.base16}');
    // _password = dbPass;
    // // 3. now copy-n-paste those printed strings from the console into the DB fields
    // //  (overwriting the previous plain-text values)
    // // 4. then comment the above block
    //
    // 5. and then uncomment this one, and re-start the app
    //  and we have no longer any copy of the plain-text values
    //  (neither in the code nor the DB)
    _username = encrypter.decrypt16(dbUser, iv: iv);
    _password = encrypter.decrypt16(dbPass, iv: iv);
  }

  //
  void signIn() async {
    _isWaiting = true;
    notifyListeners();
    try {
      await _fetchStaticCreds();
      // store a local-key that we will require to be present when receiving notice of a valid session (e.g. during app startup)
      //  which can help detect sessions that out-live the app-installation-lifetime
      final prefs = await SharedPreferences.getInstance();
      prefs.setString(_prevAuthKey, _username);
      // now proceed with auto-login
      await _auth.signInWithEmailAndPassword(email: _username, password: _password);
      //
      _hasError = false;
    } catch (error) {
      _hasError = true;
    }
    _isWaiting = false;
    notifyListeners();
  }

  //
  Future<void> signOut() async {
    _isWaiting = true;
    notifyListeners();
    try {
      await _auth.signOut();
      _hasError = false;
    } catch (error) {
      _hasError = true;
    }
    _isWaiting = false;
    notifyListeners();
  }
}
