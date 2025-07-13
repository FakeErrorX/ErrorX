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

// Make sure to add flutter_svg to your pubspec.yaml dependencies:
// flutter_svg: ^2.0.0
import 'package:flutter_svg/flutter_svg.dart';
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
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 40),
                          width: min(size.width * 0.95, 420),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface.withOpacity(0.85),
                            borderRadius: BorderRadius.circular(28),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.18),
                                blurRadius: 32,
                                spreadRadius: 2,
                                offset: const Offset(0, 8),
                              ),
                            ],
                            border: Border.all(
                              color: Colors.white.withOpacity(0.18),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // App icon with modern shadow
                              Container(
                                width: 90,
                                height: 90,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: theme.colorScheme.primary.withOpacity(0.18),
                                      blurRadius: 24,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: ClipOval(
                                  child: Image.asset(
                                    'assets/images/icon.png',
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Welcome text
                              Text(
                                'Welcome to ErrorX',
                                style: theme.textTheme.headlineSmall?.copyWith(
                                  fontWeight: FontWeight.w900,
                                  letterSpacing: 0.8,
                                  color: theme.colorScheme.onSurface,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Enter your license key to continue',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                  fontWeight: FontWeight.w500,
                                ),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 28),
                              // License key input with modern style
                              Material(
                                elevation: _isError ? 0 : 2,
                                borderRadius: BorderRadius.circular(18),
                                color: Colors.transparent,
                                child: TextField(
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
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide.none,
                                    ),
                                    filled: true,
                                    fillColor: theme.colorScheme.surface.withOpacity(0.95),
                                    errorText: _isError ? _errorMessage : null,
                                    errorStyle: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                    ),
                                    enabledBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.outline.withOpacity(0.3),
                                        width: 1.2,
                                      ),
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(18),
                                      borderSide: BorderSide(
                                        color: theme.colorScheme.primary,
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  onSubmitted: (_) => _validateLicense(),
                                  style: theme.textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ),
                              const SizedBox(height: 20),
                              // Login button modern
                              SizedBox(
                                width: double.infinity,
                                height: 52,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _validateLicense,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: theme.colorScheme.primary,
                                    foregroundColor: theme.colorScheme.onPrimary,
                                    elevation: 6,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(18),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                    textStyle: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.7,
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
                                          style: TextStyle(fontSize: 17),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 30),
                              // Join us text
                              Text(
                                'Join us',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurface.withOpacity(0.55),
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  letterSpacing: 0.2,
                                ),
                              ),
                              const SizedBox(height: 10),
                              // Social buttons section
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                children: [
                                  // Website
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.public,
                                      label: 'Website',
                                      onPressed: () {
                                        _launchUrl('https://errorx.net');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Facebook
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.facebook,
                                      label: 'Facebook',
                                      onPressed: () {
                                        _launchUrl('https://facebook.com/ErrorX.gg');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Telegram
                                  Expanded(
                                    child: _SocialButton(
                                      icon: Icons.telegram,
                                      label: 'Telegram',
                                      onPressed: () {
                                        _launchUrl('https://t.me/ErrorX_BD');
                                      },
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                  // Discord
                                  Expanded(
                                    child: _DiscordSocialButton(
                                      label: 'Discord',
                                      onPressed: () {
                                        _launchUrl('https://discord.gg/sG8FYe8Npf');
                                      },
                                    ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Icon(
            icon,
            color: theme.colorScheme.onSurface.withOpacity(0.8),
            size: 16, // Slightly larger since no text
          ),
        ),
      ),
    );
  }
}


class _DiscordSocialButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _DiscordSocialButton({
    Key? key,
    required this.label,
    required this.onPressed,
  }) : super(key: key);

  static const String _discordSvg = '''
<svg xmlns="http://www.w3.org/2000/svg" shape-rendering="geometricPrecision" text-rendering="geometricPrecision" image-rendering="optimizeQuality" fill-rule="evenodd" clip-rule="evenodd" viewBox="0 0 512 365.467">
<path fill="#fff" d="M378.186 365.028s-15.794-18.865-28.956-35.099c57.473-16.232 79.41-51.77 79.41-51.77-17.989 11.846-35.099 20.182-50.454 25.885-21.938 9.213-42.997 14.917-63.617 18.866-42.118 7.898-80.726 5.703-113.631-.438-25.008-4.827-46.506-11.407-64.494-18.867-10.091-3.947-21.059-8.774-32.027-14.917-1.316-.877-2.633-1.316-3.948-2.193-.877-.438-1.316-.878-1.755-.878-7.898-4.388-12.285-7.458-12.285-7.458s21.06 34.659 76.779 51.331c-13.163 16.673-29.395 35.977-29.395 35.977C36.854 362.395 0 299.218 0 299.218 0 159.263 63.177 45.633 63.177 45.633 126.354-1.311 186.022.005 186.022.005l4.388 5.264C111.439 27.645 75.461 62.305 75.461 62.305s9.653-5.265 25.886-12.285c46.945-20.621 84.236-25.885 99.592-27.64 2.633-.439 4.827-.878 7.458-.878 26.763-3.51 57.036-4.387 88.624-.878 41.68 4.826 86.43 17.111 132.058 41.68 0 0-34.66-32.906-109.244-55.281l6.143-7.019s60.105-1.317 122.844 45.628c0 0 63.178 113.631 63.178 253.585 0-.438-36.854 62.739-133.813 65.81l-.001.001zm-43.874-203.133c-25.006 0-44.75 21.498-44.75 48.262 0 26.763 20.182 48.26 44.75 48.26 25.008 0 44.752-21.497 44.752-48.26 0-26.764-20.182-48.262-44.752-48.262zm-160.135 0c-25.008 0-44.751 21.498-44.751 48.262 0 26.763 20.182 48.26 44.751 48.26 25.007 0 44.75-21.497 44.75-48.26.439-26.763-19.742-48.262-44.75-48.262z"/>
</svg>
''';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface.withOpacity(0.1),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: theme.colorScheme.onSurface.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: SvgPicture.string(
            _discordSvg,
            width: 12,
            height: 12,
            fit: BoxFit.contain,
          ),
        ),
      ),
    );
  }
}