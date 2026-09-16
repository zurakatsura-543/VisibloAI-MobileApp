import 'package:flutter/material.dart';

/// Premium, pixel-perfect animated splash screen for VisibloAI.
/// Uses exact 1:1 extracted PNG sub-layer assets from brand_mark.png.
class VisibloSplashView extends StatefulWidget {
  const VisibloSplashView({
    super.key,
    this.logoWidth = 260.0,
    this.onAnimationComplete,
  });

  /// The width of the full logo lockup.
  final double logoWidth;

  /// Callback triggered when the animation completes (~1.8s - 2.0s).
  final VoidCallback? onAnimationComplete;

  @override
  State<VisibloSplashView> createState() => _VisibloSplashViewState();
}

class _VisibloSplashViewState extends State<VisibloSplashView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // Animations according to spec timeline (0.0s to 2.0s total)
  late final Animation<double> _eyeOutlineWipe;
  late final Animation<double> _eyeDotScale;
  late final Animation<double> _eyeDotOpacity;
  late final Animation<double> _visibloTextWipe;
  late final Animation<double> _aiTextOpacity;
  late final Animation<Offset> _aiTextSlide;
  late final Animation<double> _pulseScale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );

    // Easing: Curves.easeInOut throughout (cubic ease-in-out)

    // 0.15s - 0.60s (Normalized: 0.075 to 0.30): Eye outline left-to-right reveal
    _eyeOutlineWipe = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.075, 0.300, curve: Curves.easeInOut),
    );

    // 0.45s - 0.75s (Normalized: 0.225 to 0.375): Teal center circle scale (0.85 -> 1.0) & opacity
    _eyeDotScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.225, 0.375, curve: Curves.easeInOut),
      ),
    );
    _eyeDotOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.225, 0.375, curve: Curves.easeInOut),
    );

    // 0.65s - 1.05s (Normalized: 0.325 to 0.525): "Visiblo" text wipe reveal
    _visibloTextWipe = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.325, 0.525, curve: Curves.easeInOut),
    );

    // 0.95s - 1.25s (Normalized: 0.475 to 0.625): "AI" text fade-in & slight horizontal slide
    _aiTextOpacity = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.475, 0.625, curve: Curves.easeInOut),
    );
    _aiTextSlide = Tween<Offset>(
      begin: const Offset(-0.04, 0.0),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.475, 0.625, curve: Curves.easeInOut),
      ),
    );

    // 1.25s - 1.50s (Normalized: 0.625 to 0.750): Subtle unified scale pulse 1.00 -> 1.02 -> 1.00
    _pulseScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.02).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.02, end: 1.0).chain(
          CurveTween(curve: Curves.easeInOut),
        ),
        weight: 50,
      ),
    ]).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.625, 0.750),
      ),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        widget.onAnimationComplete?.call();
      }
    });

    // Start animation
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const double aspectRatio = 1656.0 / 487.0;
    final double logoHeight = widget.logoWidth / aspectRatio;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              final double currentPulse =
                  _controller.value >= 0.625 && _controller.value <= 0.750
                      ? _pulseScale.value
                      : 1.0;

              return Transform.scale(
                scale: currentPulse,
                child: SizedBox(
                  width: widget.logoWidth,
                  height: logoHeight,
                  child: Stack(
                    children: [
                      // 1. Eye Shape Outline (Navy) - Left to right wipe reveal
                      ClipRect(
                        clipper: _LeftToRightWipeClipper(_eyeOutlineWipe.value),
                        child: Image.asset(
                          'assets/icons/brand_eye_outline.png',
                          width: widget.logoWidth,
                          height: logoHeight,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // 2. Teal Center Circle - Scale from 85% to 100% + Fade
                      Opacity(
                        opacity: _eyeDotOpacity.value,
                        child: Transform.scale(
                          scale: _eyeDotScale.value,
                          alignment: const Alignment(-0.80, 0.0), // Center of eye icon
                          child: Image.asset(
                            'assets/icons/brand_eye_dot.png',
                            width: widget.logoWidth,
                            height: logoHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),

                      // 3. "Visiblo" Text (Navy) - Left-to-right wipe reveal
                      ClipRect(
                        clipper: _LeftToRightWipeClipper(_visibloTextWipe.value),
                        child: Image.asset(
                          'assets/icons/brand_text_visiblo.png',
                          width: widget.logoWidth,
                          height: logoHeight,
                          fit: BoxFit.contain,
                        ),
                      ),

                      // 4. "AI" Text (Teal) - Slide + Fade
                      Opacity(
                        opacity: _aiTextOpacity.value,
                        child: FractionalTranslation(
                          translation: _aiTextSlide.value,
                          child: Image.asset(
                            'assets/icons/brand_text_ai.png',
                            width: widget.logoWidth,
                            height: logoHeight,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

/// Custom Clipper that reveals content from left to right based on [progress] (0.0 to 1.0).
class _LeftToRightWipeClipper extends CustomClipper<Rect> {
  final double progress;

  _LeftToRightWipeClipper(this.progress);

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * progress, size.height);
  }

  @override
  bool shouldReclip(_LeftToRightWipeClipper oldClipper) {
    return oldClipper.progress != progress;
  }
}
