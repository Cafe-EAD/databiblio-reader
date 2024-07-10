import 'package:fl_toast/fl_toast.dart';
import 'package:flutter/material.dart';

class Notifications {
  static warning({
    String? title,
    String? message,
    Duration? duration,
  }) {
    notificationBase(
      key: 'SnackbarWarning',
      backgroundColor: Colors.orange,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static success({
    String? title,
    String? message,
    Duration? duration,
  }) {
    notificationBase(
      key: 'SnackbarSuccess',
      backgroundColor: Colors.green,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static error({
    String? title,
    String? message,
    Duration? duration,
  }) {
    notificationBase(
      key: 'SnackbarError',
      backgroundColor: Colors.red,
      title: title,
      message: message,
      duration: duration,
    );
  }

  static notificationBase({
    String? key,
    Color? backgroundColor,
    String? title,
    String? message,
    Duration? duration,
  }) {
    showStyledToast(
      duration: duration ?? const Duration(seconds: 5),
      backgroundColor: Colors.transparent,
      margin: const EdgeInsets.all(8),
      contentPadding: const EdgeInsets.all(0),
      alignment: const Alignment(0, -1.0),
      child: Dismissible(
        key: ValueKey<String>('$key'),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(7),
          margin: const EdgeInsets.only(top: 20),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(7),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Icon(
                Icons.info_outline,
                size: 25,
                color: Colors.white,
              ),
              const SizedBox(
                width: 5,
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "$title",
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "$message",
                      textAlign: TextAlign.justify,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.normal,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: () {
                  ToastManager.dismissAll();
                },
                iconSize: 25,
                icon: const Icon(
                  Icons.close,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
      context: ToastProvider.context,
      animationBuilder: (context, animation, child) {
        return ScaleTransition(
          scale: animation,
          child: child,
        );
      },
    );
  }
}
