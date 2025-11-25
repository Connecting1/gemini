from django.db import models
import uuid
from users.models import User  # User 모델 import


class Feed(models.Model):
    """
    사용자가 업로드하는 피드 정보를 저장하는 모델
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='feeds')
    artifact_name = models.CharField(max_length=200)
    
    STATUS_CHOICES = [
        ('draft', '초안'),
        ('published', '게시됨'),
        ('hidden', '숨김'),
        ('deleted', '삭제됨'),
    ]
    status = models.CharField(max_length=20, choices=STATUS_CHOICES, default='published')
    
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return f"{self.artifact_name} by {self.user.username}"

    def save(self, *args, **kwargs):
        # 피드가 저장될 때 user의 feed_count 증가 (새로 생성된 경우에만)
        is_new = self.pk is None
        super().save(*args, **kwargs)
        
        if is_new and self.status == 'published':
            self.user.feed_count += 1
            self.user.update_rank()  # 랭크 업데이트

    class Meta:
        db_table = 'feeds'
        ordering = ['-created_at']  # 최신 피드가 먼저 보이도록


class FeedImage(models.Model):
    """
    피드에 첨부된 이미지 정보를 저장하는 모델
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    feed = models.ForeignKey(Feed, on_delete=models.CASCADE, related_name='images')
    image_url = models.TextField()
    order = models.IntegerField(default=0)  # 이미지 순서
    metadata = models.JSONField(null=True, blank=True)  # EXIF 정보 등 메타데이터
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Image {self.order} for {self.feed.title}"

    class Meta:
        db_table = 'feed_images'
        ordering = ['order']  # 순서대로 정렬