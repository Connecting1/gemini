from django.db import models
import uuid
from feeds.models import Feed
from django.utils import timezone

class Artifact(models.Model):
    """유물 정보 저장 모델"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=200)
    description = models.TextField(blank=True, null=True)  # 기본 설명
    time_period = models.CharField(max_length=100, blank=True, null=True)
    estimated_year = models.CharField(max_length=100, blank=True, null=True)
    origin_location = models.CharField(max_length=200, blank=True, null=True)
    
    STATUS_CHOICES = [
        ('auto_generated', '자동 생성됨'),
        ('verified', '검증됨'),
        ('featured', '주목할 만한'),
        ('rejected', '거부됨'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='auto_generated')
    
    image_count = models.IntegerField(default=0)
    
    # ✨ AI 생성 설명 필드 추가
    ai_description = models.TextField(blank=True, null=True, help_text="AI가 생성한 설명")
    ai_description_generated_at = models.DateTimeField(null=True, blank=True, help_text="AI 설명 생성 시각")
    ai_model_version = models.CharField(max_length=50, blank=True, null=True, default="llama3.1:8b", help_text="사용된 AI 모델")
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name
    
    # ✨ AI 설명 필요 여부 확인
    def needs_ai_description(self):
        """AI 설명이 없거나 오래된 경우 True"""
        if not self.ai_description:
            return True
        
        # 30일 이상 지난 설명은 재생성 고려
        if self.ai_description_generated_at:
            from datetime import timedelta
            age = timezone.now() - self.ai_description_generated_at
            return age > timedelta(days=30)
        
        return False

    class Meta:
        db_table = 'artifacts'


class ArtifactFeed(models.Model):
    """유물과 피드 연결 모델"""
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    artifact = models.ForeignKey(Artifact, on_delete=models.CASCADE, related_name='artifact_feeds')
    feed = models.ForeignKey(Feed, on_delete=models.CASCADE, related_name='feed_artifacts')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.artifact.name} - {self.feed.artifact_name}"

    class Meta:
        db_table = 'artifact_feeds'
        unique_together = ('artifact', 'feed')


def check_and_create_artifact(artifact_name):
    """유물명 기준 이미지 10장 이상 시 자동 생성"""
    from django.db.models import Count, Sum
    
    # 같은 유물명 피드들의 이미지 수 계산
    feeds = Feed.objects.filter(artifact_name=artifact_name, status='published')
    total_images = feeds.annotate(img_count=Count('images')).aggregate(Sum('img_count'))['img_count__sum'] or 0
    
    existing_artifact = Artifact.objects.filter(name=artifact_name).first()
    
    if total_images >= 10 and not existing_artifact:
        # 유물 생성 및 피드 연결
        artifact = Artifact.objects.create(
            name=artifact_name,
            image_count=total_images,
            status='auto_generated'
        )
        
        for feed in feeds:
            ArtifactFeed.objects.create(
                artifact=artifact,
                feed=feed
            )
            
        return artifact
    elif existing_artifact:
        # 기존 유물 이미지 수 업데이트
        existing_artifact.image_count = total_images
        existing_artifact.save()
        
        # 연결되지 않은 피드 연결
        existing_feeds = ArtifactFeed.objects.filter(artifact=existing_artifact).values_list('feed_id', flat=True)
        for feed in feeds:
            if feed.id not in existing_feeds:
                ArtifactFeed.objects.create(
                    artifact=existing_artifact,
                    feed=feed
                )
                
        return existing_artifact
    
    return None