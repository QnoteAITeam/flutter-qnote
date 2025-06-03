## 📱 Qnote 앱 다운 후 빌드 및 실행방법

- flutter pub get
- flutter run

## 📱 Qnote env 파일 다운방법

Mobile. 010-3154-0982
Email. hhs2003@o.cnu.ac.kr 

## 📱 Qnote 앱 화면별 구현 및 사용 모듈 명세

## 1. 대시보드(Dashboard) 화면

**주요 모듈 및 패키지**
- `flutter/material.dart`: Flutter UI 프레임워크
- `flutter_qnote/api/diary_api.dart`: 일기 API 연동
- `flutter_qnote/api/user_api.dart`: 사용자 정보 API
- `flutter_qnote/api/dto/get_user_info_dto.dart`, `get_diary_info_dto.dart`: DTO 변환
- `flutter_qnote/models/diary.dart`, `models/user.dart`: 데이터 모델
- `widgets/calendar_widget.dart`: 커스텀 캘린더
- `widgets/dashboard_app_bar.dart`: 상단 바
- `widgets/greeting_card_widget.dart`: 인사 카드
- `widgets/diary_summary_section_widget.dart`: 일기 요약 섹션
- `features/search/search_screen.dart`, `features/search/search_home_screen.dart`: 검색 화면
- `features/chat/chat_screen.dart`: 채팅 화면
- `features/profile/profile_screen.dart`: 프로필 화면
- `features/schedule/schedule_screen.dart`: 일정 화면
- `features/diary/diary_detail_screen.dart`: 일기 상세
- `auth/auth_api.dart`: 인증 및 토큰 관리

**구현 방법 및 특징**
- `StatefulWidget`과 `WidgetsBindingObserver`로 앱 라이프사이클 및 상태 관리
- 앱 실행/복귀 시 사용자 인증 및 일기 데이터 자동 갱신
- API에서 일기/사용자 정보 fetch, DTO → 모델 변환, 상태에 따라 위젯 갱신
- 캘린더 날짜 클릭 시 해당 일기 상세 화면으로 이동 (`Navigator`)
- 오늘의 일기 요약, 주간 일기 작성 횟수 등 통계 정보 표시
- 인증 실패/세션 만료 시 안내 메시지 및 로그인 화면 리다이렉트
- `BottomNavigationBar`와 `FloatingActionButton`으로 주요 화면 전환 및 채팅 진입
- 비동기 데이터 로딩 중 로딩 인디케이터, 오류 발생 시 스낵바 안내

**UI/UX**
- 홈, 검색, 채팅, 일정, 프로필 등 탭 구조
- 캘린더와 일기 요약, 인사 카드, 오늘의 일기 상태 표시
- 하단 FloatingActionButton으로 채팅 진입

---

## 2. 채팅(Chat) 화면

**주요 모듈 및 패키지**
- `flutter/material.dart`: UI 구성
- `intl`: 날짜/시간 포맷
- `flutter_qnote/api/api_service.dart`: AI 챗봇 세션 및 메시지 송수신
- `flutter_qnote/api/diary_api.dart`: 일기 관련 API
- `widgets/chat_app_bar.dart`: 채팅 상단 바
- `widgets/chat_message_bubble.dart`: 채팅 메시지 버블
- `widgets/shimmer_loading_bubble.dart`: AI 응답 대기 shimmer 효과
- `widgets/save_diary_widget.dart`: 일기 저장 버튼
- `widgets/chat_input_area.dart`: 메시지 입력창

**구현 방법 및 특징**
- `StatefulWidget`으로 메시지, 세션, AI 응답 등 상태 관리
- 앱 진입 시 API로 챗봇 세션 생성, 오류 시 안내 메시지
- 메시지 입력 → DTO 변환 → API 전송 → AI 응답 수신 후 채팅 리스트에 추가
- 새로운 메시지 도착 시 자동 스크롤 하단 이동 (`ScrollController`)
- AI 예측 답변 옵션 캐싱 및 빠른 UI 반응
- AI가 일기 요약 제안 시 요약/제목/태그 추출 후 일기 저장 버튼 활성화
- '바로 일기 정리해줘' 클릭 시 일기 상세 화면으로 이동 및 저장
- 커스텀 메시지 버블, shimmer 로딩, 예측 답변 옵션(가로 스크롤), 입력창 하단 첨부 안내, 전체화면 키보드 내리기 등 UI/UX 최적화

**UI/UX**
- 채팅 메시지 커스텀 버블
- AI 응답 대기 중 shimmer 효과
- 예측 답변 옵션(OutlinedButton, 가로 스크롤)
- 입력창 하단 첨부 안내
- 전체 화면 어디서나 키보드 내리기 (GestureDetector)

---

## 3. 일기 상세(Diary Detail) 화면

**주요 모듈 및 패키지**
- `flutter/material.dart`: UI 프레임워크
- `flutter_qnote/api/diary_api.dart`: 일기 저장/수정 API
- `flutter_qnote/models/diary.dart`: 일기 데이터 모델
- `flutter_qnote/api/dto/get_diary_info_dto.dart`: DTO 변환
- `intl`: 날짜 포맷
- `widgets/date_selector_widget.dart`: 날짜 선택 위젯

