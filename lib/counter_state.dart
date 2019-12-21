import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'my_device.dart';
import 'my_auth_state.dart';

// this class contains all the state used in the sample app
class CounterState with ChangeNotifier {
  //
  // default Constructor - ensures we load the latest saved-value from the DB
  CounterState() {
    _myAuthState = MyAuthState()
      ..addListener(() async {
        notifyListeners();
        if (!authIsValid) {
          // not authenticated - cancel data-updates listener
          if (_dataUpdateListener == null) return;
          await _dataUpdateListener.cancel();
          _dataUpdateListener = null;
          return;
        }
        // authenticated - start listening for data-updates
        if (_dataUpdateListener != null) return;
        _listenForUpdates();
      });
    _myDevice = MyDevice()
      ..addListener(() {
        notifyListeners();
      });
  }
  //
  // this handle will allow us to cancel and restart the stream when auth changes
  StreamSubscription<DocumentSnapshot> _dataUpdateListener;
  //
  // the location of the document containing our state data
  final _sharedCounterDoc = Firestore.instance.collection('counterApp').document('shared');
  //
  // convenience, to avoid using these string-literals more than once
  static const _dbCounterValueField = 'counterValue';
  static const _dbDeviceNameField = 'deviceName';
  static const _dbUserNameField = 'userName';
  //
  // persistent state - i.e. what we will store and load across app runs
  int _value;
  String _lastUpdatedByDevice;
  String _lastUpdatedByUser;
  //
  // read-only access to the state
  // - ensuring state is modified only via whatever methods we expose
  int get value => _value;
  String get lastUpdatedByDevice => _lastUpdatedByDevice;
  String get lastUpdatedByUser => _lastUpdatedByUser;
  String get myDevice => _myDevice.name;
  bool get authIsValid => _myAuthState.isValid;
  String get userName => _myAuthState.userName;
  //
  void toggleAuth() {
    // disallow change if already busy
    if (_myAuthState.isWaiting) return;
    //
    if (_myAuthState.isValid) {
      _myAuthState.signOut();
    } else {
      _myAuthState.signIn();
    }
  }

  //
  // transient state - i.e. will not be stored when the app is not running
  //  internal-only readiness- & error-status
  bool _isWaiting = false;
  bool _hasError = false;
  MyDevice _myDevice;
  MyAuthState _myAuthState;
  //
  // read-only status indicators
  bool get isWaiting => _isWaiting || _myDevice.isWaiting || _myAuthState.isWaiting;
  bool get hasError => _hasError || _myAuthState.hasError;
  //
  // how we modify the state
  void increment() => _setValue(_value + 1);
  void reset() => _setValue(0);

  void _setValue(int newValue) {
    _value = newValue;
    _save();
  }

  //
  //  save the updated _value to the DB
  void _save() async {
    _hasError = false;
    _isWaiting = true;
    notifyListeners();
    try {
      await _sharedCounterDoc.setData({
        _dbCounterValueField: _value,
        _dbDeviceNameField: myDevice,
        _dbUserNameField: _myAuthState.userName,
      });
      _hasError = false;
    } catch (error) {
      _hasError = true;
    }
    _isWaiting = false;
    notifyListeners();
  }

  //
  // how we receive data from the DB, and notify
  void _listenForUpdates() {
    _isWaiting = true;
    notifyListeners();
    // listen to the stream of updates (e.g. due to other devices)
    _dataUpdateListener = _sharedCounterDoc.snapshots().listen((snapshot) {
      _isWaiting = false;
      if (!snapshot.exists) {
        _hasError = true;
        notifyListeners();
        return;
      }
      _hasError = false;
      // Convert to string, then try to extract a number
      final counterText = (snapshot.data[_dbCounterValueField] ?? 0).toString();
      // last resort is use 0
      _value = int.tryParse(counterText) ?? 0;
      _lastUpdatedByDevice = (snapshot.data[_dbDeviceNameField] ?? 'No device').toString();
      _lastUpdatedByUser = (snapshot.data[_dbUserNameField] ?? 'No user').toString();
      notifyListeners();
    }, onError: (error) {
      _hasError = true;
      notifyListeners();
    });
  }
}
