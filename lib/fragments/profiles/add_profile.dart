import 'package:errorx/common/common.dart';
import 'package:errorx/pages/scan.dart';
import 'package:errorx/state.dart';
import 'package:errorx/widgets/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AddProfile extends StatefulWidget {
  final BuildContext context;

  const AddProfile({
    super.key,
    required this.context,
  });

  @override
  State<AddProfile> createState() => _AddProfileState();
}

class _AddProfileState extends State<AddProfile> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _animationController.forward();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  _handleAddProfileFormFile() async {
    HapticFeedback.mediumImpact();
    globalState.appController.addProfileFormFile();
  }

  _handleAddProfileFormURL(String url) async {
    globalState.appController.addProfileFormURL(url);
  }

  _handleAutoDownloadErrorX() async {
    HapticFeedback.mediumImpact();
    const url = 'https://raw.githubusercontent.com/FakeErrorX/ConfigX/refs/heads/master/ErrorX.yaml';
    globalState.appController.addProfileFormURL(url, name: "ErrorX");
  }

  _toScan() async {
    HapticFeedback.mediumImpact();
    if (system.isDesktop) {
      globalState.appController.addProfileFormQrCode();
      return;
    }
    final url = await BaseNavigator.push(
      widget.context,
      const ScanPage(),
    );
    if (url != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleAddProfileFormURL(url);
      });
    }
  }

  _toAdd() async {
    HapticFeedback.mediumImpact();
    final url = await globalState.showCommonDialog<String>(
      child: const URLFormDialog(),
    );
    if (url != null) {
      _handleAddProfileFormURL(url);
    }
  }

  Widget _buildProfileCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
    int index = 0,
  }) {
    // Calculate proper animation timing based on index
    final double start = 0.1 * index;
    final double end = 0.2 + (0.1 * index);
    
    final animation = CurvedAnimation(
      parent: _animationController,
      curve: Interval(start, end, curve: Curves.easeOutBack),
    );
    
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0.3, 0),
        end: Offset.zero,
      ).animate(animation),
      child: FadeTransition(
        opacity: Tween<double>(begin: 0, end: 1).animate(animation),
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          decoration: BoxDecoration(
            color: context.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: context.colorScheme.shadow.withOpacity(0.08),
                blurRadius: 10,
                spreadRadius: 0,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: onTap,
              splashColor: color.withOpacity(0.1),
              highlightColor: color.withOpacity(0.05),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Hero(
                      tag: 'profile_icon_$index',
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 24,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: context.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            subtitle,
                            style: context.textTheme.bodyMedium?.copyWith(
                              color: context.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 16,
                      color: color.withOpacity(0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Header animation
    final headerAnimation = CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.3, curve: Curves.easeOutQuint),
    );
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            context.colorScheme.background,
            context.colorScheme.surface,
          ],
          stops: const [0.0, 1.0],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.symmetric(vertical: 16),
        children: [
          // Animated header
          FadeTransition(
            opacity: Tween<double>(begin: 0, end: 1).animate(headerAnimation),
            child: SlideTransition(
              position: Tween<Offset>(begin: const Offset(0, -0.2), end: Offset.zero).animate(headerAnimation),
              child: Container(
                margin: const EdgeInsets.only(bottom: 24, left: 16, right: 16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: context.colorScheme.primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Icon(
                      Icons.add_circle_outline_rounded,
                      size: 48,
                      color: context.colorScheme.primary,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      "Add Profile",
                      style: context.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: context.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Choose a method to add a new profile",
                      textAlign: TextAlign.center,
                      style: context.textTheme.bodyMedium?.copyWith(
                        color: context.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          
          // ErrorX auto-download option
          _buildProfileCard(
            title: "Default profile",
            subtitle: "Download Default profile",
            icon: Icons.download_rounded,
            color: Colors.red.shade600,
            index: 0,
            onTap: _handleAutoDownloadErrorX,
          ),
          
          // QR Code option
          _buildProfileCard(
            title: appLocalizations.qrcode,
            subtitle: appLocalizations.qrcodeDesc,
            icon: Icons.qr_code_scanner_rounded,
            color: Colors.purple.shade600,
            index: 1,
            onTap: _toScan,
          ),
          
          // File option
          _buildProfileCard(
            title: appLocalizations.file,
            subtitle: appLocalizations.fileDesc,
            icon: Icons.file_present_rounded,
            color: Colors.blue.shade600,
            index: 2,
            onTap: _handleAddProfileFormFile,
          ),
          
          // URL option
          _buildProfileCard(
            title: appLocalizations.url,
            subtitle: appLocalizations.urlDesc,
            icon: Icons.link_rounded,
            color: Colors.green.shade600,
            index: 3,
            onTap: _toAdd,
          ),
        ],
      ),
    );
  }
}

class URLFormDialog extends StatefulWidget {
  const URLFormDialog({super.key});

  @override
  State<URLFormDialog> createState() => _URLFormDialogState();
}

class _URLFormDialogState extends State<URLFormDialog> {
  final urlController = TextEditingController();

  _handleAddProfileFormURL() async {
    final url = urlController.value.text;
    if (url.isEmpty) return;
    Navigator.of(context).pop<String>(url);
  }

  @override
  Widget build(BuildContext context) {
    return CommonDialog(
      title: appLocalizations.importFromURL,
      actions: [
        TextButton(
          onPressed: _handleAddProfileFormURL,
          child: Text(appLocalizations.submit),
        )
      ],
      child: SizedBox(
        width: 300,
        child: Wrap(
          runSpacing: 16,
          children: [
            TextField(
              maxLines: 5,
              minLines: 1,
              controller: urlController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                  borderSide: BorderSide(
                    color: context.colorScheme.primary,
                    width: 2,
                  ),
                ),
                prefixIcon: Icon(
                  Icons.link_rounded,
                  color: context.colorScheme.primary,
                ),
                labelText: appLocalizations.url,
                hintText: "https://",
                filled: true,
                fillColor: context.colorScheme.surfaceVariant.withOpacity(0.2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
