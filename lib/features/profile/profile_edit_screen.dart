import 'package:flutter/material.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          "프로필 수정",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),

      //프로필 이미지 + 카메라 아이콘
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(40),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.center,
              children: [
                const CircleAvatar(
                  radius: 90,
                  backgroundColor: Colors.grey,
                  child: Icon(Icons.person, size: 90, color: Colors.white),
                ),
                Positioned(
                  bottom: 0,
                  right: 10,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.grey.shade300, width: 1),
                    ),
                    padding: const EdgeInsets.all(10),
                    child: const Icon(Icons.camera_alt, size: 24, color: const Color(0xFF937B58)),
                  ),
                ),
              ],
            ),

            //더 추가하고 싶은 텍스트 필드가 있으면 동일한 방식으로 추가 구현
            const SizedBox(height: 50),
            _buildTextField(label: "이름", hint: "김김김"),
            _buildTextField(label: "이메일", hint: "kimkimkim@gmail.com"),
            _buildTextField(label: "전화번호", hint: "010-1234-5678"),
            _buildTextField(label: "생년월일", hint: "2003.12.31."),
            const SizedBox(height: 20),

            //저장 버튼
            Center(
              child: SizedBox(
                width: 220, // 원하는 가로 길이로 조절
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("저장되었습니다.")),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFE6DED1),
                    minimumSize: const Size.fromHeight(45),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "변경사항 저장하기",
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  //프로필 사진 아래에 있는 텍스트 필드 (동일한 스타일로 생성)
  Widget _buildTextField({required String label, required String hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        const SizedBox(height: 10),
        TextField(
          style: const TextStyle(fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontSize: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }
}
