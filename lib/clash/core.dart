import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:errorx/clash/clash.dart';
import 'package:errorx/clash/interface.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/models/models.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';

class ClashCore {
  static ClashCore? _instance;
  late ClashHandlerInterface clashInterface;

  ClashCore._internal() {
    if (Platform.isAndroid) {
      clashInterface = clashLib!;
    } else {
      clashInterface = clashService!;
    }
  }

  factory ClashCore() {
    _instance ??= ClashCore._internal();
    return _instance!;
  }

  Future<bool> preload() {
    return clashInterface.preload();
  }

  static Future<void> initGeo() async {
    final homePath = await appPath.homeDirPath;
    final homeDir = Directory(homePath);
    final isExists = await homeDir.exists();
    if (!isExists) {
      await homeDir.create(recursive: true);
    }
    const geoFileNameList = [
      mmdbFileName,
      geoIpFileName,
      geoSiteFileName,
      asnFileName,
    ];
    try {
      for (final geoFileName in geoFileNameList) {
        final geoFile = File(
          join(homePath, geoFileName),
        );
        final isExists = await geoFile.exists();
        if (isExists) {
          continue;
        }
        final data = await rootBundle.load('assets/data/$geoFileName');
        List<int> bytes = data.buffer.asUint8List();
        await geoFile.writeAsBytes(bytes, flush: true);
      }
    } catch (e) {
      exit(0);
    }
  }

  Future<bool> init() async {
    await initGeo();
    final homeDirPath = await appPath.homeDirPath;
    return await clashInterface.init(homeDirPath);
  }

  Future<bool> initEncryption(String encryptionKey) async {
    return await clashInterface.initEncryption(encryptionKey);
  }

  Future<bool> setState(CoreState state) async {
    return await clashInterface.setState(state);
  }

  shutdown() async {
    await clashInterface.shutdown();
  }

  FutureOr<bool> get isInit => clashInterface.isInit;

  FutureOr<String> validateConfig(String data) {
    return clashInterface.validateConfig(data);
  }

  Future<String> updateConfig(UpdateConfigParams updateConfigParams) async {
    return await clashInterface.updateConfig(updateConfigParams);
  }

  Future<List<Group>> getProxiesGroups() async {
    final proxiesRawString = await clashInterface.getProxies();
    return Isolate.run<List<Group>>(() {
      try {
        if (proxiesRawString.isEmpty) return <Group>[];
        
        final dynamic decodedJson = json.decode(proxiesRawString);
        if (decodedJson == null) return <Group>[];
        
        final proxies = decodedJson as Map<String, dynamic>;
        if (proxies.isEmpty) return <Group>[];
        
        // Check if GLOBAL proxy exists
        final globalProxy = proxies[UsedProxy.GLOBAL.name];
        if (globalProxy == null) return <Group>[];
        
        final globalAll = globalProxy["all"];
        if (globalAll == null || globalAll is! List) return <Group>[];
        
        final groupNames = [
          UsedProxy.GLOBAL.name,
          ...globalAll.where((e) {
            if (e == null) return false;
            final proxy = proxies[e];
            if (proxy == null || proxy is! Map) return false;
            final proxyType = proxy['type'];
            return proxyType != null && GroupTypeExtension.valueList.contains(proxyType);
          })
        ];
        
        final groupsRaw = groupNames.map((groupName) {
          final group = Map<String, dynamic>.from(proxies[groupName] ?? {});
          final groupAll = group["all"];
          if (groupAll is List) {
            group["all"] = groupAll
                .map((name) => proxies[name])
                .where((proxy) => proxy != null)
                .toList();
          } else {
            group["all"] = <dynamic>[];
          }
          return group;
        }).toList();
        
        return groupsRaw
            .map((e) {
              try {
                return Group.fromJson(e);
              } catch (parseError) {
                // Skip malformed group data
                return null;
              }
            })
            .where((group) => group != null)
            .cast<Group>()
            .toList();
      } catch (e) {
        // Return empty list on any parsing error
        return <Group>[];
      }
    });
  }

