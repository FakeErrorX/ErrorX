import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';
import 'dart:typed_data';

import 'package:archive/archive.dart';
import 'package:errorx/clash/clash.dart';
import 'package:errorx/common/archive.dart';
import 'package:errorx/common/encryption_service.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/providers/providers.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';
import 'package:url_launcher/url_launcher.dart';

import 'common/common.dart';
import 'fragments/profiles/override_profile.dart';
import 'models/models.dart';

class AppController {
  bool lastTunEnable = false;
  int? lastProfileModified;

  final BuildContext context;
  final WidgetRef _ref;

  AppController(this.context, WidgetRef ref) : _ref = ref;

  updateClashConfigDebounce() {
    debouncer.call(DebounceTag.updateClashConfig, () {
      updateClashConfig(true);
    });
  }

  updateGroupsDebounce() {
    debouncer.call(DebounceTag.updateGroups, updateGroups);
  }

  addCheckIpNumDebounce() {
    debouncer.call(DebounceTag.addCheckIpNum, () {
      _ref.read(checkIpNumProvider.notifier).add();
    });
  }

  applyProfileDebounce({
    bool silence = false,
  }) {
    debouncer.call(DebounceTag.applyProfile, (silence) {
      applyProfile(silence: silence);
    }, args: [silence]);
  }

  savePreferencesDebounce() {
    debouncer.call(DebounceTag.savePreferences, savePreferences);
  }

  changeProxyDebounce(String groupName, String proxyName) {
    debouncer.call(DebounceTag.changeProxy,
        (String groupName, String proxyName) async {
      await changeProxy(
        groupName: groupName,
        proxyName: proxyName,
      );
      await updateGroups();
    }, args: [groupName, proxyName]);
  }

  restartCore() async {
    await clashService?.reStart();
    await initCore();

    if (_ref.read(runTimeProvider.notifier).isStart) {
      await globalState.handleStart();
    }
  }

  updateStatus(bool isStart) async {
    if (isStart) {
      await globalState.handleStart([
        updateRunTime,
        updateTraffic,
      ]);
      final currentLastModified =
          await _ref.read(currentProfileProvider)?.profileLastModified;
      if (currentLastModified == null || lastProfileModified == null) {
        addCheckIpNumDebounce();
        return;
      }
      if (currentLastModified <= (lastProfileModified ?? 0)) {
        addCheckIpNumDebounce();
        return;
      }
      applyProfileDebounce();
    } else {
      await globalState.handleStop();
      await clashCore.resetTraffic();
      _ref.read(trafficsProvider.notifier).clear();
      _ref.read(totalTrafficProvider.notifier).value = Traffic();
      _ref.read(runTimeProvider.notifier).value = null;
      // tray.updateTrayTitle(null);
      addCheckIpNumDebounce();
    }
  }

  updateRunTime() {
    final startTime = globalState.startTime;
    if (startTime != null) {
      final startTimeStamp = startTime.millisecondsSinceEpoch;
      final nowTimeStamp = DateTime.now().millisecondsSinceEpoch;
      _ref.read(runTimeProvider.notifier).value = nowTimeStamp - startTimeStamp;
    } else {
      _ref.read(runTimeProvider.notifier).value = null;
    }
  }

  updateTraffic() async {
    final traffic = await clashCore.getTraffic();
    _ref.read(trafficsProvider.notifier).addTraffic(traffic);
    _ref.read(totalTrafficProvider.notifier).value =
        await clashCore.getTotalTraffic();
  }

  addProfile(Profile profile) async {
    _ref.read(profilesProvider.notifier).setProfile(profile);
    if (_ref.read(currentProfileIdProvider) != null) return;
    _ref.read(currentProfileIdProvider.notifier).value = profile.id;
  }

