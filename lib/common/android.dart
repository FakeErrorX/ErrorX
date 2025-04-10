import 'dart:io';

import 'package:errorx/plugins/app.dart';
import 'package:errorx/state.dart';

class Android {
  init() async {
    app?.onExit = () async {
      await globalState.appController.savePreferences();
    };
  }
}

final android = Platform.isAndroid ? Android() : null;