  FutureOr<String> changeProxy(ChangeProxyParams changeProxyParams) async {
    return await clashInterface.changeProxy(changeProxyParams);
  }

  Future<List<Connection>> getConnections() async {
    final res = await clashInterface.getConnections();
    final connectionsData = json.decode(res) as Map;
    final connectionsRaw = connectionsData['connections'] as List? ?? [];
    return connectionsRaw.map((e) => Connection.fromJson(e)).toList();
  }

  closeConnection(String id) {
    clashInterface.closeConnection(id);
  }

  closeConnections() {
    clashInterface.closeConnections();
  }

  Future<List<ExternalProvider>> getExternalProviders() async {
    final externalProvidersRawString =
        await clashInterface.getExternalProviders();
    if (externalProvidersRawString.isEmpty) {
      return [];
    }
    return Isolate.run<List<ExternalProvider>>(
      () {
        final externalProviders =
            (json.decode(externalProvidersRawString) as List<dynamic>)
                .map(
                  (item) => ExternalProvider.fromJson(item),
                )
                .toList();
        return externalProviders;
      },
    );
  }

  Future<ExternalProvider?> getExternalProvider(
      String externalProviderName) async {
    final externalProvidersRawString =
        await clashInterface.getExternalProvider(externalProviderName);
    if (externalProvidersRawString.isEmpty) {
      return null;
    }
    if (externalProvidersRawString.isEmpty) {
      return null;
    }
    return ExternalProvider.fromJson(json.decode(externalProvidersRawString));
  }

  Future<String> updateGeoData(UpdateGeoDataParams params) {
    return clashInterface.updateGeoData(params);
  }

  Future<String> sideLoadExternalProvider({
    required String providerName,
    required String data,
  }) {
    return clashInterface.sideLoadExternalProvider(
        providerName: providerName, data: data);
  }

  Future<String> updateExternalProvider({
    required String providerName,
  }) async {
    return clashInterface.updateExternalProvider(providerName);
  }

  startListener() async {
    await clashInterface.startListener();
  }

  stopListener() async {
    await clashInterface.stopListener();
  }

  Future<Delay> getDelay(String url, String proxyName) async {
    final data = await clashInterface.asyncTestDelay(url, proxyName);
    return Delay.fromJson(json.decode(data));
  }

  Future<Traffic> getTraffic() async {
    final trafficString = await clashInterface.getTraffic();
    if (trafficString.isEmpty) {
      return Traffic();
    }
    return Traffic.fromMap(json.decode(trafficString));
  }

  Future<IpInfo?> getCountryCode(String ip) async {
    final countryCode = await clashInterface.getCountryCode(ip);
    if (countryCode.isEmpty) {
      return null;
    }
    return IpInfo(
      ip: ip,
      countryCode: countryCode,
    );
  }

  Future<Traffic> getTotalTraffic() async {
    final totalTrafficString = await clashInterface.getTotalTraffic();
    if (totalTrafficString.isEmpty) {
      return Traffic();
    }
    return Traffic.fromMap(json.decode(totalTrafficString));
  }

  Future<int> getMemory() async {
    final value = await clashInterface.getMemory();
    if (value.isEmpty) {
      return 0;
    }
    return int.parse(value);
  }

  Future<ClashConfigSnippet?> getProfile(String id) async {
    final res = await clashInterface.getProfile(id);
    if (res.isEmpty) {
      return null;
    }
    return Isolate.run(() => ClashConfigSnippet.fromJson(json.decode(res)));
  }

  resetTraffic() {
    clashInterface.resetTraffic();
  }

  startLog() {
    clashInterface.startLog();
  }

  stopLog() {
    clashInterface.stopLog();
  }

  requestGc() {
    clashInterface.forceGc();
  }

  destroy() async {
    await clashInterface.destroy();
  }
}

final clashCore = ClashCore();
