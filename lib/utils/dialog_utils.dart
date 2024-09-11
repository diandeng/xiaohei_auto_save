import 'package:flutter/material.dart';

class DialogUtils {
  static Future<void> showSimpleDialog({
    required BuildContext context,
    required String title,
    required String content,
    String confirmText = '确定',
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }

  static Future<void> showAlertDialog({
    required BuildContext context,
    required String title,
    required String content,
    required VoidCallback onConfirm,
    String confirmText = '确定',
    String cancelText = '取消',
    Color confirmButtonColor = Colors.red,
  }) async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: <Widget>[
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(cancelText),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: TextButton.styleFrom(foregroundColor: confirmButtonColor),
              child: Text(confirmText),
            ),
          ],
        );
      },
    );
  }
}
