// lib/features/profile/profile_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_qnote/api/user_api.dart';
import 'package:flutter_qnote/features/login/login_screen.dart';
import 'package:flutter_qnote/features/profile/profile_edit_screen.dart';
import 'package:flutter_qnote/features/profile/setting_screen.dart';
import 'package:flutter_qnote/features/profile/customer_support_screen.dart';
import 'package:flutter_qnote/auth/auth_api.dart'; // AuthApi 경로 확인
// import 'package:flutter_qnote/models/user.dart'; // 실제 User 모델 경로 확인 (필요시)

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = '김김김';
  String _userEmail = 'kimkimkim@gmail.com';
  String _userPhoneNumber = '010-1234-5678';
  String? _userAvatarUrl;
  final String _defaultAvatarAsset = 'assets/images/ai_avatar.png';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    // TODO: 실제 API 또는 로컬 저장소에서 사용자 정보를 가져와 상태를 업데이트합니다.
    final userInfo = await UserApi.instance.getUserCredential();

    if (mounted) {
      setState(() {
        // 이곳에서 실제 사용자 정보를 가져와 _userName, _userEmail 등을 업데이트
        _userName = userInfo.username; // 기본값 설정
        _userPhoneNumber =
            userInfo.phoneNumber ?? '전화번호가 아직 등록되지 않았습니다.'; // 기본값 설정
        _userEmail = userInfo.email; // 기본값 설정
        _userAvatarUrl =
            userInfo.profileImage ?? null; // 프로필 이미지 URL이 없을 경우 null로 설정
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthApi.getInstance.logout();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginScreen()),
          (Route<dynamic> route) => false,
        );
      }
    } catch (e) {
      print('Logout error: $e');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('로그아웃 중 오류가 발생했습니다: $e')));
      }
    }
  }

  Widget _buildProfileInfoSection() {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircleAvatar(
            radius: 55,
            backgroundColor: Colors.grey.shade200,
            backgroundImage:
                _userAvatarUrl != null && _userAvatarUrl!.isNotEmpty
                    ? NetworkImage(_userAvatarUrl!)
                    : AssetImage(_defaultAvatarAsset) as ImageProvider,
            onBackgroundImageError:
                _userAvatarUrl != null && _userAvatarUrl!.isNotEmpty
                    ? (exception, stackTrace) {
                      print('Error loading profile image: $exception');
                    }
                    : null,
          ),
          const SizedBox(height: 16),
          Text(
            _userName,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.email_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                _userEmail,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.phone_outlined, size: 16, color: Colors.grey.shade600),
              const SizedBox(width: 6),
              Text(
                _userPhoneNumber,
                style: TextStyle(fontSize: 14, color: Colors.grey.shade700),
              ),
            ],
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const ProfileEditScreen(),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFF0EBE5),
              foregroundColor: Colors.brown.shade700,
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              elevation: 0,
            ),
            child: const Text(
              '프로필 수정',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMenuListItem({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    Color? iconColor,
    Color? textColor,
  }) {
    return Material(
      color: Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
          child: Row(
            children: [
              Icon(icon, color: iconColor ?? Colors.grey.shade700, size: 22),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    color: textColor ?? Colors.black87,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: Colors.grey.shade400,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // AppBar를 제거하고, DashboardScreen에서 AppBar를 제공하므로 Scaffold의 appBar 속성은 사용하지 않음.
    // 전체 배경색은 DashboardScreen의 Scaffold에서 이미 Color(0xFFF4F6F8)로 설정되어 있음.
    // 필요하다면 여기서 Container로 감싸고 배경색을 설정할 수 있지만,
    // 일반적으로는 DashboardScreen의 배경색을 따름.
    return Container(
      // ProfileScreen 컨텐츠의 배경색 설정 (메뉴 그룹 사이의 간격 색)
      color: Colors.grey.shade100,
      child: ListView(
        padding: EdgeInsets.zero, // ListView의 기본 패딩 제거
        children: [
          // DashboardScreen의 AppBar 아래부터 프로필 내용이 시작됨
          _buildProfileInfoSection(),
          const SizedBox(height: 8), // 섹션 간 간격
          Container(
            color: Colors.white,
            child: Column(
              children: [
                _buildMenuListItem(
                  icon: Icons.settings_outlined,
                  title: '설정',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const SettingScreen(),
                      ),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  thickness: 0.5,
                ),
                _buildMenuListItem(
                  icon: Icons.headset_mic_outlined,
                  title: '고객센터',
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CustomerSupportScreen(),
                      ),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  thickness: 0.5,
                ),
                _buildMenuListItem(
                  icon: Icons.article_outlined,
                  title: '운영정책',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('운영정책 기능은 준비 중입니다.')),
                    );
                  },
                ),
                const Divider(
                  height: 1,
                  indent: 20,
                  endIndent: 20,
                  thickness: 0.5,
                ),
                _buildMenuListItem(
                  icon: Icons.campaign_outlined,
                  title: '공지사항',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('공지사항 기능은 준비 중입니다.')),
                    );
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Container(
            color: Colors.white,
            child: _buildMenuListItem(
              icon: Icons.logout,
              title: '로그아웃',
              iconColor: Colors.red.shade600,
              textColor: Colors.red.shade600,
              onTap: () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      title: const Text(
                        '로그아웃',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      content: const Text('정말로 로그아웃 하시겠습니까?'),
                      actionsAlignment: MainAxisAlignment.spaceEvenly,
                      actions: <Widget>[
                        TextButton(
                          child: const Text(
                            '취소',
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                        TextButton(
                          child: const Text(
                            '로그아웃',
                            style: TextStyle(
                              color: Colors.red,
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            _handleLogout();
                          },
                        ),
                      ],
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
