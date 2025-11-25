from django.db import models
import uuid
from artifacts.models import Artifact


class Model3D(models.Model):
    """
    유물의 3D 모델 정보를 저장하는 모델
    GLB 파일 전용으로 최적화됨
    """
    # 클래스 상수로 선택지 정의
    FILE_FORMAT_CHOICES = [
        ('glb', 'GLB'),
        ('gltf', 'GLTF'),
        ('other', '기타'),
    ]
    
    STATUS_CHOICES = [
        ('pending', '대기 중'),
        ('processing', '처리 중'),
        ('completed', '완료'),
        ('failed', '실패'),
    ]
    
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    artifact = models.ForeignKey(Artifact, on_delete=models.CASCADE, related_name='models')
    model_url = models.FileField(upload_to='models/')
    thumbnail_url = models.ImageField(upload_to='models/thumbnails/', blank=True, null=True)  # 3D 모델 썸네일 이미지
    
    file_format = models.CharField(
        max_length=10, 
        choices=FILE_FORMAT_CHOICES,
        default='glb'  # 기본값을 glb로 설정
    )
    
    poly_count = models.IntegerField(blank=True, null=True)  # 폴리곤 수
    file_size = models.IntegerField(blank=True, null=True)  # 파일 크기 (KB)
    
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='pending')
    
    # 새로운 필드 추가
    description = models.TextField(blank=True, null=True)  # 모델 설명
    meshroom_settings = models.JSONField(blank=True, null=True)  # Meshroom 설정 정보 (선택적)
    
    processing_time = models.IntegerField(blank=True, null=True)  # 처리 소요 시간(초)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"3D Model for {self.artifact.name}"

    class Meta:
        db_table = 'model3d'
        verbose_name = '3D Model'
        verbose_name_plural = '3D Models'


class SourceImage(models.Model):
    """
    3D 모델 생성에 사용된 원본 이미지를 저장하는 모델
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    model = models.ForeignKey(Model3D, on_delete=models.CASCADE, related_name='source_images')
    image_url = models.ImageField(upload_to='models/sources/')
    order = models.IntegerField(default=0)  # 이미지 순서
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Source image {self.order} for {self.model}"

    class Meta:
        db_table = 'model_source_images'
        ordering = ['order']  # 순서대로 정렬


# class ModelTexture(models.Model):
#     """
#     3D 모델에 사용되는 텍스처를 저장하는 모델
#     """
#     id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
#     model = models.ForeignKey(Model3D, on_delete=models.CASCADE, related_name='textures')
#     texture_url = models.TextField()  # 텍스처 파일 경로
    
#     TEXTURE_TYPE_CHOICES = [
#         ('diffuse', 'Diffuse'),
#         ('normal', 'Normal'),
#         ('specular', 'Specular'),
#         ('roughness', 'Roughness'),
#         ('metallic', 'Metallic'),
#         ('ao', 'Ambient Occlusion'),
#         ('emissive', 'Emissive'),
#         ('other', '기타'),
#     ]
#     texture_type = models.CharField(max_length=20, choices=TEXTURE_TYPE_CHOICES, default='diffuse')
    
#     created_at = models.DateTimeField(auto_now_add=True)

#     def __str__(self):
#         return f"{self.texture_type} texture for {self.model}"

#     class Meta:
#         db_table = 'model_textures'