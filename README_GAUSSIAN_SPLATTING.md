# 가우시안 스플래팅 뷰어 기능

## 🎯 개요

온기(Ongi) 유물 앱에 **가우시안 스플래팅(Gaussian Splatting)** 기술을 활용한 고품질 3D 모델 뷰어 기능이 추가되었습니다.

기존의 GLB 모델 뷰어와 별도로, 가우시안 스플래팅 기술을 통해 더 사실적이고 디테일한 3D 유물 모델을 확인할 수 있습니다.

---

## ✨ 주요 기능

### 1. 고품질 3D 렌더링
- **가우시안 스플래팅** 기술 기반 실시간 렌더링
- 포토리얼리스틱한 유물 표현
- Unity 엔진 기반 고성능 렌더링

### 2. 직관적인 3D 조작
- **1-finger 드래그**: 모델 회전
- **2-finger 핀치**: 줌 인/아웃
- **카메라 리셋**: 초기 위치로 복귀

### 3. 효율적인 파일 관리
- 필요할 때만 `.ply` 파일 다운로드
- 로컬 캐싱으로 재사용 시 즉시 로드
- 다운로드 진행률 실시간 표시

### 4. 원활한 사용자 경험
- Flutter 네이티브 UI + Unity 3D 뷰어 하이브리드
- 로딩 상태 및 에러 처리
- 모델 설명 및 정보 표시

---

## 📁 프로젝트 구조

```
ongi/
├── ongi_flutter/                    # Flutter 앱
│   ├── lib/
│   │   ├── providers/
│   │   │   └── gaussian_splatting_provider.dart  # 상태 관리
│   │   ├── services/
│   │   │   └── gaussian_splatting_service.dart   # 파일 다운로드/관리
│   │   └── screens/
│   │       ├── main/
│   │       │   └── home_screen.dart              # 버튼 추가
│   │       └── gaussian_splatting/
│   │           └── gaussian_splatting_viewer_screen.dart  # 뷰어 화면
│   └── pubspec.yaml                 # flutter_unity_widget 추가
│
├── unity_gaussian_splatting_viewer/ # Unity 프로젝트
│   └── Assets/
│       └── Scripts/
│           ├── SplatLoader.cs       # .ply 파일 로더
│           ├── OrbitCamera.cs       # 카메라 컨트롤러
│           └── UnityMessageManager.cs  # Flutter 통신
│
├── UNITY_INTEGRATION_GUIDE.md       # Unity 통합 가이드
└── README_GAUSSIAN_SPLATTING.md     # 이 파일
```

---

## 🚀 사용 방법

### 사용자 관점

1. **홈 화면**에서 우측 상단의 **"가우시안 스플래팅"** 버튼 클릭
2. 모델 다운로드 진행률 확인 (최초 1회)
3. Unity 뷰어가 로드되면 3D 모델 조작
   - 드래그하여 회전
   - 핀치하여 줌
   - 우측 상단 새로고침 버튼으로 카메라 리셋
4. 뒤로가기 버튼으로 홈 화면 복귀

### 개발자 관점

#### Flutter 측 사용 예시

```dart
import 'package:provider/provider.dart';
import 'package:ongi_flutter/providers/gaussian_splatting_provider.dart';
import 'package:ongi_flutter/screens/gaussian_splatting/gaussian_splatting_viewer_screen.dart';

// 가우시안 스플래팅 뷰어 열기
void openGaussianSplatting(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => GaussianSplattingViewerScreen(
        modelId: 'artifact_123',
        modelUrl: 'https://example.com/models/artifact_123.ply',
        modelName: '백제 금동대향로',
        description: '백제시대의 금동 향로',
      ),
    ),
  );
}

// 파일 다운로드 진행률 확인
Consumer<GaussianSplattingProvider>(
  builder: (context, provider, child) {
    if (provider.isDownloading) {
      return CircularProgressIndicator(
        value: provider.downloadProgress,
      );
    }
    return YourWidget();
  },
)
```

#### Unity 측 스크립트

```csharp
// Flutter에서 모델 로드 요청
public void LoadModel(string filePath)
{
    StartCoroutine(LoadModelCoroutine(filePath));
}

// Unity에서 Flutter로 메시지 전송
private void SendMessageToFlutter(string type, string message)
{
    string jsonMessage = $"{{\"type\":\"{type}\",\"message\":\"{message}\"}}";
    UnityMessageManager.Instance.SendMessageToFlutter(jsonMessage);
}
```

---

## 🔧 기술 스택

### Flutter
- **provider**: 상태 관리
- **dio**: HTTP 다운로드
- **path_provider**: 로컬 파일 관리
- **flutter_unity_widget**: Unity 임베딩

### Unity
- **Unity 2021.3+ LTS**: 게임 엔진
- **UnityGaussianSplatting**: Aras-p 플러그인
- **URP**: Universal Render Pipeline

---

## 📊 API 연동

### 백엔드 요구사항

3D 모델 API 응답에 가우시안 스플래팅 모델 URL 추가:

```json
{
  "id": "123",
  "artifact_name": "백제 금동대향로",
  "description": "백제시대의 금동 향로",
  "model_url": "/media/models/artifact_123.glb",
  "gaussian_model_url": "/media/gaussian/artifact_123.ply",  // 추가
  "status": "completed"
}
```

### .ply 파일 생성 방법

1. **3D 스캔** → Point Cloud 데이터 획득
2. **Nerfstudio** 또는 **3D Gaussian Splatting** 학습
3. `.ply` 파일 Export
4. **압축** (Super Splat 등) → 20~50MB 목표
5. 서버에 업로드

---

## 📱 빌드 가이드

### 1. Unity 프로젝트 Export

자세한 내용은 [UNITY_INTEGRATION_GUIDE.md](UNITY_INTEGRATION_GUIDE.md) 참조

```bash
# Android
Unity Editor -> File -> Build Settings -> Android -> Export

# iOS
Unity Editor -> File -> Build Settings -> iOS -> Build
```

### 2. Flutter 빌드

```bash
cd ongi_flutter

# Android APK
flutter build apk --release

# iOS IPA
flutter build ios --release
```

---

## 🐛 알려진 이슈

### 1. 첫 로딩 시간
- Unity 엔진 초기화: 1~2초 소요
- 해결: 로딩 오버레이로 UX 개선

### 2. 앱 크기 증가
- Unity 엔진 포함: 약 30~50MB 증가
- 해결: Code Stripping, App Bundle 사용

### 3. 메모리 사용량
- 대형 .ply 파일: 메모리 사용량 증가
- 해결: 화면 종료 시 모델 언로드, GC 호출

---

## 🔮 향후 계획

- [ ] AR(증강현실) 모드 추가
- [ ] 다중 모델 비교 뷰어
- [ ] 스크린샷 및 공유 기능
- [ ] 모델 애니메이션 지원
- [ ] WebGL 빌드로 웹 지원

---

## 📝 라이선스

MIT License

---

## 👥 기여자

- **Unity 스크립트**: AI Assistant
- **Flutter 통합**: AI Assistant
- **가우시안 스플래팅 플러그인**: [Aras Pranckevičius](https://github.com/aras-p/UnityGaussianSplatting)

---

## 📞 문의

기술 지원: GitHub Issues