  deleteProfile(String id) async {
    _ref.read(profilesProvider.notifier).deleteProfileById(id);
    clearEffect(id);
    if (globalState.config.currentProfileId == id) {
      final profiles = globalState.config.profiles;
      final currentProfileId = _ref.read(currentProfileIdProvider.notifier);
      if (profiles.isNotEmpty) {
        final updateId = profiles.first.id;
        currentProfileId.value = updateId;
      } else {
        currentProfileId.value = null;
        updateStatus(false);
      }
    }
  }

  updateProviders() async {
    _ref.read(providersProvider.notifier).value =
        await clashCore.getExternalProviders();
  }

  updateLocalIp() async {
    _ref.read(localIpProvider.notifier).value = null;
    await Future.delayed(commonDuration);
    _ref.read(localIpProvider.notifier).value = await other.getLocalIpAddress();
  }

  Future<void> updateProfile(Profile profile) async {
    final newProfile = await profile.update();
    _ref
        .read(profilesProvider.notifier)
        .setProfile(newProfile.copyWith(isUpdating: false));
    if (profile.id == _ref.read(currentProfileIdProvider)) {
      applyProfileDebounce(silence: true);
    }
  }

  setProfile(Profile profile) {
    _ref.read(profilesProvider.notifier).setProfile(profile);
  }

  setProfileAndAutoApply(Profile profile) {
    _ref.read(profilesProvider.notifier).setProfile(profile);
    if (profile.id == _ref.read(currentProfileIdProvider)) {
      applyProfileDebounce(silence: true);
    }
  }

  setProfiles(List<Profile> profiles) {
    _ref.read(profilesProvider.notifier).value = profiles;
  }

  addLog(Log log) {
    _ref.read(logsProvider).add(log);
  }

  updateOrAddHotKeyAction(HotKeyAction hotKeyAction) {
    final hotKeyActions = _ref.read(hotKeyActionsProvider);
    final index =
        hotKeyActions.indexWhere((item) => item.action == hotKeyAction.action);
    if (index == -1) {
      _ref.read(hotKeyActionsProvider.notifier).value = List.from(hotKeyActions)
        ..add(hotKeyAction);
    } else {
      _ref.read(hotKeyActionsProvider.notifier).value = List.from(hotKeyActions)
        ..[index] = hotKeyAction;
    }

    _ref.read(hotKeyActionsProvider.notifier).value = index == -1
        ? (List.from(hotKeyActions)..add(hotKeyAction))
        : (List.from(hotKeyActions)..[index] = hotKeyAction);
  }

  List<Group> getCurrentGroups() {
    return _ref.read(currentGroupsStateProvider.select((state) => state.value));
  }

  String getRealTestUrl(String? url) {
    return _ref.read(getRealTestUrlProvider(url));
  }

  int getProxiesColumns() {
    return _ref.read(getProxiesColumnsProvider);
  }

  addSortNum() {
    return _ref.read(sortNumProvider.notifier).add();
  }

  getCurrentGroupName() {
    final currentGroupName = _ref.read(currentProfileProvider.select(
      (state) => state?.currentGroupName,
    ));
    return currentGroupName;
  }

  ProxyCardState getProxyCardState(proxyName) {
    return _ref.read(getProxyCardStateProvider(proxyName));
  }

  getSelectedProxyName(groupName) {
    return _ref.read(getSelectedProxyNameProvider(groupName));
  }

  updateCurrentGroupName(String groupName) {
    final profile = _ref.read(currentProfileProvider);
    if (profile == null || profile.currentGroupName == groupName) {
      return;
    }
    setProfile(
      profile.copyWith(currentGroupName: groupName),
    );
  }

  Future<void> updateClashConfig([bool? isPatch]) async {
    commonPrint.log("update clash patch: ${isPatch ?? false}");
    final commonScaffoldState = globalState.homeScaffoldKey.currentState;
    if (commonScaffoldState?.mounted != true) return;
    await commonScaffoldState?.loadingRun(() async {
      await _updateClashConfig(
        isPatch,
      );
    });
  }

