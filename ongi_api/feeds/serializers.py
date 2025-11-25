from rest_framework import serializers
from .models import Feed, FeedImage
from users.models import User

class FeedImageSerializer(serializers.ModelSerializer):
    """피드 이미지 시리얼라이저"""
    class Meta:
        model = FeedImage
        fields = ['id', 'image_url', 'order', 'metadata', 'created_at']
        read_only_fields = ['id', 'created_at']

class UserMinimalSerializer(serializers.ModelSerializer):
    """유저 정보의 최소 버전 시리얼라이저 (피드 작성자 정보용)"""
    class Meta:
        model = User
        fields = ['id', 'username', 'profile_image', 'rank']

class FeedSerializer(serializers.ModelSerializer):
    images = FeedImageSerializer(many=True, read_only=True)
    user = UserMinimalSerializer(read_only=True)
    
    class Meta:
        model = Feed
        fields = [
            'id', 'user', 'artifact_name', 
            'status', 'images', 'created_at', 'updated_at'
        ]
        read_only_fields = ['id', 'user', 'created_at', 'updated_at']

class FeedCreateSerializer(serializers.ModelSerializer):
    """피드 생성 시리얼라이저"""
    images = serializers.ListField(
        child=serializers.ImageField(),
        required=False,
        write_only=True
    )
    
    class Meta:
        model = Feed
        fields = ['title', 'content', 'artifact_name', 'status', 'images']
    
    def create(self, validated_data):
        images = validated_data.pop('images', [])
        feed = Feed.objects.create(**validated_data)
        
        # 이미지 파일 처리
        for index, image_file in enumerate(images):
            # 파일 저장 로직은 실제 구현 시 프로젝트에 맞게 수정 필요
            image_url = self._save_image(image_file, feed.id, index)
            
            FeedImage.objects.create(
                feed=feed,
                image_url=image_url,
                order=index
            )
        
        return feed
    
    def _save_image(self, image_file, feed_id, order):
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
        
        # URL 생성
        relative_path = os.path.join('feeds', str(feed_id), filename)
        url = f"{settings.MEDIA_URL}{relative_path}"
        
        return url