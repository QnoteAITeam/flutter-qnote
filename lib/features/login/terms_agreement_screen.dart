import 'package:flutter/material.dart';
import 'package:flutter_qnote/features/login/signup_screen.dart';
import 'package:flutter_qnote/features/login/widgets/pressable_fade_button.dart';
import 'package:flutter_qnote/features/login/widgets/sub_title.widget.dart';
import 'package:flutter_qnote/features/login/widgets/title.widget.dart';

class TermsAgreementScreen extends StatefulWidget {
  const TermsAgreementScreen({super.key});

  @override
  State<TermsAgreementScreen> createState() => _TermsAgreementScreenState();
}

class _TermsAgreementScreenState extends State<TermsAgreementScreen> {
  final _textWidth = 330.0;
  final _detailFontSize = 16.0;

  void _onPressedAgreeButton() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) {
          return const SignupScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final middleTextStyle = TextStyle(
      color: Colors.black,
      fontSize: 20,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: -0.21,
    );

    final detailTextStyle = TextStyle(
      color: const Color(0xFF727272),
      fontSize: 16,
      fontFamily: 'Inter',
      fontWeight: FontWeight.w500,
      letterSpacing: -0.21,
    );

    return Scaffold(
      body: SafeArea(
        child: Container(
          height: double.infinity,
          width: double.infinity,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const SizedBox(height: 65),
                  const SubTitle(), //
                  const SizedBox(height: 10),

                  const TitleWidget(),
                  const SizedBox(height: 30),

                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      '서비스 이용약관 동의',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 28,
                        fontFamily: 'Inter',
                        fontWeight: FontWeight.w600,
                        letterSpacing: -0.21,
                      ),
                    ),
                  ),

                  const SizedBox(height: 34),

                  SizedBox(
                    width: _textWidth,
                    child: Text('서비스 이용 목적', style: middleTextStyle),
                  ),

                  const SizedBox(height: 24),

                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      '본 서비스는 LLM(대규모 언어 모델)을 기반으로 한 AI 기능을 제공합니다. 사용자는 비정상적 사용이나 악용 없이, 정해진 목적 내에서 서비스를 이용해야 합니다.',
                      style: detailTextStyle,
                    ),
                  ),

                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text('수집하는 정보 및 목적', style: middleTextStyle),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      '회원가입 시 이메일, 비밀번호, 별명만을 수집합니다. 해당 정보는 다음의 목적에 한해 사용됩니다.',
                      style: detailTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      '사용자 식별 및 로그인 기능 제공\n개인화된 서비스 제공\n서비스 운영 및 품질 개선',
                      style: detailTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      '수집된 정보는 관련 법령에 따라 안전하게 보관되며, 사용자 동의 없이 제3자에게 제공되지 않습니다.',
                      style: detailTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text('AI 기능 이용 관련 안내', style: middleTextStyle),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      '사용자의 입력은 AI 기능 작동을 위해 일시적으로 처리될 수 있습니다.\n입력된 내용은 저장되지 않으며, 모델의 응답 결과는 자동 생성된 텍스트입니다.\nAI 응답 결과의 정확성이나 신뢰도는 보장되지 않으며, 사용자의 판단과 책임 하에 활용되어야 합니다.',
                      style: detailTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text('이용상의 제한', style: middleTextStyle),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      '아래와 같은 행위는 금지되며, 위반 시 서비스 이용이 제한될 수 있습니다:',
                      style: detailTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      'AI 기능을 통한 불법적 정보 생성\n타인에 대한 비방, 명예훼손, 혐오 발언\n시스템의 정상적 운영을 방해하는 행위',
                      style: detailTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text('면책 조항', style: middleTextStyle),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      'AI 응답 내용으로 인해 발생한 피해나 책임은 사용자 본인에게 있으며, 서비스 제공자는 이에 대해 책임을 지지 않습니다.',
                      style: detailTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text('약관 변경', style: middleTextStyle),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: _textWidth,
                    child: Text(
                      '약관은 법령 또는 서비스 정책 변경에 따라 사전 고지 후 수정될 수 있습니다.',
                      style: detailTextStyle,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    width: 316,
                    height: 46,
                    decoration: ShapeDecoration(
                      color: const Color(0xFF937A58) /* 갈색 */,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(25),
                      ),
                    ),

                    child: PressableFadeButton(
                      signInCallBack: _onPressedAgreeButton,
                      text: '[필수] 위 약관에 동의 합니다.',
                    ),
                  ),

                  const SizedBox(height: 50),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