  Future<void> _updateClashConfig([bool? isPatch]) async {
    final profile = _ref.watch(currentProfileProvider);
    await _ref.read(currentProfileProvider)?.checkAndUpdate();
    
    // Temporarily decrypt the profile file for Clash Core to read
    if (profile != null) {
      await profile.temporarilyDecryptForCore();
    }
    
    final patchConfig = _ref.read(patchClashConfigProvider);
    final appSetting = _ref.read(appSettingProvider);
    bool enableTun = patchConfig.tun.enable;
    if (enableTun != lastTunEnable &&
        lastTunEnable == false &&
        !Platform.isAndroid) {
      final code = await system.authorizeCore();
      switch (code) {
        case AuthorizeCode.none:
          break;
        case AuthorizeCode.success:
          lastTunEnable = enableTun;
          await restartCore();
          return;
        case AuthorizeCode.error:
          enableTun = false;
      }
    }
    if (appSetting.openLogs) {
      clashCore.startLog();
    } else {
      clashCore.stopLog();
    }
    final res = await clashCore.updateConfig(
      globalState.getUpdateConfigParams(isPatch),
    );
    if (res.isNotEmpty) throw res;
    lastTunEnable = enableTun;
    lastProfileModified = await profile?.profileLastModified;
  }

  // Ensure all profiles are properly decrypted for core operations
  Future<void> ensureProfilesDecrypted() async {
    // Get all profiles and ensure they're decrypted for core operations
    final profiles = _ref.read(profilesProvider);
    for (final profile in profiles) {
      try {
        await profile.prepareForClashCore();
      } catch (e) {
        commonPrint.log("Failed to decrypt profile ${profile.id}: $e");
      }
    }
  }

  // Enhanced version to ensure current profile is decrypted for Clash Core
  Future<void> ensureCurrentProfileDecrypted() async {
    final currentProfile = _ref.read(currentProfileProvider);
    if (currentProfile != null) {
      try {
        // First prepare the profile in memory
        await currentProfile.prepareForClashCore();
        
        // Then decrypt on disk for Clash Core operations
        await currentProfile.temporarilyDecryptForCore();
      } catch (e) {
        commonPrint.log("Failed to decrypt current profile: $e");
      }
    }
  }

  // Ensure all profiles are safely encrypted before app exits
  Future<void> ensureAllProfilesEncrypted() async {
    final profiles = _ref.read(profilesProvider);
    for (final profile in profiles) {
      try {
        // Get the file path
        final profilePath = await appPath.getProfilePath(profile.id);
        if (profilePath == null) continue;
        
        final file = File(profilePath);
        if (!await file.exists()) continue;
        
        // Check if file is currently encrypted
        final bytes = await file.readAsBytes();
        if (!EncryptionService.hasEncryptionHeader(bytes) && 
            EncryptionService.isProfileCached(profile.id)) {
          // File is decrypted but we have the cached version, re-encrypt immediately
          final cachedBytes = EncryptionService.getCachedProfile(profile.id)!;
          final encryptedBytes = EncryptionService.encrypt(cachedBytes);
          await file.writeAsBytes(encryptedBytes);
          commonPrint.log("Re-encrypted profile ${profile.id} before exit");
        }
      } catch (e) {
        commonPrint.log("Failed to ensure encryption for profile ${profile.id}: $e");
      }
    }
  }

  Future _applyProfile() async {
    await clashCore.requestGc();
    await updateClashConfig();
    await updateGroups();
    await updateProviders();
  }

  Future applyProfile({bool silence = false}) async {
    if (silence) {
      await _applyProfile();
    } else {
      final commonScaffoldState = globalState.homeScaffoldKey.currentState;
      if (commonScaffoldState?.mounted != true) return;
      await commonScaffoldState?.loadingRun(() async {
        await _applyProfile();
      });
    }
    addCheckIpNumDebounce();
  }

  handleChangeProfile() {
    _ref.read(delayDataSourceProvider.notifier).value = {};
    applyProfile();
  }

