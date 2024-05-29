import 'dart:async';
import 'dart:developer';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

class ConnectivityService with ChangeNotifier {
  final Connectivity _connectivity = Connectivity();
  late StreamSubscription<List<ConnectivityResult>> connectivitySubscription;
  bool _isConnected = false;
   bool get isConnected => _isConnected;

  ConnectivityService() {
    connectivitySubscription = _connectivity.onConnectivityChanged.listen((List<ConnectivityResult> result) { 
      if(result.contains(ConnectivityResult.wifi)) {
        _isConnected = true;
        log('Internet Connected');
      } else {
        _isConnected = false;
        log('Internet Disconnected');
      }
    });
    notifyListeners();
  }

  @override
  void dispose() {
    connectivitySubscription.cancel();
    super.dispose();
  }
}
