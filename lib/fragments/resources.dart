import 'dart:io';

import 'package:errorx/clash/clash.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/models/models.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' hide context;

@immutable
class GeoItem {
  final String label;
  final String key;
  final String fileName;
  final IconData icon;
  final Color color;

  const GeoItem({
    required this.label,
    required this.key,
    required this.fileName,
    required this.icon,
    required this.color,
  });
}

class Resources extends StatelessWidget {
  const Resources({super.key});

  @override
  Widget build(BuildContext context) {
    final geoItems = <GeoItem>[
      GeoItem(
        label: "GeoIp",
        fileName: geoIpFileName,
        key: "geoip",
        icon: Icons.public_rounded,
        color: Colors.blue.shade700,
      ),
      GeoItem(
        label: "GeoSite",
        fileName: geoSiteFileName,
        key: "geosite",
        icon: Icons.language_rounded,
        color: Colors.green.shade700,
      ),
      GeoItem(
        label: "MMDB",
        fileName: mmdbFileName,
        key: "mmdb",
        icon: Icons.storage_rounded,
        color: Colors.orange.shade700,
      ),
      GeoItem(
        label: "ASN",
        fileName: asnFileName,
        key: "asn",
        icon: Icons.account_tree_rounded,
        color: Colors.purple.shade700,
      ),
    ];

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header section
          Padding(
            padding: const EdgeInsets.only(bottom: 16.0, left: 4.0),
            child: Text(
              'Resources Management',
              style: context.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                letterSpacing: 0.3,
              ),
            ),
          ),
          