  updateBrightness(Brightness brightness) {
    _ref.read(appBrightnessProvider.notifier).value = brightness;
  }

  autoUpdateProfiles() async {
    for (final profile in _ref.read(profilesProvider)) {
      if (!profile.autoUpdate) continue;
      final isNotNeedUpdate = profile.lastUpdateDate
          ?.add(
            profile.autoUpdateDuration,
          )
          .isBeforeNow;
      if (isNotNeedUpdate == false || profile.type == ProfileType.file) {
        continue;
      }
      try {
        await updateProfile(profile);
      } catch (e) {
        _ref.read(logsProvider.notifier).addLog(
              Log(
                logLevel: LogLevel.info,
                payload: e.toString(),
              ),
            );
      }
    }
  }

  Future<void> updateGroups() async {
    // Ensure the current profile is decrypted for Clash Core operations
    await ensureCurrentProfileDecrypted();
    
    _ref.read(groupsProvider.notifier).value = await retry(
      task: () async {
        return await clashCore.getProxiesGroups();
      },
      retryIf: (res) => res.isEmpty,
    );
  }

  updateProfiles() async {
    for (final profile in _ref.read(profilesProvider)) {
      if (profile.type == ProfileType.file) {
        continue;
      }
      await updateProfile(profile);
    }
  }

  updateSystemColorSchemes(ColorSchemes colorSchemes) {
    _ref.read(appSchemesProvider.notifier).value = colorSchemes;
  }

  savePreferences() async {
    commonPrint.log("save preferences");
    await preferences.saveConfig(globalState.config);
  }

  changeProxy({
    required String groupName,
    required String proxyName,
  }) async {
    await clashCore.changeProxy(
      ChangeProxyParams(
        groupName: groupName,
        proxyName: proxyName,
      ),
    );
    if (_ref.read(appSettingProvider).closeConnections) {
      clashCore.closeConnections();
    }
    addCheckIpNumDebounce();
  }

  handleBackOrExit() async {
    if (_ref.read(appSettingProvider).minimizeOnExit) {
      if (system.isDesktop) {
        await savePreferencesDebounce();
      }
      await system.back();
    } else {
      await handleExit();
    }
  }

  handleExit() async {
    try {
      await updateStatus(false);
      await clashCore.shutdown();
      await clashService?.destroy();
      await proxy?.stopProxy();
      await savePreferences();
    } finally {
      system.exit();
    }
  }

  autoCheckUpdate() async {
    if (!_ref.read(appSettingProvider).autoCheckUpdate) return;
    final res = await request.checkForUpdate();
    checkUpdateResultHandle(data: res);
  }

  checkUpdateResultHandle({
    Map<String, dynamic>? data,
    bool handleError = false,
  }) async {
    if(globalState.isPre){
      return;
    }
    if (data != null) {
      final tagName = data['tag_name'];
      final body = data['body'];
      final submits = other.parseReleaseBody(body);
      final textTheme = context.textTheme;
      final res = await globalState.showMessage(
        title: appLocalizations.discoverNewVersion,
        message: TextSpan(
          text: "$tagName \n",
          style: textTheme.headlineSmall,
          children: [
            TextSpan(
              text: "\n",
              style: textTheme.bodyMedium,
            ),
            for (final submit in submits)
              TextSpan(
                text: "- $submit \n",
                style: textTheme.bodyMedium,
              ),
          ],
        ),
        confirmText: appLocalizations.goDownload,
      );
      if (res != true) {
        return;
      }
      launchUrl(
        Uri.parse("https://github.com/$repository/releases/latest"),
      );
    } else if (handleError) {
      globalState.showMessage(
        title: appLocalizations.checkUpdate,
        message: TextSpan(
          text: appLocalizations.checkUpdateError,
        ),
      );
    }
  }

