import 'dart:io';

import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/state.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:tray_manager/tray_manager.dart';

import 'app_localizations.dart';
import 'constant.dart';
import 'other.dart';
import 'window.dart';

class Tray {
  Future _updateSystemTray({
    required Brightness? brightness,
    bool force = false,
  }) async {
    if (Platform.isAndroid) {
      return;
    }
    if (Platform.isLinux || force) {
      await trayManager.destroy();
    }
    await trayManager.setIcon(
      other.getTrayIconPath(
        brightness: brightness ??
            WidgetsBinding.instance.platformDispatcher.platformBrightness,
      ),
      isTemplate: true,
    );
    if (!Platform.isLinux) {
      await trayManager.setToolTip(
        appName,
      );
    }
  }

  update({
    required TrayState trayState,
    bool focus = false,
  }) async {
    if (Platform.isAndroid) {
      return;
    }
    if (!Platform.isLinux) {
      await _updateSystemTray(
        brightness: trayState.brightness,
        force: focus,
      );
    }
    List<MenuItem> menuItems = [];
    final showMenuItem = MenuItem(
      label: appLocalizations.show,
      onClick: (_) {
        window?.show();
      },
    );
    menuItems.add(showMenuItem);
    menuItems.add(MenuItem.separator());
    for (final mode in Mode.values) {
      menuItems.add(
        MenuItem.checkbox(
          label: Intl.message(mode.name),
          onClick: (_) {
            globalState.appController.changeMode(mode);
          },
          checked: mode == trayState.mode,
        ),
      );
    }
    menuItems.add(MenuItem.separator());
    if (!Platform.isWindows) {
      for (final group in trayState.groups) {
        List<MenuItem> subMenuItems = [];
        for (final proxy in group.all) {
          subMenuItems.add(
            MenuItem.checkbox(
              label: proxy.name,
              checked: trayState.selectedMap[group.name] == proxy.name,
              onClick: (_) {
                final appController = globalState.appController;
                appController.updateCurrentSelectedMap(
                  group.name,
                  proxy.name,
                );
                appController.changeProxy(
                  groupName: group.name,
                  proxyName: proxy.name,
                );
              },
            ),
          );
        }
        menuItems.add(
          MenuItem.submenu(
            label: group.name,
            submenu: Menu(
              items: subMenuItems,
            ),
          ),
        );
      }
      if (trayState.groups.isNotEmpty) {
        menuItems.add(MenuItem.separator());
      }
    }
    if (trayState.isStart) {
      menuItems.add(
        MenuItem.checkbox(
          label: appLocalizations.tun,
          onClick: (_) {
            globalState.appController.updateTun();
          },
          checked: trayState.tunEnable,
        ),
      );
      menuItems.add(
        MenuItem.checkbox(
          label: appLocalizations.systemProxy,
          onClick: (_) {
            globalState.appController.updateSystemProxy();
          },
          checked: trayState.systemProxy,
        ),
      );
      menuItems.add(MenuItem.separator());
    }
    final autoStartMenuItem = MenuItem.checkbox(
      label: appLocalizations.autoLaunch,
      onClick: (_) async {
        globalState.appController.updateAutoLaunch();
      },
      checked: trayState.autoLaunch,
    );
    menuItems.add(autoStartMenuItem);
    menuItems.add(MenuItem.separator());
    final exitMenuItem = MenuItem(
      label: appLocalizations.exit,
      onClick: (_) async {
        await globalState.appController.handleExit();
      },
    );
    menuItems.add(exitMenuItem);
    final menu = Menu(items: menuItems);
    await trayManager.setContextMenu(menu);
    if (Platform.isLinux) {
      await _updateSystemTray(
        brightness: trayState.brightness,
        force: focus,
      );
    }
  }

  updateTrayTitle([Traffic? traffic]) async {
    // if (!Platform.isMacOS) {
    //   return;
    // }
    // if (traffic == null) {
    //   await trayManager.setTitle("");
    // } else {
    //   await trayManager.setTitle(
    //     "${traffic.up.shortShow} ↑ \n${traffic.down.shortShow} ↓",
    //   );
    // }
  }
}

final tray = Tray();
