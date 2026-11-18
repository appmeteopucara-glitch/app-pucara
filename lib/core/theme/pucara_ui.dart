import 'dart:ui';

import 'package:flutter/material.dart';

class PucaraColors {
  static const Color backgroundTop = Color(0xFF05172F);
  static const Color backgroundBottom = Color(0xFF010811);
  static const Color surface = Color(0xCC0B1A31);
  static const Color surfaceStrong = Color(0xE610223F);
  static const Color border = Color(0x4DB4CCF6);
  static const Color accent = Color(0xFF0A84FF);
  static const Color accentBright = Color(0xFF2E9BFF);
  static const Color textPrimary = Colors.white;
  static const Color textSecondary = Color(0xFFB6C2D4);
  static const Color success = Color(0xFF60D669);
  static const Color warning = Color(0xFFFFC53D);
  static const Color danger = Color(0xFFFF5D5D);
}

class PucaraBackground extends StatelessWidget {
  const PucaraBackground({super.key});

  static const String backgroundAsset = 'assets/images/montana.png';

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const ColoredBox(color: PucaraColors.backgroundTop),
        Positioned.fill(
          child: Transform.scale(
            scale: 1.14,
            child: Image.asset(
              backgroundAsset,
              fit: BoxFit.cover,
              alignment: const Alignment(0, -0.24),
              filterQuality: FilterQuality.high,
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: const Alignment(0, -0.92),
                radius: 1.18,
                colors: [
                  const Color(0x663F9EFF),
                  const Color(0x221F5D94),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.4, 1.0],
                colors: [
                  const Color(0x70041A33),
                  const Color(0x54112C4C),
                  Colors.black.withValues(alpha: 0.5),
                ],
              ),
            ),
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: const [0.0, 0.5, 1.0],
                colors: [
                  Colors.black.withValues(alpha: 0.04),
                  Colors.black.withValues(alpha: 0.12),
                  Colors.black.withValues(alpha: 0.64),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class PucaraPanel extends StatelessWidget {
  const PucaraPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(20),
    this.margin,
    this.borderRadius = 22,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: padding,
            decoration: BoxDecoration(
              color: color ?? const Color(0xB80C1C34),
              borderRadius: BorderRadius.circular(borderRadius),
              border: Border.all(
                color: PucaraColors.border.withValues(alpha: 0.72),
                width: 1.05,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.24),
                  blurRadius: 26,
                  offset: const Offset(0, 14),
                ),
              ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

class PucaraPrimaryButton extends StatelessWidget {
  const PucaraPrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final disabled = onPressed == null || isLoading;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: disabled
            ? const LinearGradient(
                colors: [Color(0xFF35506B), Color(0xFF263B56)],
              )
            : const LinearGradient(
                colors: [PucaraColors.accentBright, PucaraColors.accent],
              ),
        boxShadow: disabled
            ? null
            : [
                BoxShadow(
                  color: PucaraColors.accent.withValues(alpha: 0.35),
                  blurRadius: 18,
                  offset: const Offset(0, 10),
                ),
              ],
      ),
      child: ElevatedButton(
        onPressed: disabled ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.transparent,
          disabledForegroundColor: Colors.white70,
          minimumSize: const Size.fromHeight(60),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          textStyle: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.9,
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: Colors.white,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 20),
                    const SizedBox(width: 10),
                  ],
                  Text(label),
                ],
              ),
      ),
    );
  }
}

class PucaraMetricPill extends StatelessWidget {
  const PucaraMetricPill({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color = PucaraColors.accentBright,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: const TextStyle(
                  fontSize: 10,
                  color: PucaraColors.textSecondary,
                  letterSpacing: 0.7,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 14,
                  color: PucaraColors.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PucaraSectionTitle extends StatelessWidget {
  const PucaraSectionTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: const TextStyle(
                  color: PucaraColors.textPrimary,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: const TextStyle(
                    color: PucaraColors.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class PucaraBrand extends StatelessWidget {
  const PucaraBrand({
    super.key,
    this.size = 110,
    this.showTagline = true,
    this.compact = false,
    this.textAlign = TextAlign.center,
  });

  final double size;
  final bool showTagline;
  final bool compact;
  final TextAlign textAlign;

  static const String logoAsset = 'assets/images/logo.png';

  @override
  Widget build(BuildContext context) {
    final logoHeight = compact ? size * 0.78 : size;
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: compact ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        SizedBox(
          width: size,
          height: logoHeight,
          child: Image.asset(
            logoAsset,
            fit: BoxFit.contain,
            alignment: compact ? Alignment.centerLeft : Alignment.center,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Text(
          compact ? 'PUCARÁ' : 'P U C A R Á',
          textAlign: textAlign,
          style: TextStyle(
            color: PucaraColors.accentBright,
            fontSize: compact ? size * 0.16 : size * 0.12,
            fontWeight: FontWeight.w700,
            letterSpacing: compact ? 2.6 : 5.0,
          ),
        ),
        if (showTagline) ...[
          SizedBox(height: compact ? 8 : 12),
          Container(
            width: compact ? size * 0.42 : size * 0.52,
            height: 1,
            color: Colors.white.withValues(alpha: 0.16),
          ),
          SizedBox(height: compact ? 8 : 12),
          Text(
            'INFORMACIÓN METEOROLÓGICA\nPARA DECISIONES SEGURAS',
            textAlign: textAlign,
            style: TextStyle(
              color: PucaraColors.textSecondary,
              fontSize: compact ? 9 : 12,
              height: 1.35,
              letterSpacing: 0.35,
            ),
          ),
        ],
      ],
    );
  }
}

InputDecoration pucaraInputDecoration({
  required String hint,
  required IconData icon,
  Widget? suffixIcon,
}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(color: PucaraColors.textSecondary),
    prefixIcon: Icon(icon, color: Colors.white.withValues(alpha: 0.92)),
    suffixIcon: suffixIcon,
    filled: true,
    fillColor: Colors.white.withValues(alpha: 0.04),
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 18),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: PucaraColors.accentBright),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: PucaraColors.danger),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: const BorderSide(color: PucaraColors.danger),
    ),
  );
}