  _handlePreference() async {
    if (await preferences.isInit) {
      return;
    }
    final res = await globalState.showMessage(
      title: appLocalizations.tip,
      message: TextSpan(text: appLocalizations.cacheCorrupt),
    );
    if (res == true) {
      final file = File(await appPath.sharedPreferencesPath);
      final isExists = await file.exists();
      if (isExists) {
        await file.delete();
      }
    }
    await handleExit();
  }

  Future<void> initCore() async {
    final isInit = await clashCore.isInit;
    if (!isInit) {
      await clashCore.setState(
        globalState.getCoreState(),
      );
      await clashCore.init();
    }
    await applyProfile();
  }

  init() async {
    await _handlePreference();
    await _handlerDisclaimer();
    await initCore();
    await _initStatus();
    updateTray(true);
    autoLaunch?.updateStatus(
      _ref.read(appSettingProvider).autoLaunch,
    );
    autoUpdateProfiles();
    autoCheckUpdate();
    if (!_ref.read(appSettingProvider).silentLaunch) {
      window?.show();
    } else {
      window?.hide();
    }
    _ref.read(initProvider.notifier).value = true;
  }

  _initStatus() async {
    if (Platform.isAndroid) {
      await globalState.updateStartTime();
    }
    final status = globalState.isStart == true
        ? true
        : _ref.read(appSettingProvider).autoRun;

    await updateStatus(status);
    if (!status) {
      addCheckIpNumDebounce();
    }
  }

  setDelay(Delay delay) {
    _ref.read(delayDataSourceProvider.notifier).setDelay(delay);
  }

  toPage(PageLabel pageLabel) {
    _ref.read(currentPageLabelProvider.notifier).value = pageLabel;
  }

  toProfiles() {
    toPage(PageLabel.profiles);
  }

