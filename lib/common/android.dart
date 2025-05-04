import 'dart:io';

import 'package:errorx/plugins/app.dart';
import 'package:errorx/state.dart';

class Android {
  init() async {
    app?.onExit = () async {
      await globalState.appController.savePreferences();
      // Ensure all profiles are encrypted before Android app exit
      await globalState.appController.ensureAllProfilesEncrypted();
    };
  }
}

final android = Platform.isAndroid ? Android() : null;
