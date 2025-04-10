import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/state.dart';
import 'package:flutter/cupertino.dart';

class CommonPrint {
  static CommonPrint? _instance;

  CommonPrint._internal();

  factory CommonPrint() {
    _instance ??= CommonPrint._internal();
    return _instance!;
  }

  log(String? text) {
    final payload = "[ErrorX] $text";
    debugPrint(payload);
    if (globalState.isService) {
      return;
    }
    globalState.appController.addLog(
      Log(logLevel: LogLevel.info, payload: payload),
    );
  }
}

final commonPrint = CommonPrint();