  initLink() {
    linkManager.initAppLinksListen(
      (url) async {
        final res = await globalState.showMessage(
          title: "${appLocalizations.add}${appLocalizations.profile}",
          message: TextSpan(
            children: [
              TextSpan(text: appLocalizations.doYouWantToPass),
              TextSpan(
                text: " $url ",
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                  decorationColor: Theme.of(context).colorScheme.primary,
                ),
              ),
              TextSpan(
                  text:
                      "${appLocalizations.create}${appLocalizations.profile}"),
            ],
          ),
        );

        if (res != true) {
          return;
        }
        addProfileFormURL(url);
      },
    );
  }

  Future<bool> showDisclaimer() async {
    return await globalState.showCommonDialog<bool>(
          dismissible: false,
          child: CommonDialog(
            title: appLocalizations.disclaimer,
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pop<bool>(false);
                },
                child: Text(appLocalizations.exit),
              ),
              TextButton(
                onPressed: () {
                  _ref.read(appSettingProvider.notifier).updateState(
                        (state) => state.copyWith(disclaimerAccepted: true),
                      );
                  Navigator.of(context).pop<bool>(true);
                },
                child: Text(appLocalizations.agree),
              )
            ],
            child: SelectableText(
              appLocalizations.disclaimerDesc,
            ),
          ),
        ) ??
        false;
  }

  _handlerDisclaimer() async {
    if (_ref.read(appSettingProvider).disclaimerAccepted) {
      return;
    }
    
    // Auto-accept the disclaimer without showing dialog
    _ref.read(appSettingProvider.notifier).updateState(
      (state) => state.copyWith(disclaimerAccepted: true),
    );
    
    // Automatically download and apply default profile on first run
    const url = 'https://raw.githubusercontent.com/FakeErrorX/ConfigX/refs/heads/master/ErrorX.yaml';
    await addProfileFormURL(url, name: "ErrorX", silentMode: true);
    
    return;
  }

  addProfileFormURL(String url, {String? name, bool silentMode = false}) async {
    if (!silentMode && globalState.navigatorKey.currentState?.canPop() == true) {
      globalState.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    }
    if (!silentMode) {
      toProfiles();
    }
    
    Profile? profile;
    try {
      // Create profile directly without depending on scaffold state
      profile = await Profile.normal(
        url: url,
        label: name,
      ).update();
      
      // Only use loading screen if not in silent mode and scaffold is available
      if (!silentMode) {
        final commonScaffoldState = globalState.homeScaffoldKey.currentState;
        if (commonScaffoldState != null && commonScaffoldState.mounted) {
          commonPrint.log("Adding profile with loading UI for: $url");
        }
      } else {
        commonPrint.log("Adding profile silently for: $url");
      }
    } catch (e) {
      commonPrint.log("Error downloading profile: $e");
      if (!silentMode) {
        // Only show errors to the user in non-silent mode
        await globalState.showMessage(
          title: appLocalizations.tip,
          message: TextSpan(text: e.toString()),
        );
      }
    }
    
    if (profile != null) {
      await addProfile(profile);
      commonPrint.log("Profile added successfully: ${profile.label}");
    }
  }

  addProfileFormFile() async {
    final platformFile = await globalState.safeRun(picker.pickerFile);
    final bytes = platformFile?.bytes;
    if (bytes == null) {
      return null;
    }
    if (!context.mounted) return;
    globalState.navigatorKey.currentState?.popUntil((route) => route.isFirst);
    toProfiles();
    final commonScaffoldState = globalState.homeScaffoldKey.currentState;
    if (commonScaffoldState?.mounted != true) return;
    try {
      final profile = await commonScaffoldState?.loadingRun<Profile?>(
        () async {
          await Future.delayed(const Duration(milliseconds: 300));
          try {
            // Check if bytes already have the encryption header
            if (EncryptionService.hasEncryptionHeader(bytes)) {
              commonPrint.log("Detected already encrypted profile, will decrypt before importing");
            }
            return await Profile.normal(label: platformFile?.name).saveFile(bytes);
          } catch (e) {
            commonPrint.log("Error importing profile: $e");
            rethrow;
          }
        },
        title: "${appLocalizations.add}${appLocalizations.profile}",
      );
      if (profile != null) {
        await addProfile(profile);
        commonPrint.log("Profile imported successfully: ${profile.label}");
      }
    } catch (e) {
      // Show user-friendly error message when import fails
      await globalState.showMessage(
        title: appLocalizations.tip,
        message: TextSpan(text: e.toString()),
      );
      commonPrint.log("Failed to import profile: $e");
    }
  }

  addProfileFormQrCode() async {
    final url = await globalState.safeRun(picker.pickerConfigQRCode);
    if (url == null) return;
    addProfileFormURL(url);
  }

  updateViewSize(Size size) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _ref.read(viewSizeProvider.notifier).value = size;
    });
  }

  setProvider(ExternalProvider? provider) {
    _ref.read(providersProvider.notifier).setProvider(provider);
  }

  List<Proxy> _sortOfName(List<Proxy> proxies) {
    return List.of(proxies)
      ..sort(
        (a, b) => other.sortByChar(
          other.getPinyin(a.name),
          other.getPinyin(b.name),
        ),
      );
  }

  List<Proxy> _sortOfDelay({
    required List<Proxy> proxies,
    String? testUrl,
  }) {
    return List.of(proxies)
      ..sort(
        (a, b) {
          final aDelay =
              _ref.read(getDelayProvider(proxyName: a.name, testUrl: testUrl));
          final bDelay =
              _ref.read(getDelayProvider(proxyName: b.name, testUrl: testUrl));
          if (aDelay == null && bDelay == null) {
            return 0;
          }
          if (aDelay == null || aDelay == -1) {
            return 1;
          }
          if (bDelay == null || bDelay == -1) {
            return -1;
          }
          return aDelay.compareTo(bDelay);
        },
      );
  }

  List<Proxy> getSortProxies(List<Proxy> proxies, [String? url]) {
    return switch (_ref.read(proxiesStyleSettingProvider).sortType) {
      ProxiesSortType.none => proxies,
      ProxiesSortType.delay => _sortOfDelay(
          proxies: proxies,
          testUrl: url,
        ),
      ProxiesSortType.name => _sortOfName(proxies),
    };
  }

  clearEffect(String profileId) async {
    final profilePath = await appPath.getProfilePath(profileId);
    final providersPath = await appPath.getProvidersPath(profileId);
    return await Isolate.run(() async {
      if (profilePath != null) {
        final profileFile = File(profilePath);
        final isExists = await profileFile.exists();
        if (isExists) {
          profileFile.delete(recursive: true);
        }
      }
      if (providersPath != null) {
        final providersFileDir = File(providersPath);
        final isExists = await providersFileDir.exists();
        if (isExists) {
          providersFileDir.delete(recursive: true);
        }
      }
    });
  }

  updateTun() {
    _ref.read(patchClashConfigProvider.notifier).updateState(
          (state) => state.copyWith.tun(enable: !state.tun.enable),
        );
  }

  updateSystemProxy() {
    _ref.read(networkSettingProvider.notifier).updateState(
          (state) => state.copyWith(
            systemProxy: !state.systemProxy,
          ),
        );
  }

  updateStart() {
    updateStatus(!_ref.read(runTimeProvider.notifier).isStart);
  }

  updateCurrentSelectedMap(String groupName, String proxyName) {
    final currentProfile = _ref.read(currentProfileProvider);
    if (currentProfile != null &&
        currentProfile.selectedMap[groupName] != proxyName) {
      final SelectedMap selectedMap = Map.from(
        currentProfile.selectedMap,
      )..[groupName] = proxyName;
      _ref.read(profilesProvider.notifier).setProfile(
            currentProfile.copyWith(
              selectedMap: selectedMap,
            ),
          );
    }
  }

  updateCurrentUnfoldSet(Set<String> value) {
    final currentProfile = _ref.read(currentProfileProvider);
    if (currentProfile == null) {
      return;
    }
    _ref.read(profilesProvider.notifier).setProfile(
          currentProfile.copyWith(
            unfoldSet: value,
          ),
        );
  }

  changeMode(Mode mode) {
    _ref.read(patchClashConfigProvider.notifier).updateState(
          (state) => state.copyWith(mode: mode),
        );
    if (mode == Mode.global) {
      updateCurrentGroupName(GroupName.GLOBAL.name);
    }
    addCheckIpNumDebounce();
  }

  updateAutoLaunch() {
    _ref.read(appSettingProvider.notifier).updateState(
          (state) => state.copyWith(
            autoLaunch: !state.autoLaunch,
          ),
        );
  }

  updateVisible() async {
    final visible = await window?.isVisible;
    if (visible != null && !visible) {
      window?.show();
    } else {
      window?.hide();
    }
  }

  updateMode() {
    _ref.read(patchClashConfigProvider.notifier).updateState(
      (state) {
        final index = Mode.values.indexWhere((item) => item == state.mode);
        if (index == -1) {
          return null;
        }
        final nextIndex = index + 1 > Mode.values.length - 1 ? 0 : index + 1;
        return state.copyWith(
          mode: Mode.values[nextIndex],
        );
      },
    );
  }

  handleAddOrUpdate(WidgetRef ref, [Rule? rule]) async {
    final res = await globalState.showCommonDialog<Rule>(
      child: AddRuleDialog(
        rule: rule,
        snippet: ref.read(
          profileOverrideStateProvider.select(
            (state) => state.snippet!,
          ),
        ),
      ),
    );
    if (res == null) {
      return;
    }
    ref.read(profileOverrideStateProvider.notifier).updateState(
      (state) {
        final model = state.copyWith.overrideData!(
          rule: state.overrideData!.rule.updateRules(
            (rules) {
              final index = rules.indexWhere((item) => item.id == res.id);
              if (index == -1) {
                return List.from([res, ...rules]);
              }
              return List.from(rules)..[index] = res;
            },
          ),
        );
        return model;
      },
    );
  }

  Future<bool> exportLogs() async {
    final logsRaw = _ref.read(logsProvider).list.map(
          (item) => item.toString(),
        );
    final data = await Isolate.run<List<int>>(() async {
      final logsRawString = logsRaw.join("\n");
      return utf8.encode(logsRawString);
    });
    return await picker.saveFile(
          other.logFile,
          Uint8List.fromList(data),
        ) !=
        null;
  }

  Future<List<int>> backupData() async {
    final homeDirPath = await appPath.homeDirPath;
    final profilesPath = await appPath.profilesPath;
    final configJson = globalState.config.toJson();
    return Isolate.run<List<int>>(() async {
      final archive = Archive();
      archive.add("config.json", configJson);
      await archive.addDirectoryToArchive(profilesPath, homeDirPath);
      final zipEncoder = ZipEncoder();
      return zipEncoder.encode(archive) ?? [];
    });
  }

  updateTray([bool focus = false]) async {
    tray.update(
      trayState: _ref.read(trayStateProvider),
    );
  }

  recoveryData(
    List<int> data,
    RecoveryOption recoveryOption,
  ) async {
    final archive = await Isolate.run<Archive>(() {
      final zipDecoder = ZipDecoder();
      return zipDecoder.decodeBytes(data);
    });
    final homeDirPath = await appPath.homeDirPath;
    final configs =
        archive.files.where((item) => item.name.endsWith(".json")).toList();
    final profiles =
        archive.files.where((item) => !item.name.endsWith(".json"));
    final configIndex =
        configs.indexWhere((config) => config.name == "config.json");
    if (configIndex == -1) throw "invalid backup file";
    final configFile = configs[configIndex];
    var tempConfig = Config.compatibleFromJson(
      json.decode(
        utf8.decode(configFile.content),
      ),
    );
    for (final profile in profiles) {
      final filePath = join(homeDirPath, profile.name);
      final file = File(filePath);
      await file.create(recursive: true);
      await file.writeAsBytes(profile.content);
    }
    final clashConfigIndex =
        configs.indexWhere((config) => config.name == "clashConfig.json");
    if (clashConfigIndex != -1) {
      final clashConfigFile = configs[clashConfigIndex];
      tempConfig = tempConfig.copyWith(
        patchClashConfig: ClashConfig.fromJson(
          json.decode(
            utf8.decode(
              clashConfigFile.content,
            ),
          ),
        ),
      );
    }
    _recovery(
      tempConfig,
      recoveryOption,
    );
  }

  _recovery(Config config, RecoveryOption recoveryOption) {
    final profiles = config.profiles;
    for (final profile in profiles) {
      _ref.read(profilesProvider.notifier).setProfile(profile);
    }
    final onlyProfiles = recoveryOption == RecoveryOption.onlyProfiles;
    if (onlyProfiles) {
      final currentProfile = _ref.read(currentProfileProvider);
      if (currentProfile != null) {
        _ref.read(currentProfileIdProvider.notifier).value = profiles.first.id;
      }
      return;
    }
    _ref.read(patchClashConfigProvider.notifier).value =
        config.patchClashConfig;
    _ref.read(appSettingProvider.notifier).value = config.appSetting;
    _ref.read(currentProfileIdProvider.notifier).value =
        config.currentProfileId;
    _ref.read(appDAVSettingProvider.notifier).value = config.dav;
    _ref.read(themeSettingProvider.notifier).value = config.themeProps;
    _ref.read(windowSettingProvider.notifier).value = config.windowProps;
    _ref.read(vpnSettingProvider.notifier).value = config.vpnProps;
    _ref.read(proxiesStyleSettingProvider.notifier).value = config.proxiesStyle;
    _ref.read(overrideDnsProvider.notifier).value = config.overrideDns;
    _ref.read(networkSettingProvider.notifier).value = config.networkProps;
    _ref.read(hotKeyActionsProvider.notifier).value = config.hotKeyActions;
  }
}
