# Gaussian Splatting Viewer Setup Guide

이 가이드는 Unity Gaussian Splatting Viewer를 설정하고 PLY 파일을 변환하는 방법을 설명합니다.

## 현재 상태

✅ Aras-p의 UnityGaussianSplatting 플러그인 설치 완료
✅ Unity-Flutter 통신 구조 구현 완료
❌ 런타임 PLY 로딩 미구현 (Unity Editor에서 사전 변환 필요)

## PLY 파일 변환 가이드

### 1단계: Unity Editor 열기

```bash
# Unity Hub를 통해 프로젝트 열기
# 또는 Unity Editor에서 직접 프로젝트 폴더 선택
open unity_gaussian_splatting_viewer
```

**필수 Unity 버전**: Unity 2022.3 이상 권장

**필수 Graphics API**:
- Windows: DX12 또는 Vulkan (DX11은 작동하지 않음)
- macOS: Metal
- Linux: Vulkan

### 2단계: PLY 파일 준비

PLY 파일을 Unity 프로젝트 외부의 임의 위치에 준비합니다.

예시:
```
~/Downloads/my_gaussian_splat.ply
```

**지원 형식**:
- Binary Little Endian PLY (3D Gaussian Splatting 표준 포맷)
- Scaniverse SPZ 포맷

### 3단계: GaussianSplatAsset 생성

1. Unity Editor 메뉴에서 선택:
   ```
   Tools → Gaussian Splats → Create GaussianSplatAsset
   ```

2. **Input PLY/SPZ File** 필드에 PLY 파일 경로 입력

3. **Output Folder** 선택 (기본값: `Assets/GaussianAssets`)

4. **Quality** 선택:
   - **Very High**: 무손실, 가장 큰 파일 크기 (1.05x 압축)
   - **High**: 고품질, 2.94x 압축
   - **Medium**: 중간 품질, 5.14x 압축 (권장)
   - **Low**: 낮은 품질, 14.01x 압축
   - **Very Low**: 최저 품질, 18.62x 압축

5. **Create Asset** 버튼 클릭

6. 변환 완료 대기 (파일 크기에 따라 몇 초~몇 분 소요)

### 4단계: 씬에 Gaussian Splat 추가

1. Unity 씬 열기: `Assets/Scenes/GaussianSplattingScene.unity`

2. Hierarchy에서 GameObject 생성:
   ```
   GameObject → Create Empty
   이름: "MySplatObject"
   ```

3. Inspector에서 컴포넌트 추가:
   ```
   Add Component → Gaussian Splat Renderer
   ```

4. **Gaussian Splat Renderer** 설정:
   - **m_Asset**: 생성한 GaussianSplatAsset 드래그 앤 드롭
   - **m_Shader Splats**: `GaussianSplatting/Shaders/RenderGaussianSplats.shader` 할당
   - **m_Shader Composite**: `GaussianSplatting/Shaders/GaussianComposite.shader` 할당
   - **m_Shader Debug Points**: `GaussianSplatting/Shaders/GaussianDebugRenderPoints.shader` 할당
   - **m_Shader Debug Boxes**: `GaussianSplatting/Shaders/GaussianDebugRenderBoxes.shader` 할당
   - **m_CS Splat Utilities**: `GaussianSplatting/Shaders/SplatUtilities.compute` 할당

5. Play 버튼을 눌러 테스트

### 5단계: Flutter 앱에 통합

**방법 1: Resources 폴더 사용 (권장)**

1. Asset을 Resources 폴더로 이동:
   ```
   Assets/Resources/GaussianAssets/my_splat.asset
   ```

2. Flutter에서 로드:
   - 현재 구현된 동적 다운로드 대신 Resources.Load 사용
   - UnityMessageManager에서 미리 로드된 Asset을 SplatLoader에 전달

**방법 2: 빌드에 포함**

1. Asset을 `StreamingAssets` 폴더에 복사:
   ```
   Assets/StreamingAssets/GaussianAssets/
   ```

2. SplatLoader 수정하여 StreamingAssets에서 로드

## 알려진 제약사항

### 런타임 동적 로딩 미지원

현재 구현은 Unity Editor에서 사전 변환을 요구합니다. 이는 Aras-p 플러그인의 설계상 제약입니다:

- ✅ Editor에서 PLY → 최적화된 Asset 변환
- ❌ 런타임에서 PLY 직접 로딩

### 향후 개선 계획

런타임 동적 로딩을 구현하려면:

1. **RuntimePLYLoader 완성**
   - PLY 바이너리 파싱
   - Morton reordering (옵션)
   - SH clustering (옵션)

2. **GaussianSplatAsset 런타임 생성**
   - TextAsset 없이 NativeArray로 데이터 보유
   - GPU 버퍼 직접 생성
   - GaussianSplatRenderer 수정

3. **예상 작업량**: 2-4시간

## 문제 해결

### "Runtime PLY loading is NOT YET IMPLEMENTED" 에러

**원인**: Flutter에서 다운로드한 PLY 파일을 Unity가 런타임에 직접 로드하려고 시도

**해결**:
1. 위의 가이드에 따라 Unity Editor에서 PLY를 Asset으로 변환
2. 변환된 Asset을 앱에 포함
3. SplatLoader를 수정하여 미리 변환된 Asset 사용

### 컴파일 에러: Shader/Compute Shader 없음

**해결**:
1. `Assets/GaussianSplatting/` 폴더가 제대로 복사되었는지 확인
2. Unity Editor에서 프로젝트 재임포트: `Assets → Reimport All`

### 플랫폼별 Graphics API 오류

**Windows**:
```
Edit → Project Settings → Player → Other Settings → Graphics APIs
- DX12 또는 Vulkan 추가
- DX11 제거
```

**macOS/iOS**:
- Metal 필수 (자동)

**Android**:
- Vulkan 권장
- 일부 디바이스는 지원하지 않을 수 있음

## 참고 자료

- [Aras-p/UnityGaussianSplatting GitHub](https://github.com/aras-p/UnityGaussianSplatting)
- [Gaussian Splatting 논문](https://repo-sam.inria.fr/fungraph/3d-gaussian-splatting/)
- [flutter_unity_widget 문서](https://pub.dev/packages/flutter_unity_widget)

## 다음 단계

1. ✅ Unity Editor에서 PLY 파일 변환
2. ⏳ 변환된 Asset을 Flutter 앱에 통합
3. ⏳ 동적 다운로드 대신 미리 포함된 Asset 사용
4. ⏳ (옵션) 런타임 PLY 로더 구현

---

**작성일**: 2025-11-28
**플러그인 버전**: UnityGaussianSplatting (main branch, commit: latest)
**Unity 버전**: 2022.3 이상
