import 'package:flutter/material.dart';

class EmailPasswordForm extends StatefulWidget {
  const EmailPasswordForm({super.key});

  @override
  State<EmailPasswordForm> createState() => _EmailPasswordFormState();
}

class _EmailPasswordFormState extends State<EmailPasswordForm> {
  final _formKey = GlobalKey<FormState>();

  String _enteredEmail = '';
  String _enteredPassword = '';

  void _saveData() {
    final isValid = _formKey.currentState!.validate();
    if (!isValid) return;

    _formKey.currentState!.save();
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Expanded(
        child: Column(
          children: [
            TextFormField(
              decoration: InputDecoration(
                labelText: '이메일',
                //
              ),

              autocorrect: false,
              keyboardType: TextInputType.emailAddress,

              validator: (value) {
                if (value == null ||
                    value.isEmpty ||
                    value.trim().length == 0) {
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
          ],
        ),
      ),
    );
  }
}
