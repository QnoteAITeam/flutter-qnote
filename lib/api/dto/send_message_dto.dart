//이 메세지는 누가 작성하였나.. system은 우리 서버측, assistance는.. AI, user는 유저
enum MessageRole { system, assistance, user }

//Ai의 상태, asking : 묻고 있음, done 이제 끝났고, text에는 일기의 내용
enum MessageState { asking, done }

class SendMessageDto {
  SendMessageDto({
    required this.role,
    required this.state,
    required this.message,
  });

  final MessageRole role;
  final MessageState state;
  final String message;

  factory SendMessageDto.fromJson(Map<String, dynamic> json) {
    return SendMessageDto(
      role: MessageRole.values.firstWhere(
        (e) => e.name == json['role'],
        orElse: () => MessageRole.user,
      ),
      state: MessageState.values.firstWhere(
        (e) => e.name == json['state'],
        orElse: () => MessageState.done,
      ),
      message: json['message'],
    );
  }

  factory SendMessageDto.dummy() {
    return SendMessageDto(
      state: MessageState.asking,
      message: '서버에서 응답이 없어서 그래, 이건 더미 값이야 뭐 오늘 하루 어땟는데?',
      role: MessageRole.assistance,
    );
  }

  Map<String, dynamic> toJson() {
    return {'role': role.name, 'state': state.name, 'message': message};
  }
}
