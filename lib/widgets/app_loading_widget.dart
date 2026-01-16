import 'dart:math';
import 'package:flutter/material.dart';
import 'package:jippymart_customer/themes/app_them_data.dart';

class AppLoadingWidget extends StatefulWidget {
  final String? title;
  final String? subtitle;
  final IconData? icon;
  final Color? iconColor;
  final Color? backgroundColor;
  final double? size;
  final bool showDots;
  final bool showFunFact;

  const AppLoadingWidget({
    super.key,
    this.title,
    this.subtitle,
    this.icon,
    this.iconColor,
    this.backgroundColor,
    this.size,
    this.showDots = true,
    this.showFunFact = false,
  });

  @override
  State<AppLoadingWidget> createState() => _AppLoadingWidgetState();
}

class _AppLoadingWidgetState extends State<AppLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // **ANIMATED ICON**
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: Container(
                  width: widget.size ?? 60,
                  height: widget.size ?? 60,
                  decoration: BoxDecoration(
                    color: widget.backgroundColor ?? AppThemeData.primary300,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (widget.backgroundColor ?? AppThemeData.primary300)
                            .withValues(alpha: 0.3),
                        blurRadius: 15,
                        spreadRadius: 3,
                      ),
                    ],
                  ),
                  child: Icon(
                    widget.icon ?? Icons.search,
                    color: widget.iconColor ?? Colors.white,
                    size: (widget.size ?? 60) * 0.5,
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // **LOADING TEXT**
          Column(
            children: [
              if (widget.title != null) ...[
                Text(
                  widget.title!,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppThemeData.grey900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
              ],
              if (widget.subtitle != null) ...[
                Text(
                  widget.subtitle!,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppThemeData.grey400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ),

          if (widget.showDots) ...[
            const SizedBox(height: 20),
            _AnimatedDots(),
          ],

          if (widget.showFunFact) ...[
            const SizedBox(height: 40),
            _buildFunFact(),
          ],
        ],
      ),
    );
  }

  Widget _buildFunFact() {
    final funFacts = [
      "🍕 Pizza is the most popular food in the world!",
      "🌮 Tacos are eaten 4.5 billion times per year in the US!",
      "🍔 Americans eat 50 billion burgers per year!",
      "🍜 Ramen was invented in Japan in 1958!",
      "🍰 The world's largest cake weighed 128,238 pounds!",
      "🥘 Biryani has over 50 different varieties!",
      "🍦 Ice cream was invented in China over 4000 years ago!",
      "🍕 The first pizza was made in Naples, Italy!",
    ];

    final randomFact = funFacts[DateTime.now().millisecond % funFacts.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeData.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppThemeData.primary300.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        randomFact,
        style: TextStyle(fontSize: 14, color: AppThemeData.grey600),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// Animated dots widget with continuous looping
class _AnimatedDots extends StatefulWidget {
  const _AnimatedDots();

  @override
  State<_AnimatedDots> createState() => _AnimatedDotsState();
}

class _AnimatedDotsState extends State<_AnimatedDots>
    with TickerProviderStateMixin {
  late List<AnimationController> _controllers;
  late List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(3, (index) {
      final controller = AnimationController(
        duration: Duration(milliseconds: 600 + (index * 200)),
        vsync: this,
      );
      controller.repeat(reverse: true);
      return controller;
    });

    _animations = _controllers.map((controller) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: controller, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (var controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(3, (index) {
        return AnimatedBuilder(
          animation: _animations[index],
          builder: (context, child) {
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: const Color(0xFFFF5201)
                    .withValues(alpha: _animations[index].value),
                shape: BoxShape.circle,
              ),
            );
          },
        );
      }),
    );
  }
}

// **PREDEFINED LOADING WIDGETS FOR COMMON USE CASES**

class SearchLoadingWidget extends StatelessWidget {
  const SearchLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const AppLoadingWidget(
      title: "🔍 Finding Your Perfect Match",
      subtitle: "Searching through thousands of options...",
      icon: Icons.search,
      showDots: true,
      showFunFact: false,
    );
  }
}

class RestaurantLoadingWidget extends StatefulWidget {
  final bool showFunFact;

  const RestaurantLoadingWidget({super.key, this.showFunFact = true});

  @override
  State<RestaurantLoadingWidget> createState() => _RestaurantLoadingWidgetState();
}

