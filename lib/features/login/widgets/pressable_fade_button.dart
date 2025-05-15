import 'package:flutter/material.dart';
import 'package:flutter_qnote/features/login/widgets/login_button_text_widget.dart';

class PressableFadeButton extends StatefulWidget {
  const PressableFadeButton({
    super.key,
    required this.signInCallBack,
    required this.text,
  });

  final VoidCallback signInCallBack;
  final String text;
  @override
  State<PressableFadeButton> createState() => _PressableFadeButtonState();
}

class _PressableFadeButtonState extends State<PressableFadeButton> {
  double _darkOverlayOpacity = 0.0;

  void _handleTapDown(TapDownDetails details) {
    setState(() {
      _darkOverlayOpacity = 0.5; // 즉시 어두워짐
    });

    // 서서히 밝아짐
    Future.delayed(Duration(milliseconds: 250), () {
      setState(() {
        _darkOverlayOpacity = 0.0;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: _handleTapDown,
      onTapUp: (details) {
        widget.signInCallBack();
      },
      child: Stack(
        children: [
          Container(
            width: 315,
            height: 45,
            decoration: ShapeDecoration(
              color: const Color(0xFF937A58), // 갈색
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
            ),
            child: Center(child: LoginButtonTextWidget(text: widget.text)),
          ),
          AnimatedOpacity(
            opacity: _darkOverlayOpacity,
            duration: const Duration(milliseconds: 300),
            child: Container(
              width: 315,
              height: 45,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(25),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
