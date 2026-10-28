import 'package:flutter/material.dart';

class NavigationProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int _refreshKey = 0;
  bool _isSidebarCollapsed = false;

  int get currentIndex => _currentIndex;
  int get refreshKey => _refreshKey;
  bool get isSidebarCollapsed => _isSidebarCollapsed;

  void toggleSidebar() {
    _isSidebarCollapsed = !_isSidebarCollapsed;
    notifyListeners();
  }

  void setSidebarCollapsed(bool value) {
    if (_isSidebarCollapsed != value) {
      _isSidebarCollapsed = value;
      notifyListeners();
    }
  }

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
    _isSidebarCollapsed = false;
    notifyListeners();
  }
}

