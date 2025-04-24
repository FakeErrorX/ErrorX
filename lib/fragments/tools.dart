import 'dart:io';
import 'package:errorx/common/common.dart';
import 'package:errorx/fragments/about.dart';
import 'package:errorx/fragments/access.dart';
import 'package:errorx/fragments/application_setting.dart';
import 'package:errorx/fragments/config/config.dart';
import 'package:errorx/fragments/hotkey.dart';
import 'package:errorx/l10n/l10n.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'theme.dart';
import 'package:path/path.dart' show dirname, join;
import 'package:url_launcher/url_launcher.dart';

class ToolsFragment extends ConsumerStatefulWidget {
  const ToolsFragment({super.key});

  @override
  ConsumerState<ToolsFragment> createState() => _ToolboxFragmentState();
}

class _ToolboxFragmentState extends ConsumerState<ToolsFragment> {
  _buildNavigationMenuItem(NavigationItem navigationItem) {
    return ListItem.open(
      leading: navigationItem.icon,
      title: Text(Intl.message(navigationItem.label.name)),
      subtitle: navigationItem.description != null
          ? Text(Intl.message(navigationItem.description!))
          : null,
      delegate: OpenDelegate(
        title: Intl.message(navigationItem.label.name),
        widget: navigationItem.fragment,
      ),
    );
  }

  Widget _buildNavigationMenu(List<NavigationItem> navigationItems) {
    return Column(
      children: [
        for (final navigationItem in navigationItems) ...[
          _buildNavigationMenuItem(navigationItem),
          navigationItems.last != navigationItem
              ? const Divider(
                  height: 0,
                )
              : Container(),
        ]
      ],
    );
  }

  List<Widget> _getOtherList() {
    return generateSection(
      title: appLocalizations.other,
      items: [
        _DocsItem(),
        _InfoItem(),
      ],
    );
  }

  _getSettingList() {
    return generateSection(
      title: appLocalizations.settings,
      items: [
        _ThemeItem(),
        if (system.isDesktop) _HotkeyItem(),
        if (Platform.isWindows) _LoopbackItem(),
        if (Platform.isAndroid) _AccessItem(),
        _ConfigItem(),
        _SettingItem(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final items = [
      Consumer(
        builder: (_, ref, __) {
          final state = ref.watch(moreToolsSelectorStateProvider);
          if (state.navigationItems.isEmpty) {
            return Container();
          }
          return Column(
            children: [
              ListHeader(title: appLocalizations.more),
              _buildNavigationMenu(state.navigationItems)
            ],
          );
        },
      ),
      ..._getSettingList(),
      ..._getOtherList(),
    ];
    return ListView.builder(
      itemCount: items.length,
      itemBuilder: (_, index) => items[index],
      padding: const EdgeInsets.only(bottom: 20),
    );
  }
}

class _ThemeItem extends StatelessWidget {
  const _ThemeItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.style),
      title: Text(appLocalizations.theme),
      subtitle: Text(appLocalizations.themeDesc),
      delegate: OpenDelegate(
        title: appLocalizations.theme,
        widget: const ThemeFragment(),
      ),
    );
  }
}

class _HotkeyItem extends StatelessWidget {
  const _HotkeyItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.keyboard),
      title: Text(appLocalizations.hotkeyManagement),
      subtitle: Text(appLocalizations.hotkeyManagementDesc),
      delegate: OpenDelegate(
        title: appLocalizations.hotkeyManagement,
        widget: const HotKeyFragment(),
      ),
    );
  }
}

class _LoopbackItem extends StatelessWidget {
  const _LoopbackItem();

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: const Icon(Icons.lock),
      title: Text(appLocalizations.loopback),
      subtitle: Text(appLocalizations.loopbackDesc),
      onTap: () {
        windows?.runas(
          '"${join(dirname(Platform.resolvedExecutable), "EnableLoopback.exe")}"',
          "",
        );
      },
    );
  }
}

class _AccessItem extends StatelessWidget {
  const _AccessItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.view_list),
      title: Text(appLocalizations.accessControl),
      subtitle: Text(appLocalizations.accessControlDesc),
      delegate: OpenDelegate(
        title: appLocalizations.appAccessControl,
        widget: const AccessFragment(),
      ),
    );
  }
}

class _ConfigItem extends StatelessWidget {
  const _ConfigItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.edit),
      title: Text(appLocalizations.basicConfig),
      subtitle: Text(appLocalizations.basicConfigDesc),
      delegate: OpenDelegate(
        title: appLocalizations.override,
        widget: const ConfigFragment(),
      ),
    );
  }
}

class _SettingItem extends StatelessWidget {
  const _SettingItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.settings),
      title: Text(appLocalizations.application),
      subtitle: Text(appLocalizations.applicationDesc),
      delegate: OpenDelegate(
        title: appLocalizations.application,
        widget: const ApplicationSettingFragment(),
      ),
    );
  }
}

class _DocsItem extends StatelessWidget {
  const _DocsItem();

  @override
  Widget build(BuildContext context) {
    return ListItem(
      leading: const Icon(Icons.description),
      title: Text("Docs"),
      onTap: () async {
        await launchUrl(Uri.parse("https://errorx.net/docs"));
      },
    );
  }
}

class _InfoItem extends StatelessWidget {
  const _InfoItem();

  @override
  Widget build(BuildContext context) {
    return ListItem.open(
      leading: const Icon(Icons.info),
      title: Text(appLocalizations.about),
      delegate: OpenDelegate(
        title: appLocalizations.about,
        widget: const AboutFragment(),
      ),
    );
  }
}
