# artifacts/serializers.py

from rest_framework import serializers
from .models import Artifact, ArtifactFeed
from feeds.models import Feed
from feeds.serializers import FeedSerializer, UserMinimalSerializer

class ArtifactSerializer(serializers.ModelSerializer):
    """유물 정보 시리얼라이저"""
    feed_count = serializers.SerializerMethodField()
    has_3d_model = serializers.SerializerMethodField()
    thumbnail_url = serializers.SerializerMethodField()
    # ✨ AI 설명 관련 필드 추가
    has_ai_description = serializers.SerializerMethodField()
    needs_ai_generation = serializers.SerializerMethodField()
    
    class Meta:
        model = Artifact
        fields = [
            'id', 'name', 'description', 'time_period', 'estimated_year',
            'origin_location', 'status', 'image_count', 'feed_count',
            'has_3d_model', 'thumbnail_url',
            # ✨ AI 관련
            'ai_description', 'ai_description_generated_at', 'ai_model_version',
            'has_ai_description', 'needs_ai_generation',
            'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'image_count', 'created_at', 'updated_at']
    
    def get_feed_count(self, obj):
        return obj.artifact_feeds.count()
    
    def get_has_3d_model(self, obj):
        return obj.models.filter(status='completed').exists()
    
    def get_thumbnail_url(self, obj):
        model = obj.models.filter(status='completed').first()
        if model and model.thumbnail_url:
            return model.thumbnail_url.url
        
        artifact_feed = obj.artifact_feeds.first()
        if artifact_feed:
            feed = artifact_feed.feed
            feed_image = feed.images.first()
            if feed_image:
                return feed_image.image_url
        
        return None
    
    # ✨ AI 설명 관련 메서드
    def get_has_ai_description(self, obj):
        return bool(obj.ai_description)
    
    def get_needs_ai_generation(self, obj):
        return obj.needs_ai_description()

class ArtifactDetailSerializer(ArtifactSerializer):
    """유물 상세 정보 시리얼라이저"""
    feeds = serializers.SerializerMethodField()
    
    class Meta(ArtifactSerializer.Meta):
        fields = ArtifactSerializer.Meta.fields + ['feeds']
    
    def get_feeds(self, obj):
        """연관된 피드 목록을 반환 (최대 5개)"""
        artifact_feeds = ArtifactFeed.objects.filter(artifact=obj).select_related('feed')[:5]
        feeds = [item.feed for item in artifact_feeds]
        return FeedSerializer(feeds, many=True).data