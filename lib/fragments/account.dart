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

class _AccountFragmentState extends ConsumerState<AccountFragment> with TickerProviderStateMixin {
  late AnimationController _mainAnimationController;
  late AnimationController _pulseController;
  late AnimationController _shimmerController;
  
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _shimmerAnimation;
  
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
    _initializeAnimations();
    _loadLicenseInfo();
    
    _refreshTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      _updateRemainingTime();
    });
  }
  
  void _initializeAnimations() {
    _mainAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    )..repeat(reverse: true);
    
    _shimmerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.6, curve: Curves.easeOutCubic),
      ),
    );
    
    _slideAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.2, 0.8, curve: Curves.easeOutBack),
      ),
    );
    
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _mainAnimationController,
        curve: const Interval(0.0, 0.5, curve: Curves.elasticOut),
      ),
    );
    
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(_pulseController);
    _shimmerAnimation = Tween<double>(begin: -1.0, end: 2.0).animate(_shimmerController);
    
    _mainAnimationController.forward();
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
    _mainAnimationController.dispose();
    _pulseController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (_isLoading) {
      return _buildLoadingScreen(theme);
    }
    
    if (_hasError) {
      return _buildErrorScreen(theme);
    }
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            theme.colorScheme.surface,
            theme.colorScheme.surface.withOpacity(0.95),
          ],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Premium Header
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(_slideAnimation),
                  child: _buildPremiumHeader(theme),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // License Information Section
              ScaleTransition(
                scale: _scaleAnimation,
                child: _buildLicenseSection(theme),
              ),
              
              const SizedBox(height: 24),
              
              // License details cards
              ..._buildPremiumInfoCards(theme),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildLoadingScreen(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _pulseAnimation.value,
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        theme.colorScheme.primary,
                        theme.colorScheme.primary.withOpacity(0.7),
                      ],
                    ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.3),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: const Icon(
                    Icons.shield,
                    color: Colors.white,
                    size: 40,
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Loading License Information',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Please wait while we verify your subscription',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildErrorScreen(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.red.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 48,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Connection Error',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32.0),
            child: Text(
              _errorMessage,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurface.withOpacity(0.7),
              ),
            ),
          ),
          const SizedBox(height: 32),
          _buildRetryButton(theme),
        ],
      ),
    );
  }
  
  Widget _buildRetryButton(ThemeData theme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _loadLicenseInfo,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.refresh_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  'Retry',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildPremiumHeader(ThemeData theme) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 25,
            spreadRadius: 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
          child: Stack(
            children: [
              // Premium gradient background
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF667eea),
                        const Color(0xFF764ba2),
                        const Color(0xFFf093fb),
                        const Color(0xFFf5576c),
                      ],
                      stops: const [0.0, 0.25, 0.75, 1.0],
                    ),
                  ),
                ),
              ),
              
              // Content
              Padding(
                padding: const EdgeInsets.all(28.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Animated premium shield
                        AnimatedBuilder(
                          animation: _pulseAnimation,
                          builder: (context, child) {
                            return Transform.scale(
                              scale: _pulseAnimation.value,
                              child: Container(
                                width: 80,
                                height: 80,
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 15,
                                      spreadRadius: 0,
                                      offset: const Offset(0, 6),
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: Icon(
                                    Icons.workspace_premium_rounded,
                                    color: Colors.white,
                                    size: 40,
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(width: 24),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "ErrorX",
                                style: TextStyle(
                                  fontSize: 32,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 0.8,
                                  shadows: [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 2),
                                      blurRadius: 4,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: Colors.white.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified_rounded,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      "$_subscriptionType",
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
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
              
              // Premium decorative elements
              Positioned.fill(
                child: IgnorePointer(
                  child: _buildPremiumDecorations(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildPremiumDecorations() {
    return SizedBox.expand(
      child: Stack(
        children: [
          // Floating particles
          Positioned(
            top: 20,
            right: 30,
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shimmerAnimation.value * 20, 0),
                  child: Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.6),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          Positioned(
            bottom: 40,
            left: 20,
            child: AnimatedBuilder(
              animation: _shimmerAnimation,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(-_shimmerAnimation.value * 15, 0),
                  child: Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.4),
                      shape: BoxShape.circle,
                    ),
                  ),
                );
              },
            ),
          ),
          // Large decorative circles
          Positioned(
            top: -40,
            right: -40,
            child: Container(
              width: 160,
              height: 160,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -50,
            child: Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.05),
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildLicenseSection(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 22,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "License Information",
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  "Your subscription details and status",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  List<Widget> _buildPremiumInfoCards(ThemeData theme) {
    final dateFormat = DateFormat('MMM dd, yyyy h:mm:ss a');
    
    String formatLocalTime(DateTime? utcDate) {
      if (utcDate == null) return "Unknown";
      final localDate = utcDate.toLocal();
      return dateFormat.format(localDate);
    }
    
    final items = [
      _PremiumLicenseInfoItem(
        icon: Icons.key_rounded,
        iconColor: const Color(0xFFFF6B35),
        title: "License Key",
        value: _licenseKey,
        index: 0,
        animationController: _mainAnimationController,
        isSensitive: true,
        isVisible: _isLicenseKeyVisible,
        onToggleVisibility: () {
          setState(() {
            _isLicenseKeyVisible = !_isLicenseKeyVisible;
          });
        },
      ),
      _PremiumLicenseInfoItem(
        icon: Icons.workspace_premium_rounded,
        iconColor: const Color(0xFF9C27B0),
        title: "Subscription Type",
        value: _subscriptionType,
        index: 1,
        animationController: _mainAnimationController,
      ),
      _PremiumLicenseInfoItem(
        icon: Icons.play_circle_rounded,
        iconColor: const Color(0xFF4CAF50),
        title: "Start Date",
        value: formatLocalTime(_startDate),
        index: 2,
        animationController: _mainAnimationController,
      ),
      _PremiumLicenseInfoItem(
        icon: Icons.event_rounded,
        iconColor: const Color(0xFFF44336),
        title: "Expiry Date",
        value: formatLocalTime(_expiryDate),
        index: 3,
        animationController: _mainAnimationController,
      ),
      _PremiumLicenseInfoItem(
        icon: Icons.hourglass_top_rounded,
        iconColor: const Color(0xFF2196F3),
        title: "Time Remaining",
        value: _remainingTime,
        index: 4,
        animationController: _mainAnimationController,
        isLive: true,
      ),
      _PremiumLicenseInfoItem(
        icon: Icons.laptop_rounded,
        iconColor: const Color(0xFF009688),
        title: "Platform",
        value: _platform,
        index: 5,
        animationController: _mainAnimationController,
      ),
    ];
    
    return items;
  }
}

class _PremiumLicenseInfoItem extends StatelessWidget {
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
  
  const _PremiumLicenseInfoItem({
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
    
    final animation = CurvedAnimation(
      parent: animationController,
      curve: Interval(
        0.1 + (index * 0.05),
        0.35 + (index * 0.05),
        curve: Curves.easeOutCubic,
      ),
    );
    
    final slideAnimation = Tween<Offset>(
      begin: const Offset(0.4, 0),
      end: Offset.zero,
    ).animate(animation);
    
    final fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(animation);
    
    final scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.0,
    ).animate(animation);
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: FadeTransition(
        opacity: fadeAnimation,
        child: SlideTransition(
          position: slideAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    spreadRadius: 0,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: theme.colorScheme.outline.withOpacity(0.08),
                  width: 1,
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Row(
                  children: [
                    // Premium icon container
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            iconColor.withOpacity(0.15),
                            iconColor.withOpacity(0.08),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: iconColor.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          icon,
                          color: iconColor,
                          size: 28,
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 20),
                    
                    // Content
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: theme.textTheme.titleSmall?.copyWith(
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                              fontWeight: FontWeight.w600,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: SelectableText(
                                  isSensitive && !isVisible ? "••••••••••••••••" : value,
                                  style: theme.textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.2,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (isLive)
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Colors.green,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.green.withOpacity(0.5),
                                        blurRadius: 6,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                ),
                              if (isSensitive && onToggleVisibility != null)
                                Container(
                                  margin: const EdgeInsets.only(left: 8),
                                  child: Material(
                                    color: Colors.transparent,
                                    child: InkWell(
                                      onTap: onToggleVisibility,
                                      borderRadius: BorderRadius.circular(8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(4),
                                        child: Icon(
                                          isVisible
                                              ? Icons.visibility_off_rounded
                                              : Icons.visibility_rounded,
                                          color: theme.colorScheme.primary.withOpacity(0.7),
                                          size: 20,
                                        ),
                                      ),
                                    ),
                                  ),
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
      ),
    );
  }
} 