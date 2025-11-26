# Unity 가우시안 스플래팅 뷰어 통합 가이드

이 문서는 Flutter 앱에 Unity 가우시안 스플래팅 뷰어를 통합하는 방법을 설명합니다.

## 📋 목차

1. [개요](#개요)
2. [사전 준비](#사전-준비)
3. [Unity 프로젝트 설정](#unity-프로젝트-설정)
4. [Flutter와 Unity 연동](#flutter와-unity-연동)
5. [빌드 및 배포](#빌드-및-배포)
6. [트러블슈팅](#트러블슈팅)

---

## 개요

### 아키텍처

```
┌─────────────────────────────────────┐
│ Flutter (ongi_flutter)               │
│ ├─ 홈 화면 (가우시안 스플래팅 버튼)  │
│ ├─ .ply 파일 다운로드 서비스         │
│ ├─ GaussianSplattingProvider         │
│ └─ GaussianSplattingViewerScreen     │
└─────────────┬───────────────────────┘
              │ (파일 경로 전달)
              ▼
┌─────────────────────────────────────┐
│ Unity (unity_gaussian_splatting_     │
│        viewer)                       │
│ ├─ SplatLoader.cs                    │
│ ├─ OrbitCamera.cs                    │
│ ├─ UnityMessageManager.cs            │
│ └─ Aras-p/UnityGaussianSplatting     │
└─────────────────────────────────────┘
```

### 워크플로우

1. 사용자가 홈 화면에서 "가우시안 스플래팅" 버튼 클릭
2. Flutter가 서버에서 `.ply` 파일 다운로드 (진행률 표시)
3. 다운로드 완료 후 로컬 파일 경로 획득
4. Flutter → Unity로 파일 경로 전송
5. Unity가 `.ply` 파일 로드 및 렌더링
6. 사용자가 터치로 3D 모델 조작

---

## 사전 준비

### 필수 소프트웨어

1. **Unity Editor** (버전 2021.3 LTS 이상)
   - 다운로드: https://unity.com/download

2. **Android Build Support** (Android 빌드 시)
   - Unity Hub → Installs → 설치된 Unity 버전 → Add Modules
   - Android Build Support 체크

3. **iOS Build Support** (iOS 빌드 시)
   - Unity Hub → Installs → 설치된 Unity 버전 → Add Modules
   - iOS Build Support 체크
   - macOS에서만 가능

### Unity 패키지

- **UnityGaussianSplatting** by Aras-p
  - GitHub: https://github.com/aras-p/UnityGaussianSplatting

---

## Unity 프로젝트 설정

### 1단계: Unity 프로젝트 생성

1. Unity Hub 열기
2. **New Project** 클릭
3. 템플릿: **3D (URP - Universal Render Pipeline)** 선택
4. 프로젝트 이름: `UnityGaussianSplattingViewer`
5. 위치: `<ongi-project>/unity_gaussian_splatting_viewer`
6. **Create Project** 클릭

### 2단계: UnityGaussianSplatting 패키지 설치

#### 방법 1: Unity Package Manager (권장)

1. Unity Editor에서 **Window** → **Package Manager** 열기
2. 좌측 상단 **+** 버튼 클릭
3. **Add package from git URL** 선택
4. 입력: `https://github.com/aras-p/UnityGaussianSplatting.git`
5. **Add** 클릭

#### 방법 2: Manual 설치

1. GitHub에서 저장소 다운로드
2. `Assets/Plugins/UnityGaussianSplatting` 폴더에 복사

### 3단계: 스크립트 추가

프로젝트 루트의 `unity_gaussian_splatting_viewer/Assets/Scripts` 폴더에 다음 스크립트들이 준비되어 있습니다:

- `SplatLoader.cs` - .ply 파일 로더
- `OrbitCamera.cs` - 카메라 컨트롤러
- `UnityMessageManager.cs` - Flutter 통신 매니저

이 파일들을 Unity 프로젝트의 `Assets/Scripts` 폴더로 복사하세요:

```bash
# 프로젝트 루트에서 실행
cp unity_gaussian_splatting_viewer/Assets/Scripts/*.cs \
   <Unity-Project-Path>/Assets/Scripts/
```

### 4단계: Unity 씬 설정

#### 4.1 새 씬 생성

1. **Assets** → **Create** → **Scene**
2. 이름: `GaussianSplattingViewer`
3. 더블클릭하여 씬 열기

#### 4.2 GameObjects 추가

**1) Main Camera 설정**

- Hierarchy에 있는 기본 Main Camera 선택
- Inspector에서 **Add Component** → `OrbitCamera` 추가
- 설정:
  - Rotation Speed: 5
  - Min Distance: 2
  - Max Distance: 50
  - Initial Distance: 10

**2) Gaussian Splatting Loader 생성**

- Hierarchy에서 우클릭 → **Create Empty**
- 이름: `SplatLoader`
- Inspector에서 **Add Component** → `SplatLoader` 추가
- Inspector에서 **Add Component** → `GaussianSplatRenderer` 추가

**3) Message Manager 생성**

- Hierarchy에서 우클릭 → **Create Empty**
- 이름: `UnityMessageManager`
- Inspector에서 **Add Component** → `UnityMessageManager` 추가

**4) SplatLoader 연결**

- Hierarchy에서 `SplatLoader` 선택
- Inspector의 `SplatLoader` 컴포넌트에서:
  - **Splat Renderer**: `SplatLoader` GameObject 자기 자신 드래그

#### 4.3 씬 저장

- **File** → **Save** (Ctrl+S)
- **File** → **Build Settings** 열기
- **Add Open Scenes** 클릭하여 현재 씬 추가

### 5단계: 빌드 설정

#### Android 빌드 설정

1. **File** → **Build Settings**
2. **Platform**: Android 선택
3. **Switch Platform** 클릭
4. **Player Settings** 클릭
5. 설정:
   - **Company Name**: `com.yourcompany`
   - **Product Name**: `UnityGaussianSplattingViewer`
   - **Other Settings** → **Minimum API Level**: Android 7.0 (API Level 24)
   - **Other Settings** → **Scripting Backend**: IL2CPP
   - **Other Settings** → **Target Architectures**: ARM64 체크

#### iOS 빌드 설정

1. **File** → **Build Settings**
2. **Platform**: iOS 선택
3. **Switch Platform** 클릭
4. **Player Settings** 클릭
5. 설정:
   - **Company Name**: `com.yourcompany`
   - **Product Name**: `UnityGaussianSplattingViewer`
   - **Other Settings** → **Target minimum iOS Version**: 12.0

---

## Flutter와 Unity 연동

### 1단계: Unity Export

#### Android Export

1. Unity Editor에서 **File** → **Build Settings**
2. **Android** 플랫폼 선택
3. **Export Project** 체크
4. **Export** 클릭
5. 경로: `<flutter-project>/android/unityLibrary`

```bash
# 예시 경로
/home/user/ongi/ongi_flutter/android/unityLibrary
```

#### iOS Export

1. Unity Editor에서 **File** → **Build Settings**
2. **iOS** 플랫폼 선택
3. **Build** 클릭
4. 경로: `<flutter-project>/ios/UnityExport`

### 2단계: Flutter 프로젝트 설정

#### Android 설정

`ongi_flutter/android/settings.gradle`에 추가:

```gradle
include ':unityLibrary'
project(':unityLibrary').projectDir = file('./unityLibrary')
```

`ongi_flutter/android/app/build.gradle`에 추가:

```gradle
dependencies {
    implementation project(':unityLibrary')
    // ... 기존 dependencies
}
```

#### iOS 설정

`ongi_flutter/ios/Podfile`에 추가:

```ruby
# Unity Framework
unity_path = File.expand_path('../UnityExport', __FILE__)
pod 'UnityFramework', :path => "#{unity_path}"
```

### 3단계: 패키지 설치

프로젝트 루트에서:

```bash
cd ongi_flutter
flutter pub get
```

### 4단계: 빌드 테스트

#### Android

```bash
cd ongi_flutter
flutter build apk --debug
```

#### iOS

```bash
cd ongi_flutter
flutter build ios --debug
```

---

## 빌드 및 배포

### Android APK 빌드

```bash
cd ongi_flutter
flutter build apk --release
```

생성 위치: `ongi_flutter/build/app/outputs/flutter-apk/app-release.apk`

### iOS IPA 빌드

```bash
cd ongi_flutter
flutter build ios --release
```

그 후 Xcode에서 Archive 및 IPA 생성

---

## 트러블슈팅

### 문제 1: "UnityPlayer not found" 에러

**원인**: Unity Export가 제대로 되지 않았거나 경로 설정이 잘못됨

**해결**:
1. Unity에서 Export 다시 실행
2. `settings.gradle` 및 `build.gradle` 경로 확인
3. Android Studio에서 프로젝트 Clean 및 Rebuild

### 문제 2: ".ply 파일을 로드할 수 없음"

**원인**: 파일 권한 문제 또는 경로 오류

**해결**:
1. AndroidManifest.xml에 권한 추가:
```xml
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

2. Flutter에서 `permission_handler` 패키지로 런타임 권한 요청

### 문제 3: Unity 화면이 검은색으로 표시됨

**원인**: Unity 씬이 제대로 로드되지 않음

**해결**:
1. Unity Build Settings에서 씬이 추가되었는지 확인
2. `GaussianSplattingViewer` 씬이 Index 0인지 확인
3. Unity Export 다시 실행

### 문제 4: Flutter ↔ Unity 통신이 안 됨

**원인**: Message Manager 설정 누락

**해결**:
1. Unity 씬에 `UnityMessageManager` GameObject가 있는지 확인
2. `UnityMessageManager.cs` 스크립트가 제대로 연결되었는지 확인
3. Android/iOS 네이티브 브리지 코드 확인

### 문제 5: 앱 크기가 너무 큼

**원인**: Unity 엔진 포함으로 인한 크기 증가

**해결**:
1. Unity Player Settings에서:
   - **Stripping Level**: High로 설정
   - **Managed Stripping Level**: High로 설정
2. 사용하지 않는 Unity 모듈 제거
3. Android App Bundle (.aab) 사용

---

## 추가 참고 자료

- **UnityGaussianSplatting**: https://github.com/aras-p/UnityGaussianSplatting
- **flutter_unity_widget**: https://pub.dev/packages/flutter_unity_widget
- **Unity Manual**: https://docs.unity3d.com/

---

## 라이선스

이 프로젝트는 MIT 라이선스를 따릅니다.
