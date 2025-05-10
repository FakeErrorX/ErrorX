import 'dart:async';
import 'package:flutter/material.dart';
import 'package:errorx/common/common.dart';
import 'package:errorx/l10n/l10n.dart';
import 'package:errorx/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:errorx/services/api_service.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'dart:math' as math;

class AccountFragment extends ConsumerStatefulWidget {
  const AccountFragment({Key? key}) : super(key: key);

  @override
  _AccountFragmentState createState() => _AccountFragmentState();
}

class _AccountFragmentState extends ConsumerState<AccountFragment> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _rotateAnimation;
  Timer? _refreshTimer;
  final ApiService _apiService = ApiService();
  
  // License information
  String _licenseKey = "";
  String _subscriptionType = "";
  DateTime? _startDate;
  DateTime? _expiryDate;
  String _remainingTime = "Loading...";
  String _platform = "";
  bool _isLoading = true;
  bool _hasError = false;
  String _errorMessage = "";
  bool _isLicenseKeyVisible = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutCubic),
      ),
    );
    
    _rotateAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.5, curve: Curves.easeOutBack),
      ),
    );
    
    _loadLicenseInfo();
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
    
    _animationController.forward();
  }
  
  Future<void> _loadLicenseInfo() async {
    try {
      setState(() {
        _isLoading = true;
        _hasError = false;
      });
      
      // Request license status
      _apiService.requestLicenseStatus();
      
      // Wait a moment for the response
      await Future.delayed(const Duration(milliseconds: 500));
      
      // Get license data from API service
      final licenseStatus = _apiService.getLicenseStatus();
      final storedLicenseKey = _apiService.getLicenseKey() ?? await _apiService.getStoredLicenseKey();
      
      if (licenseStatus == null) {
        setState(() {
          _hasError = true;
          _errorMessage = "Failed to retrieve license information";
          _isLoading = false;
        });
        return;
      }
      
      if (licenseStatus['status'] != 'success') {
        setState(() {
          _hasError = true;
          _errorMessage = licenseStatus['message'] ?? "Invalid license status";
          _isLoading = false;
        });
        return;
      }
      
      final data = licenseStatus['data'];
      if (data == null) {
        setState(() {
          _hasError = true;
          _errorMessage = "No license data available";
          _isLoading = false;
        });
        return;
      }
      
      // License Key
      _licenseKey = storedLicenseKey ?? data['license_key'] ?? "Unknown";
      
      // Parse subscription information
      final subscriptionInfo = data['subscription_info'];
      if (subscriptionInfo != null) {
        _subscriptionType = subscriptionInfo['name'] ?? subscriptionInfo['type'] ?? "Unknown";
        
        // Parse dates
        try {
          if (subscriptionInfo['start_time'] != null) {
            _startDate = DateTime.parse(subscriptionInfo['start_time']);
          }
          
          if (subscriptionInfo['expiry_time'] != null) {
            _expiryDate = DateTime.parse(subscriptionInfo['expiry_time']);
          }
        } catch (e) {
          commonPrint.log('Error parsing dates: $e');
        }
      }
      
      // Platform
      _platform = data['allowed_platform'] ?? "Unknown";
      
      // Update remaining time
      _updateRemainingTime();
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      commonPrint.log('Error loading license info: $e');
      setState(() {
        _hasError = true;
        _errorMessage = "Failed to load license information: $e";
        _isLoading = false;
      });
    }
  }
  
  void _updateRemainingTime() {
    if (_expiryDate == null) {
      setState(() {
        _remainingTime = "Unknown";
      });
      return;
    }
    
    // Get current time in UTC
    final now = DateTime.now().toUtc();
    if (_expiryDate!.isAfter(now)) {
      final difference = _expiryDate!.difference(now);
      setState(() {
        _remainingTime = "${difference.inDays}d ${difference.inHours % 24}h ${difference.inMinutes % 60}m ${difference.inSeconds % 60}s";
      });
    } else {
      setState(() {
        _remainingTime = "Expired";
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }
    
    if (_hasError) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
            const SizedBox(height: 16),
            Text(
              'Error Loading License Information',
              style: theme.textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32.0),
              child: Text(
                _errorMessage,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _loadLicenseInfo,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with account info card
            FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, -0.2),
                  end: Offset.zero,
                ).animate(_slideAnimation),
                child: _buildAccountCard(theme),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // License Information header with animated icon
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Color(0xFF1A1A1A),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.verified_user_rounded,
                    color: Colors.white,
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    "License Information",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // License details cards
            ..._buildInfoCards(theme),
          ],
        ),
      ),
    );
  }
  
  Widget _buildAccountCard(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.12),
            blurRadius: 20,
            spreadRadius: 0,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Stack(
            children: [
              // Gradient background with pattern
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6C5CE7),
                        Color(0xFF5758BB),
                        Color(0xFF543BD4),
                      ],
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Account Info section
                    Row(
                      children: [
                        // Animated shield icon
                        AnimatedBuilder(
                          animation: _rotateAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: 0.9 + (_rotateAnimation.value * 0.1),
                              child: child,
                            );
                          },
                          child: Container(
                            width: 70,
                            height: 70,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withOpacity(0.25),
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.2),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.shield,
                                color: Colors.white,
                                size: 36,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ErrorX",
                                style: TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(30),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.2),
                                    width: 1,
                                  ),
                                ),
                                child: Text(
                                  "$_subscriptionType Subscription",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Decorative elements (circles) overlaid on the background
              Positioned.fill(
                child: IgnorePointer(
                  child: _buildDecorativeElements(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDecorativeElements() {
    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned(
            top: -20,
            right: -20,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            left: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            top: 50,
            left: 100,
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildInfoCards(ThemeData theme) {
    // Use a date format that displays in local time with timezone
    final dateFormat = DateFormat('MMM dd, yyyy h:mm:ss a');
    
    // Function to format UTC date to local time
    String formatLocalTime(DateTime? utcDate) {
      if (utcDate == null) return "Unknown";
      
      // Convert UTC time to local time
      final localDate = utcDate.toLocal();
      
      // Format without timezone name
      return dateFormat.format(localDate);
    }
    
    final items = [
      _LicenseInfoItem(
        icon: Icons.key_rounded,
        iconColor: Colors.orange,
        title: "License Key",
        value: _licenseKey,
        index: 0,
        animationController: _animationController,
        isSensitive: true,
        isVisible: _isLicenseKeyVisible,
        onToggleVisibility: () {
          setState(() {
            _isLicenseKeyVisible = !_isLicenseKeyVisible;
          });
        },
      ),
      _LicenseInfoItem(
        icon: Icons.workspace_premium_rounded,
        iconColor: Colors.purple,
        title: "Subscription Type",
        value: _subscriptionType,
        index: 1,
        animationController: _animationController,
      ),
      _LicenseInfoItem(
        icon: Icons.play_circle_rounded,
        iconColor: Colors.green,
        title: "Start Date",
        value: formatLocalTime(_startDate),
        index: 2,
        animationController: _animationController,
      ),
      _LicenseInfoItem(
        icon: Icons.event_rounded,
        iconColor: Colors.red,
        title: "Expiry Date",
        value: formatLocalTime(_expiryDate),
        index: 3,
        animationController: _animationController,
      ),
      _LicenseInfoItem(
        icon: Icons.hourglass_top_rounded,
        iconColor: Colors.blue,
        title: "Time Remaining",
        value: _remainingTime,
        index: 4,
        animationController: _animationController,
        isLive: true,
      ),
      _LicenseInfoItem(
        icon: Icons.laptop_rounded,
        iconColor: Colors.teal,
        title: "Platform",
        value: _platform,
        index: 5,
        animationController: _animationController,
      ),
    ];
    
    return items;
  }
}

class _LicenseInfoItem extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final int index;
  final AnimationController animationController;
  final bool isLive;
  final bool isSensitive;
  final bool isVisible;
  final VoidCallback? onToggleVisibility;
  
  const _LicenseInfoItem({
    Key? key,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.index,
    required this.animationController,
    this.isLive = false,
    this.isSensitive = false,
    this.isVisible = true,
    this.onToggleVisibility,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Staggered animation
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.1 + (index * 0.05),
        0.7 + (index * 0.05),
        curve: Curves.easeOutCubic,
      ),
    );
    
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.3, 0),
      end: Offset.zero,
    ).animate(animation);
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(animation);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16.0),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: Container(
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 2),
                ),
              ],
              border: Border.all(
                color: theme.colorScheme.outline.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                children: [
                  // Icon container
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: iconColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 16),
                  
                  // Title and value
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.7),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: SelectableText(
                                isSensitive && !isVisible ? "••••••••••••••••" : value,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.2,
                                ),
                              ),
                            ),
                            if (isLive)
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: Colors.green,
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.green.withOpacity(0.5),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            if (isSensitive && onToggleVisibility != null)
                              IconButton(
                                icon: Icon(
                                  isVisible
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: theme.colorScheme.primary.withOpacity(0.7),
                                  size: 20,
                                ),
                                onPressed: onToggleVisibility,
                                tooltip: isVisible ? 'Hide license key' : 'Show license key',
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                splashRadius: 18,
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
} 