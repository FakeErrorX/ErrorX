import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'package:errorx/state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:errorx/providers/config.dart';
import 'package:errorx/plugins/app.dart';
import 'package:errorx/enum/enum.dart';
import 'package:errorx/services/api_service.dart';
import 'dart:ui';
import 'dart:math';
import 'package:url_launcher/url_launcher.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> with SingleTickerProviderStateMixin {
  final TextEditingController _licenseController = TextEditingController();
  bool _isError = false;
  bool _isLoading = false;
  bool _isLicenseKeyVisible = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  String _errorMessage = '';
  final ApiService _apiService = ApiService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOut,
      ),
    );
    
    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: Curves.easeOutCubic,
      ),
    );
    
    _animationController.forward();
    
    // Try auto-login and retrieve saved license key
    _checkAutoLogin();
  }
  
  Future<void> _checkAutoLogin() async {
    // Only try auto-login if we're not already authenticated
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    
    // Retrieve saved license key if available
    final savedLicense = prefs.getString('license_key');
    if (savedLicense != null && savedLicense.isNotEmpty) {
      setState(() {
        _licenseController.text = savedLicense;
      });
    }
    
    if (isLoggedIn) {
      setState(() {
        _isLoading = true;
      });
      
      final success = await _apiService.autoLogin();
      
      if (success && mounted) {
        // Complete the initialization process after successful login
        WidgetsBinding.instance.addPostFrameCallback((_) async {
          if (!mounted) return;
          
          // Fully initialize the app after login
          await globalState.appController.init();
          
          // Reset to home page navigation
          globalState.appController.toPage(PageLabel.dashboard);
        });
        
        // Navigate to home page
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const HomePage(),
          ),
          (route) => false,
        );
      } else {
        setState(() {
          _isLoading = false;
          // Show error message if auto-login failed
          _isError = true;
          _errorMessage = 'Your session has expired. Please login again.';
        });
      }
    }
  }

  @override
  void dispose() {
    _licenseController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _validateLicense() async {
    setState(() {
      _isLoading = true;
      _isError = false;
    });

    // Check if the license key field is empty
    if (_licenseController.text.trim().isEmpty) {
      setState(() {
        _isLoading = false;
        _isError = true;
        _errorMessage = 'Please enter a license key';
      });
      return;
    }

    // Validate license through API
    final result = await _apiService.login(_licenseController.text.trim());
    
    if (result['status'] == 'success') {
      // Save the license key to SharedPreferences for future use
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('license_key', _licenseController.text.trim());
      
      // Complete the initialization process after successful login
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        
        // Fully initialize the app after login
        await globalState.appController.init();
        
        // Reset to home page navigation
        globalState.appController.toPage(PageLabel.dashboard);
      });
      
      if (!mounted) return;
      
      // Navigate to home page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const HomePage(),
        ),
        (route) => false,
      );
    } else {
      setState(() {
        _isError = true;
        _errorMessage = result['message'] ?? 'Failed to validate license';
      });
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _launchUrl(String url) async {
    if (!await launchUrl(Uri.parse(url))) {
      throw Exception('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final theme = Theme.of(context);
    
    return Scaffold(
      body: Stack(
        children: [
          // Animated background with gradient
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  theme.colorScheme.primary,
                  theme.colorScheme.primary.withOpacity(0.7),
                  theme.colorScheme.primaryContainer,
                ],
                stops: const [0.0, 0.5, 1.0],
              ),
            ),
          ),
          
          // Background pattern
          Positioned.fill(
            child: CustomPaint(
              painter: _BackgroundPatternPainter(
                color: Colors.white.withOpacity(0.05),
              ),
            ),
          ),
          
          Center(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: SlideTransition(
                    position: _slideAnimation,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(24),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                        child: Container(
                          padding: const EdgeInsets.all(32),
                          width: min(size.width * 0.9, 400),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.8),
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 20,
                                spreadRadius: 5,
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.2),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              // App icon
                              Container(
                                width: 100,
                                height: 100,
                                decoration: const BoxDecoration(
                                  shape: BoxShape.circle,
                                ),
                                child: Image.asset(
                                  'assets/images/icon.png',
                                  width: 100,
                                  height: 100,
                                ),
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Welcome text
                              Text(
                                'Welcome to ErrorX',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 8),
                              
                              Text(
                                'Enter your license key to continue',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                                textAlign: TextAlign.center,
                              ),
                              
                              const SizedBox(height: 32),
                              
                              // License key input
                              TextField(
                                controller: _licenseController,
                                obscureText: !_isLicenseKeyVisible,
                                decoration: InputDecoration(
                                  labelText: 'License Key',
                                  hintText: 'Enter your license key',
                                  prefixIcon: Icon(
                                    Icons.vpn_key_rounded,
                                    color: _isError 
                                        ? theme.colorScheme.error 
                                        : theme.colorScheme.primary,
                                  ),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _isLicenseKeyVisible 
                                          ? Icons.visibility_off 
                                          : Icons.visibility,
                                      color: theme.colorScheme.primary.withOpacity(0.7),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _isLicenseKeyVisible = !_isLicenseKeyVisible;
                                      });
                                    },
                                    tooltip: _isLicenseKeyVisible ? 'Hide license key' : 'Show license key',
                                  ),
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide.none,
                                  ),
                                  filled: true,
                                  fillColor: theme.colorScheme.surface,
                                  errorText: _isError ? _errorMessage : null,
                                  errorStyle: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.outline.withOpacity(0.5),
                                      width: 1.5,
                                    ),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    borderSide: BorderSide(
                                      color: theme.colorScheme.primary,
                                      width: 2,
                                    ),
                                  ),
                                ),
                                onSubmitted: (_) => _validateLicense(),
                                style: theme.textTheme.bodyLarge,
                              ),
                              
                              const SizedBox(height: 24),
                              
                              // Login button
                              SizedBox(
                                width: double.infinity,
                                height: 56,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _validateLicense,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    elevation: 4,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    textStyle: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                    shadowColor: theme.colorScheme.shadow,
                                  ),
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2.5,
                                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                          ),
                                        )
                                      : const Text(
                                          'Login',
                                          style: TextStyle(fontSize: 16),
                                        ),
                                ),
                              ),

                              const SizedBox(height: 32),

                              // Join Us section
                              Column(
                                children: [
                                  Text(
                                    'Join Us',
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      color: theme.colorScheme.onSurface.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      // Website
                                      _SocialButton(
                                        icon: Icons.public,
                                        label: 'Website',
                                        onPressed: () {
                                          _launchUrl('https://errorx.net');
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      // Facebook
                                      _SocialButton(
                                        icon: Icons.facebook,
                                        label: 'Facebook',
                                        onPressed: () {
                                          _launchUrl('https://facebook.com/ErrorX.gg');
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      // Telegram
                                      _SocialButton(
                                        icon: Icons.telegram,
                                        label: 'Telegram',
                                        onPressed: () {
                                          _launchUrl('https://t.me/ErrorX_BD');
                                        },
                                      ),
                                      const SizedBox(width: 16),
                                      // Discord
                                      _SocialButton(
                                        icon: Icons.forum,
                                        label: 'Discord',
                                        onPressed: () {
                                          _launchUrl('https://discord.gg/sG8FYe8Npf');
                                        },
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BackgroundPatternPainter extends CustomPainter {
  final Color color;
  
  _BackgroundPatternPainter({required this.color});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    
    final double tileSize = 30;
    
    for (double x = 0; x < size.width; x += tileSize) {
      for (double y = 0; y < size.height; y += tileSize) {
        final path = Path();
        
        if ((x ~/ tileSize + y ~/ tileSize) % 2 == 0) {
          path.moveTo(x, y);
          path.lineTo(x + tileSize, y + tileSize);
          path.moveTo(x + tileSize, y);
          path.lineTo(x, y + tileSize);
        } else {
          path.addOval(Rect.fromCenter(
            center: Offset(x + tileSize / 2, y + tileSize / 2), 
            width: tileSize / 2, 
            height: tileSize / 2
          ));
        }
        
        canvas.drawPath(path, paint);
      }
    }
  }
  
  @override
  bool shouldRepaint(_BackgroundPatternPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;

  const _SocialButton({
    Key? key,
    required this.icon,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: label,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: theme.colorScheme.onSurface.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Icon(
              icon,
              color: theme.colorScheme.onSurface.withOpacity(0.8),
              size: 24,
            ),
          ),
        ),
      ),
    );
  }
} 