          // Description text
          Padding(
            padding: const EdgeInsets.only(bottom: 24.0, left: 4.0, right: 4.0),
            child: Text(
              'Manage your geo data resources used by the application. You can update and customize URLs for each resource.',
              style: context.textTheme.bodyMedium?.copyWith(
                color: context.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          
          // Resource cards list
          Expanded(
            child: ListView.builder(
              itemCount: geoItems.length,
              itemBuilder: (context, index) {
                final geoItem = geoItems[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16.0),
                  child: GeoDataCard(
                    geoItem: geoItem,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class GeoDataCard extends StatefulWidget {
  final GeoItem geoItem;

  const GeoDataCard({
    super.key,
    required this.geoItem,
  });

  @override
  State<GeoDataCard> createState() => _GeoDataCardState();
}

class _GeoDataCardState extends State<GeoDataCard> {
  final isUpdating = ValueNotifier<bool>(false);

  GeoItem get geoItem => widget.geoItem;

  _updateUrl(String url, WidgetRef ref) async {
    final defaultMap = defaultGeoXUrl.toJson();
    final newUrl = await globalState.showCommonDialog<String>(
      child: UpdateGeoUrlFormDialog(
        title: geoItem.label,
        url: url,
        defaultValue: defaultMap[geoItem.key],
      ),
    );
    if (newUrl != null && newUrl != url && mounted) {
      try {
        if (!newUrl.isUrl) {
          throw "Invalid url";
        }
        ref.read(patchClashConfigProvider.notifier).updateState((state) {
          final map = state.geoXUrl.toJson();
          map[geoItem.key] = newUrl;
          return state.copyWith(
            geoXUrl: GeoXUrl.fromJson(map),
          );
        });
      } catch (e) {
        globalState.showMessage(
          title: geoItem.label,
          message: TextSpan(
            text: e.toString(),
          ),
        );
      }
    }
  }

  Future<FileInfo> _getGeoFileLastModified(String fileName) async {
    final homePath = await appPath.homeDirPath;
    final file = File(join(homePath, fileName));
    final lastModified = await file.lastModified();
    final size = await file.length();
    return FileInfo(
      size: size,
      lastModified: lastModified,
    );
  }

  _handleUpdateGeoDataItem() async {
    await globalState.safeRun<void>(
      () async {
        await updateGeoDateItem();
      },
      silence: false,
    );
    setState(() {});
  }

  updateGeoDateItem() async {
    isUpdating.value = true;
    try {
      final message = await clashCore.updateGeoData(
        UpdateGeoDataParams(
          geoName: geoItem.fileName,
          geoType: geoItem.label,
        ),
      );
      if (message.isNotEmpty) throw message;
    } catch (e) {
      isUpdating.value = false;
      rethrow;
    }
    isUpdating.value = false;
    return null;
  }

  @override
  void dispose() {
    super.dispose();
    isUpdating.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        final url = ref.watch(
          patchClashConfigProvider
              .select((state) => state.geoXUrl.toJson()[geoItem.key]),
        );
        
        if (url == null) {
          return const SizedBox();
        }
        
        return Container(
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: context.colorScheme.outline.withOpacity(0.1),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header row with icon, title, and action button
                Row(
                  children: [
                    // Resource icon with colored background
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: geoItem.color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        geoItem.icon,
                        color: geoItem.color,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    
                    // Title
                    Expanded(
                      child: Text(
                        geoItem.label,
                        style: context.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ),
                    
                    // Update indicator
                    ValueListenableBuilder(
                      valueListenable: isUpdating,
                      builder: (_, isUpdating, ___) {
                        return FadeThroughBox(
                          child: isUpdating
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: geoItem.color,
                                  ),
                                )
                              : const SizedBox(),
                        );
                      },
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // URL display
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: context.colorScheme.surfaceVariant.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    url,
                    style: context.textTheme.bodySmall?.copyWith(
                      color: context.colorScheme.onSurfaceVariant,
                      fontFamily: 'monospace',
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                
                const SizedBox(height: 8),
                
                // File info
                FutureBuilder<FileInfo>(
                  future: _getGeoFileLastModified(geoItem.fileName),
                  builder: (_, snapshot) {
                    return SizedBox(
                      height: 20,
                      child: FadeThroughBox(
                        key: Key("fade_box_${geoItem.label}"),
                        child: snapshot.data == null
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                ),
                              )
                            : Row(
                                children: [
                                  Icon(
                                    Icons.access_time_rounded,
                                    size: 14,
                                    color: context.colorScheme.onSurfaceVariant,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    snapshot.data!.desc,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    );
                  },
                ),
                
                const SizedBox(height: 16),
                
                // Action buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    // Edit button
                    TextButton.icon(
                      onPressed: () => _updateUrl(url, ref),
                      icon: const Icon(Icons.edit_rounded, size: 18),
                      label: Text(appLocalizations.edit),
                      style: TextButton.styleFrom(
                        foregroundColor: geoItem.color,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                    const SizedBox(width: 8),
                    
                    // Sync button
                    ElevatedButton.icon(
                      onPressed: _handleUpdateGeoDataItem,
                      icon: const Icon(Icons.sync_rounded, size: 18),
                      label: Text(appLocalizations.sync),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: geoItem.color,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class UpdateGeoUrlFormDialog extends StatefulWidget {
  final String title;
  final String url;
  final String? defaultValue;

  const UpdateGeoUrlFormDialog(
      {super.key, required this.title, required this.url, this.defaultValue});

  @override
  State<UpdateGeoUrlFormDialog> createState() => _UpdateGeoUrlFormDialogState();
}

class _UpdateGeoUrlFormDialogState extends State<UpdateGeoUrlFormDialog> {
  late TextEditingController urlController;

  @override
  void initState() {
    super.initState();
    urlController = TextEditingController(text: widget.url);
  }

  _handleReset() async {
    if (widget.defaultValue == null) {
      return;
    }
    Navigator.of(context).pop<String>(widget.defaultValue);
  }

  _handleUpdate() async {
    final url = urlController.value.text;
    if (url.isEmpty) return;
    Navigator.of(context).pop<String>(url);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: widget.title,
      actions: [
        if (widget.defaultValue != null &&
            urlController.value.text != widget.defaultValue) ...[
          TextButton(
            onPressed: _handleReset,
            child: Text(appLocalizations.reset),
          ),
          const SizedBox(
            width: 4,
          ),
        ],
        TextButton(
          onPressed: _handleUpdate,
          child: Text(appLocalizations.submit),
        )
      ],
      child: Wrap(
        runSpacing: 16,
        children: [
          TextField(
            maxLines: 5,
            minLines: 1,
            controller: urlController,
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              hintText: 'Enter resource URL',
              prefixIcon: const Icon(Icons.link_rounded),
              filled: true,
              fillColor: context.colorScheme.surfaceVariant.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }
}
