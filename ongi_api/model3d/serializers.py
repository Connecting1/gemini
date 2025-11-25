from rest_framework import serializers
from .models import Model3D, SourceImage
from artifacts.models import Artifact
from artifacts.serializers import ArtifactSerializer

class SourceImageSerializer(serializers.ModelSerializer):
    """3D 모델 원본 이미지 시리얼라이저"""
    class Meta:
        model = SourceImage
        fields = ['id', 'image_url', 'order', 'created_at']
        read_only_fields = ['id', 'created_at']

class Model3DSerializer(serializers.ModelSerializer):
    """3D 모델 시리얼라이저"""
    artifact_name = serializers.SerializerMethodField()
    source_images = SourceImageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Model3D
        fields = [
            'id', 'artifact', 'artifact_name', 'model_url', 'thumbnail_url',
            'file_format', 'poly_count', 'file_size', 'status',
            'processing_time', 'source_images', 'description', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'created_at', 'updated_at']
    
    def get_artifact_name(self, obj):
        """연결된 유물 이름 반환"""
        return obj.artifact.name if obj.artifact else None

class Model3DDetailSerializer(Model3DSerializer):
    """3D 모델 상세 정보 시리얼라이저"""
    artifact_detail = serializers.SerializerMethodField()
    
    class Meta(Model3DSerializer.Meta):
        fields = Model3DSerializer.Meta.fields + ['artifact_detail']
    
    def get_artifact_detail(self, obj):
        """연결된 유물 상세 정보 반환"""
        if not obj.artifact:
            return None
        return ArtifactSerializer(obj.artifact).data

class Model3DCreateSerializer(serializers.Serializer):
    """3D 모델 생성 요청 시리얼라이저"""
    file_format = serializers.ChoiceField(choices=Model3D.FILE_FORMAT_CHOICES, default='glb')
    additional_notes = serializers.CharField(required=False, allow_blank=True)

class ModelStatusUpdateSerializer(serializers.Serializer):
    """3D 모델 상태 업데이트 시리얼라이저"""
    status = serializers.ChoiceField(choices=Model3D.STATUS_CHOICES)
    processing_time = serializers.IntegerField(required=False, allow_null=True)
    poly_count = serializers.IntegerField(required=False, allow_null=True)
    file_size = serializers.IntegerField(required=False, allow_null=True)
    error_message = serializers.CharField(required=False, allow_blank=True)