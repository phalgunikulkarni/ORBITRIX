import 'package:flutter/material.dart';
import 'dart:ui';
import '../theme/app_theme.dart';

class GlassMorphismCard extends StatelessWidget {
  final Widget child;
  final double blur;
  final double opacity;
  final Color? color;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final List<BoxShadow>? shadows;

  const GlassMorphismCard({
    Key? key,
    required this.child,
    this.blur = 10.0,
    this.opacity = 0.2,
    this.color,
    this.borderRadius,
    this.padding,
    this.shadows,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        boxShadow: shadows ?? AppTheme.softShadow,
        borderRadius: borderRadius ?? BorderRadius.circular(20),
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: (color ?? Colors.white).withOpacity(opacity),
              borderRadius: borderRadius ?? BorderRadius.circular(20),
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 1.5,
              ),
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class PremiumButton extends StatefulWidget {
  final Widget child;
  final VoidCallback? onPressed;
  final LinearGradient? gradient;
  final BorderRadius? borderRadius;
  final EdgeInsets? padding;
  final bool isLoading;
  final double elevation;
  final bool enablePulse;

  const PremiumButton({
    Key? key,
    required this.child,
    this.onPressed,
    this.gradient,
    this.borderRadius,
    this.padding,
    this.isLoading = false,
    this.elevation = 8.0,
    this.enablePulse = false,
  }) : super(key: key);

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    
    if (widget.enablePulse) {
      _pulseAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
      );
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) => _controller.reverse(),
      onTapCancel: () => _controller.reverse(),
      onTap: widget.onPressed,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.scale(
            scale: widget.enablePulse ? _pulseAnimation.value : _scaleAnimation.value,
            child: Container(
              padding: widget.padding ?? const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                gradient: widget.gradient ?? AppTheme.primaryGradient,
                borderRadius: widget.borderRadius ?? BorderRadius.circular(25),
                boxShadow: [
                  BoxShadow(
                    color: (widget.gradient?.colors.first ?? AppTheme.gradientStart).withOpacity(0.4),
                    blurRadius: widget.elevation,
                    offset: Offset(0, widget.elevation / 2),
                  ),
                ],
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : widget.child,
            ),
          );
        },
      ),
    );
  }
}

class ModernSearchField extends StatefulWidget {
  final TextEditingController controller;
  final String hintText;
  final VoidCallback? onChanged;
  final VoidCallback? onSubmitted;
  final bool isLoading;
  final List<Widget>? suggestions;

  const ModernSearchField({
    Key? key,
    required this.controller,
    this.hintText = 'Search...',
    this.onChanged,
    this.onSubmitted,
    this.isLoading = false,
    this.suggestions,
  }) : super(key: key);

  @override
  State<ModernSearchField> createState() => _ModernSearchFieldState();
}

class _ModernSearchFieldState extends State<ModernSearchField>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _focusAnimation;
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _focusAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _focusNode = FocusNode();
    _focusNode.addListener(() {
      if (_focusNode.hasFocus) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        AnimatedBuilder(
          animation: _focusAnimation,
          builder: (context, child) {
            return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.accentBlue.withOpacity(0.1 + _focusAnimation.value * 0.1),
                    AppTheme.neonBlue.withOpacity(0.1 + _focusAnimation.value * 0.1),
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.accentBlue.withOpacity(_focusAnimation.value * 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                onChanged: (value) => widget.onChanged?.call(),
                onFieldSubmitted: (value) => widget.onSubmitted?.call(),
                decoration: InputDecoration(
                  hintText: widget.hintText,
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w400,
                  ),
                  prefixIcon: Icon(
                    Icons.search,
                    color: AppTheme.accentBlue.withOpacity(0.7 + _focusAnimation.value * 0.3),
                  ),
                  suffixIcon: widget.isLoading
                      ? const Padding(
                          padding: EdgeInsets.all(12.0),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : widget.controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                widget.controller.clear();
                                widget.onChanged?.call();
                              },
                            )
                          : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(20),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: Colors.white.withOpacity(0.9),
                ),
              ),
            );
          },
        ),
        if (widget.suggestions != null && widget.suggestions!.isNotEmpty)
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            margin: const EdgeInsets.only(top: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              boxShadow: AppTheme.mediumShadow,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(15),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.9),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: widget.suggestions!,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class StatusCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final LinearGradient gradient;
  final VoidCallback? onTap;

  const StatusCard({
    Key? key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.gradient,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: gradient.colors.first.withOpacity(0.4),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AnimatedCounter extends StatefulWidget {
  final int count;
  final String label;
  final Duration duration;

  const AnimatedCounter({
    Key? key,
    required this.count,
    required this.label,
    this.duration = const Duration(milliseconds: 800),
  }) : super(key: key);

  @override
  State<AnimatedCounter> createState() => _AnimatedCounterState();
}

class _AnimatedCounterState extends State<AnimatedCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<int> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(duration: widget.duration, vsync: this);
    _animation = IntTween(begin: 0, end: widget.count).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AnimatedCounter oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _animation = IntTween(begin: oldWidget.count, end: widget.count).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeOut),
      );
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Text(
          '${_animation.value} ${widget.label}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        );
      },
    );
  }
}