import 'package:flutter/material.dart';
import 'package:flutter_qnote/features/login/widgets/login_text_widget.dart';
import 'package:flutter_qnote/features/login/widgets/sub_title.widget.dart';
import 'package:flutter_qnote/features/login/widgets/title.widget.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 45),
            child: Column(
              children: [
                const SizedBox(height: 65),
                const SubTitle(), //
                const SizedBox(height: 10),

                const TitleWidget(),
                const SizedBox(height: 55),
                Text(
                  '회원가입',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 22,
                    fontFamily: 'Inter',
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.21,
                  ),
                ),
                const SizedBox(height: 33),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