class _RestaurantLoadingWidgetState extends State<RestaurantLoadingWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _plateRotationController;
  late AnimationController _iconRotationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Scale animation for pulsing effect
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.easeInOut),
    );

    // Continuous rotation for plate
    _plateRotationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // Continuous rotation for icon (slower)
    _iconRotationController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _plateRotationController.dispose();
    _iconRotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned(
          top: -100,
          right: -100,
          child: Container(
            width: 300,
            height: 300,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppThemeData.primary300.withOpacity(0.1),
                  AppThemeData.primary300.withOpacity(0.05),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          bottom: -150,
          left: -100,
          child: Container(
            width: 350,
            height: 350,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppThemeData.primary300.withOpacity(0.08),
                  AppThemeData.primary300.withOpacity(0.03),
                ],
              ),
            ),
          ),
        ),
        Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // **ANIMATED RESTAURANT ICON WITH ROTATING PLATE**
              AnimatedBuilder(
                animation: Listenable.merge([
                  _scaleController,
                  _plateRotationController,
                  _iconRotationController,
                ]),
                builder: (context, child) {
                  return Opacity(
                    opacity: _fadeAnimation.value,
                    child: Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Rotating plate background
                          Transform.rotate(
                            angle: _plateRotationController.value * 2 * pi,
                            child: Container(
                              width: 90,
                              height: 90,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5201)
                                    .withValues(alpha: 0.1),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: const Color(0xFFFF5201)
                                      .withValues(alpha: 0.3),
                                  width: 2,
                                ),
                              ),
                              child: CustomPaint(painter: PlatePainter()),
                            ),
                          ),
                          // Main restaurant icon with rotation
                          Transform.rotate(
                            angle: _iconRotationController.value * 2 * pi,
                            child: Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: const Color(0xFFFF5201),
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFFF5201)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.restaurant_menu,
                                color: Colors.white,
                                size: 40,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // **LOADING TEXT**
              Column(
                children: [
                  Text(
                    "🍽️ Preparing Your Food Journey",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppThemeData.grey900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Loading delicious restaurants & dishes...",
                    style: TextStyle(
                      fontSize: 14,
                      color: AppThemeData.grey400,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // **ANIMATED DOTS**
              _AnimatedDots(),

              if (widget.showFunFact) ...[
                const SizedBox(height: 40),
                _buildFunFact(),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFunFact() {
    final funFacts = [
      "🍕 Pizza is the most popular food in the world!",
      "🌮 Tacos are eaten 4.5 billion times per year in the US!",
      "🍔 Americans eat 50 billion burgers per year!",
      "🍜 Ramen was invented in Japan in 1958!",
      "🍰 The world's largest cake weighed 128,238 pounds!",
      "🥘 Biryani has over 50 different varieties!",
      "🍦 Ice cream was invented in China over 4000 years ago!",
      "🍕 The first pizza was made in Naples, Italy!",
    ];

    final randomFact = funFacts[DateTime.now().millisecond % funFacts.length];

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppThemeData.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.orange.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Text(
        randomFact,
        style: TextStyle(fontSize: 14, color: AppThemeData.grey600),
        textAlign: TextAlign.center,
      ),
    );
  }
}

class GeneralLoadingWidget extends StatelessWidget {
  final String? message;

  const GeneralLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppLoadingWidget(
      title: message ?? "⏳ Loading...",
      icon: Icons.hourglass_empty,
      showDots: true,
      showFunFact: false,
    );
  }
}

class DataLoadingWidget extends StatelessWidget {
  final String? message;

  const DataLoadingWidget({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return AppLoadingWidget(
      title: message ?? "📊 Loading Data...",
      subtitle: "Please wait while we fetch your information",
      icon: Icons.cloud_download,
      showDots: true,
      showFunFact: false,
    );
  }
}

class OrderLoadingWidget extends StatefulWidget {
  final String? message;

  const OrderLoadingWidget({super.key, this.message});

  @override
  State<OrderLoadingWidget> createState() => _OrderLoadingWidgetState();
}

class _OrderLoadingWidgetState extends State<OrderLoadingWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );

    _fadeAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // **ANIMATED HAND WITH SERVING DISH ICON**
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeAnimation.value,
                child: Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF5201),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF5201).withValues(alpha: 0.3),
                          blurRadius: 20,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.room_service, // Hand with serving dish icon
                      color: Colors.white,
                      size: 40,
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // **LOADING TEXT**
          Column(
            children: [
              Text(
                widget.message ?? "🍽️ Loading Your Orders",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppThemeData.grey900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Fetching your delicious order history...",
                style: TextStyle(
                  fontSize: 14,
                  color: AppThemeData.grey400,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // **ANIMATED DOTS**
          _AnimatedDots(),
        ],
      ),
    );
  }
}

/// **CUSTOM PAINTER FOR PLATE DESIGN**
class PlatePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFF5201).withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 5;

    // Draw plate rim
    canvas.drawCircle(center, radius, paint);

    // Draw decorative lines on the plate
    for (int i = 0; i < 8; i++) {
      final angle = (i * 3.14159 * 2) / 8;
      final startRadius = radius * 0.7;
      final endRadius = radius * 0.9;

      final startX = center.dx + startRadius * cos(angle);
      final startY = center.dy + startRadius * sin(angle);
      final endX = center.dx + endRadius * cos(angle);
      final endY = center.dy + endRadius * sin(angle);

      canvas.drawLine(Offset(startX, startY), Offset(endX, endY), paint);
    }

    // Draw inner circle
    canvas.drawCircle(center, radius * 0.6, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