**구현 방법 및 특징**
- 전달받은 일기/AI 요약/제목/태그 등으로 초기값 세팅
- 제목, 날짜, 내용, 태그 입력 필드 제공 (TextField)
- 날짜 선택은 커스텀 DateSelectorWidget 사용
- 저장/수정 시 API 연동 및 결과 반환
- 저장 성공 시 이전 화면에서 성공 메시지 출력
- 태그 입력은 쉼표/공백 분리, 중복 제거
- 에러(네트워크, 인증 등) 발생 시 스낵바 안내

**UI/UX**
- 제목, 날짜, 내용, 태그 입력 필드 섹션별 구분
- 저장 버튼(상단 아이콘) 및 로딩 인디케이터
- 상세/편집 모드에 따라 UI 동적 변화

---

## 4. 프로필(Profile) 화면

**주요 모듈 및 패키지**
- `flutter/material.dart`: UI 프레임워크
- `flutter_qnote/api/user_api.dart`: 사용자 정보 API
- `flutter_qnote/features/login/login_screen.dart`: 로그인 화면 연동
- `flutter_qnote/features/profile/profile_edit_screen.dart`: 프로필 편집
- `flutter_qnote/features/profile/setting_screen.dart`: 설정
- `flutter_qnote/features/profile/customer_support_screen.dart`: 고객센터
- `flutter_qnote/auth/auth_api.dart`: 인증 및 로그아웃

**구현 방법 및 특징**
- 사용자 정보(이름, 이메일, 전화번호, 프로필 이미지) API로 fetch 및 상태 관리
- 프로필 수정, 설정, 고객센터, 운영정책, 공지사항 등 메뉴 제공
- 로그아웃 시 AuthApi 연동 및 로그인 화면으로 이동
- 각 메뉴 클릭 시 해당 화면 또는 안내 메시지 노출

**UI/UX**
- 프로필 정보(아바타, 이름, 이메일, 전화번호) 상단 표시
- 메뉴 리스트(설정, 고객센터, 운영정책, 공지사항)
- 로그아웃 버튼(다이얼로그 확인 후 처리)
- 전체 배경색 및 섹션 구분

---

## 5. 일정(Schedule) 화면

**주요 모듈 및 패키지**
- `flutter/material.dart`: UI 프레임워크
- `flutter_qnote/api/schedule/schedule_api.dart`: 일정 API
- `features/schedule/widgets/schedule_holder_widget.dart`: 일정 카드 위젯
- `intl`: 날짜 포맷

**구현 방법 및 특징**
- 주간 단위로 날짜 선택(가로 스크롤), 선택 날짜에 따른 일정 fetch
- 일정 목록 비동기 로딩 및 상태 관리
- 일정 추가 버튼(기능 준비 중), 일정 상세/수정 연동 가능
- 일정 데이터는 API에서 받아와 포맷팅 후 리스트로 표시

**UI/UX**
- 상단 날짜/요일/월 헤더
- 가로 스크롤 날짜 선택기
- 일정 카드 리스트(중요 일정 강조)
- 일정 없을 때 안내 메시지
- 하단 일정 추가 버튼(고정)

---

## 6. 검색(Search) 화면

**주요 모듈 및 패키지**
- `flutter/material.dart`: UI 프레임워크
- `flutter_qnote/api/diary_api.dart`: 일기 검색 API
- `flutter_qnote/api/dto/get_diary_info_dto.dart`: DTO 변환
- `flutter_qnote/models/diary.dart`: 일기 데이터 모델
- `features/diary/diary_detail_screen.dart`: 일기 상세 연동
- `intl`: 날짜 포맷

**구현 방법 및 특징**
- 검색어 입력 후 일기 검색 API 호출, 결과 리스트로 표시
- 일기 카드 클릭 시 상세 화면으로 이동
- 비동기 로딩 및 상태 관리
- 검색 결과 없을 때 안내 메시지

**UI/UX**
- 상단 AppBar 내 검색 입력창
- 검색 결과 리스트(카드 형태)
- 일기 제목, 요약, 작성일 표시

---

## 7. 인트로/스플래시/로그인 화면

**인트로(튜토리얼)**
- `PageView` 기반 슬라이드 튜토리얼
- 마지막 페이지에서 '시작하기' 클릭 시 대시보드로 이동, 첫 실행 여부는 `flutter_secure_storage`로 관리

**스플래시**
- 앱 실행 시 로고 및 앱명 표시, 최초 실행 여부에 따라 인트로 또는 대시보드로 자동 이동

**로그인**
- 이메일/비밀번호, 카카오, 구글 등 다양한 로그인 방식 지원
- 로그인 성공 시 대시보드로 라우팅, 실패 시 에러 메시지 표시
- 회원가입, 이메일/비밀번호 찾기, 약관 동의 등 부가 기능 제공

---

## 8. 공통 구조 및 모듈화

- 각 기능별로 별도 폴더 및 파일로 분리(modularization)
- 주요 화면은 `features` 디렉터리 하위에 관리, 공통 위젯은 `widgets` 폴더에 위치
- DTO, 모델, API, 인증 등은 별도 디렉터리로 관리하여 유지보수성 향상
- 전역 상태/인증/네비게이션 등은 싱글턴 패턴 및 Provider 등 상태관리 도구 활용

---
