import 'package:flutter/material.dart';

class EmailPasswordForm extends StatefulWidget {
  EmailPasswordForm({
    super.key,
    required this.handleKakaoLogin,
    required this.handleLocalLogin,
    required this.saveForm,
  });

  final void Function(String, String, BuildContext) handleLocalLogin;
  final void Function() handleKakaoLogin;
  final void Function(String, String) saveForm;

  @override
  State<EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final _formKey = GlobalKey<FormState>();

  String _enteredEmail = '';
  String _enteredPassword = '';

  bool _isPressed = false;

  bool _saveData() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return false;

    _formKey.currentState!.save();
    widget.saveForm(_enteredEmail, _enteredPassword);

    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextFormField(
            decoration: InputDecoration(
              labelText: '이메일',
              //
            ),

            autocorrect: false,
            keyboardType: TextInputType.emailAddress,

            validator: (value) {
              if (value == null || value.isEmpty || value.trim().length == 0) {
                return '이메일을 입력해주세요!';
              }

              return null;
            },

            onSaved: (newValue) {
              _enteredEmail = newValue!;
            },
          ),

          TextFormField(
            decoration: InputDecoration(
              labelText: '비밀번호',
              //
            ),

            autocorrect: false,
            obscureText: true,

            validator: (value) {
              if (value == null || value.isEmpty) return '비밀번호를 입력해주세요.';
              if (value.contains(' ')) return '비밀번호에 공백이 있으면 안됩니다.';
              if (value.length < 6) return '비밀번호는 6자리 이상이어야 합니다.';

              return null;
            },

            onSaved: (newValue) {
              _enteredPassword = newValue!;
            },
          ),
          //
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {
              if (!_saveData()) return;
              widget.handleLocalLogin(_enteredEmail, _enteredPassword, context);
            },
            child: Text('앱 자체 회원가입 & 로그인'),
          ),
          //
          const SizedBox(height: 10),
          InkWell(
            onTap: widget.handleKakaoLogin,
            onHighlightChanged: (value) {
              setState(() {
                _isPressed = value;
              });
            },
            borderRadius: BorderRadius.circular(8),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: ColorFiltered(
                colorFilter: ColorFilter.mode(
                  _isPressed
                      ? Colors.black.withValues(alpha: 0.2)
                      : Colors.transparent,
                  BlendMode.darken,
                ),
                child: Image.asset(
                  'assets/images/kakao_login_large_wide.png',
                  width: 300,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
