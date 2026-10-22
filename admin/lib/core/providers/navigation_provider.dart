import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int _refreshKey = 0;

  int get currentIndex => _currentIndex;
  int get refreshKey => _refreshKey;

  void setIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
    }
    _refreshKey++;
    notifyListeners();
  }

  void refreshCurrentTab() {
    _refreshKey++;
    notifyListeners();
  }

  void reset() {
    _currentIndex = 0;
    _refreshKey = 0;
    notifyListeners();
  }
}

