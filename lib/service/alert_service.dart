import 'package:chating/utils.dart';
import 'package:delightful_toast/delight_toast.dart';
import 'package:delightful_toast/toast/components/toast_card.dart';
import 'package:delightful_toast/toast/utils/enums.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'auth_service.dart';
import 'navigation_service.dart';

class AlertService {
  final GetIt _getIt = GetIt.instance;
  late AuthService _authService;
  late NavigationService _navigationService;

  AlertService() {
    _navigationService =_getIt.get<NavigationService>();
  }

  void showToast({required String text, IconData icon = Icons.info, required Color color}) {
    try {
      DelightToastBar(
          animationDuration: Duration(seconds: 2),
          snackbarDuration: Duration(seconds: 5),
          autoDismiss: true,
          position: DelightSnackbarPosition.top,
          builder: (context) {
            return ToastCard(
              leading: Icon(icon, size: 28, color: color,),
              title: Text(
                text,
                style: StyleText(fontWeight: FontWeight.w700, fontSize: 14,),
              ),
            );
          }).show(_navigationService.navigatorKey.currentContext!);
    } catch (e) {
      print('Error showing toast: ${e.toString()}');
    }
  }
}
