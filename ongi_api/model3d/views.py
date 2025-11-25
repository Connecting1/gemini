from django.shortcuts import get_object_or_404
from rest_framework import status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated, IsAdminUser
from .models import Model3D, SourceImage
from .serializers import (
    Model3DSerializer, 
    Model3DDetailSerializer, 
    Model3DCreateSerializer,
    ModelStatusUpdateSerializer
)
from artifacts.models import Artifact

@api_view(['GET'])
def model3d_list_view(request):
    """3D 모델 목록 조회"""
    # 상태에 따른 필터링 (기본: 완료된 모델)
    status_filter = request.query_params.get('status', 'completed')
    
    if status_filter == 'all' and request.user.is_staff:
        # 관리자는 모든 상태의 모델 조회 가능
        models = Model3D.objects.all().order_by('-created_at')
    elif status_filter == 'all':
        # 일반 사용자는 완료된 모델만 조회 가능
        models = Model3D.objects.filter(status='completed').order_by('-created_at')
    else:
        # 특정 상태의 모델만 조회
        models = Model3D.objects.filter(status=status_filter).order_by('-created_at')
    
    serializer = Model3DSerializer(models, many=True)
    return Response(serializer.data)

@api_view(['GET'])
def model3d_detail_view(request, model_id):
    """3D 모델 상세 정보 조회"""
    model = get_object_or_404(Model3D, id=model_id)
    
    # 완료되지 않은 모델은 관리자만 조회 가능
    if model.status != 'completed' and not request.user.is_staff:
        return Response({"detail": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
    
    serializer = Model3DDetailSerializer(model)
    return Response(serializer.data)

@api_view(['GET'])
def artifact_models_view(request, artifact_id):
    """특정 유물의 3D 모델 목록 조회"""
    artifact = get_object_or_404(Artifact, id=artifact_id)
    
    # 거부된 유물은 관리자만 조회 가능
    if artifact.status == 'rejected' and not request.user.is_staff:
        return Response({"detail": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
    
    # 일반 사용자는 완료된 모델만 조회 가능
    if request.user.is_staff:
        models = artifact.models.all().order_by('-created_at')
    else:
        models = artifact.models.filter(status='completed').order_by('-created_at')
    
    serializer = Model3DSerializer(models, many=True)
    return Response(serializer.data)

@api_view(['POST'])
@permission_classes([IsAuthenticated, IsAdminUser])
def create_model_request_view(request, artifact_id):
    """3D 모델 생성 요청 (관리자 전용)"""
    artifact = get_object_or_404(Artifact, id=artifact_id)
    
    serializer = Model3DCreateSerializer(data=request.data)
    if serializer.is_valid():
        # 같은 유물에 대해 처리 중인 모델이 있는지 확인
        existing_model = Model3D.objects.filter(
            artifact=artifact, 
            status__in=['pending', 'processing']
        ).first()
        
        if existing_model:
            return Response(
                {"detail": f"이미 처리 중인 모델이 있습니다. (ID: {existing_model.id}, 상태: {existing_model.status})"},
                status=status.HTTP_400_BAD_REQUEST
            )
        
        # 새 모델 생성
        model = Model3D.objects.create(
            artifact=artifact,
            file_format=serializer.validated_data['file_format'],
            status='pending',
            model_url='',  # 처리 완료 후 업데이트됨
        )
        
        # 여기에 비동기 작업 시작 로직 추가 (Celery 등)
        # start_model_generation_task.delay(model.id)
        
        response_serializer = Model3DSerializer(model)
        return Response(response_serializer.data, status=status.HTTP_201_CREATED)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

@api_view(['PATCH'])
@permission_classes([IsAdminUser])
def update_model_status_view(request, model_id):
    """3D 모델 상태 업데이트 (관리자 전용)"""
    model = get_object_or_404(Model3D, id=model_id)
    
    serializer = ModelStatusUpdateSerializer(data=request.data)
    if serializer.is_valid():
        # 상태 업데이트
        model.status = serializer.validated_data['status']
        
        # 추가 필드 업데이트 (제공된 경우)
        if 'processing_time' in serializer.validated_data:
            model.processing_time = serializer.validated_data['processing_time']
        
        if 'poly_count' in serializer.validated_data:
            model.poly_count = serializer.validated_data['poly_count']
            
        if 'file_size' in serializer.validated_data:
            model.file_size = serializer.validated_data['file_size']
        
        model.save()
        
        response_serializer = Model3DSerializer(model)
        return Response(response_serializer.data)
    
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)