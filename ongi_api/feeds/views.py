from django.shortcuts import get_object_or_404
from django.db.models import F
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from .models import Feed, FeedImage
from .serializers import FeedSerializer, FeedImageSerializer
from artifacts.models import check_and_create_artifact

@api_view(['GET', 'POST'])
@permission_classes([IsAuthenticated])
def feed_list_create_view(request):
    """피드 목록 조회 및 생성"""
    if request.method == 'GET':
        # 관리자는 모든 피드 조회 가능, 일반 사용자는 공개된 피드만 조회
        if request.user.is_staff:
            feeds = Feed.objects.all().order_by('-created_at')
        else:
            feeds = Feed.objects.filter(status='published').order_by('-created_at')
        
        serializer = FeedSerializer(feeds, many=True)
        return Response(serializer.data)
    
    elif request.method == 'POST':
        # POST 요청에서 user는 현재 로그인한 사용자로 자동 설정
        serializer = FeedSerializer(data=request.data)
        if serializer.is_valid():
            # 인증된 사용자를 피드 작성자로 설정
            feed = serializer.save(user=request.user)
            
            # 유물 자동 생성 검사 (artifact_name으로 10장 이상 모였는지)
            if feed.status == 'published':
                check_and_create_artifact(feed.artifact_name)
            
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def feed_detail_view(request, feed_id):
    """피드 상세 조회"""
    feed = get_object_or_404(Feed, id=feed_id)
    
    # 비공개 피드는 작성자나 관리자만 조회 가능
    if feed.status != 'published' and not (request.user == feed.user or request.user.is_staff):
        return Response({"detail": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
    
    # 자신의 피드가 아닌 경우 조회수 증가
    if request.user.id != feed.user.id:
        feed.view_count = F('view_count') + 1
        feed.save()
        feed.refresh_from_db()  # F() 표현식 사용 후 최신 값 가져오기
    
    serializer = FeedSerializer(feed)
    return Response(serializer.data)

@api_view(['PUT', 'PATCH'])
@permission_classes([IsAuthenticated])
def feed_update_view(request, feed_id):
    """피드 업데이트"""
    feed = get_object_or_404(Feed, id=feed_id)
    
    # 피드 작성자나 관리자만 수정 가능
    if request.user != feed.user and not request.user.is_staff:
        return Response({"detail": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
    
    serializer = FeedSerializer(feed, data=request.data, partial=True)
    if serializer.is_valid():
        serializer.save()
        return Response(serializer.data)
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['DELETE'])
@permission_classes([IsAuthenticated])
def feed_delete_view(request, feed_id):
    """피드 삭제"""
    feed = get_object_or_404(Feed, id=feed_id)
    
    # 피드 작성자나 관리자만 삭제 가능
    if request.user != feed.user and not request.user.is_staff:
        return Response({"detail": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
    
    feed.delete()
    return Response(status=status.HTTP_204_NO_CONTENT)

@api_view(['GET'])
@permission_classes([IsAuthenticated])
def my_feeds_view(request):
    """자신의 피드 목록 조회"""
    feeds = Feed.objects.filter(user=request.user).order_by('-created_at')
    serializer = FeedSerializer(feeds, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated])
def upload_feed_images(request, feed_id):
    """피드에 이미지 업로드"""
    feed = get_object_or_404(Feed, id=feed_id)
    
    # 피드 작성자만 이미지 업로드 가능
    if request.user != feed.user:
        return Response({"detail": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
    
    # 이미지 파일 리스트 확인
    images = request.FILES.getlist('images')
    if not images:
        return Response({"detail": "이미지 파일이 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)
    
    # 현재 피드의 이미지 수 확인하여 순서 지정
    current_max_order = FeedImage.objects.filter(feed=feed).order_by('-order').first()
    start_order = (current_max_order.order + 1) if current_max_order else 0
    
    # 이미지 저장 및 FeedImage 객체 생성
    image_data = []
    for i, image_file in enumerate(images):
        # 이미지 파일 저장 로직 (실제 구현 필요)
        image_url = _save_image(image_file, feed.id, start_order + i)
        
        # FeedImage 객체 생성
        feed_image = FeedImage.objects.create(
            feed=feed,
            image_url=image_url,
            order=start_order + i
        )
        
        image_data.append({
            'id': feed_image.id,
            'image_url': feed_image.image_url,
            'order': feed_image.order
        })
    
    # 이미지가 업로드된 후 유물 자동 생성 검사
    check_and_create_artifact(feed.artifact_name)
    
    return Response(image_data, status=status.HTTP_201_CREATED)

def _save_image(image_file, feed_id, order):
    from django.conf import settings
    import os
    
    # 저장 경로 생성
    upload_dir = os.path.join(settings.MEDIA_ROOT, 'feeds', str(feed_id))
    os.makedirs(upload_dir, exist_ok=True)
    
    # 파일명 생성
    filename = f"image_{order}_{image_file.name}"
    filepath = os.path.join(upload_dir, filename)
    
    # 파일 저장
    with open(filepath, 'wb+') as destination:
        for chunk in image_file.chunks():
            destination.write(chunk)
    
    # URL 경로 생성 시 슬래시 정규화 (여기가 수정 부분)
    relative_path = os.path.join('feeds', str(feed_id), filename).replace('\\', '/')
    url = f"{settings.MEDIA_URL}{relative_path}"
    
    return url