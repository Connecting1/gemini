from django.db import models
from django.contrib.auth.models import AbstractUser
import uuid


class User(AbstractUser):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)  # 이메일
    gender = models.CharField(max_length=20, choices=[  # 성별
        ('male', 'Male'),
        ('female', 'Female'),
        ('other', 'Other'),
        ('non-binary', 'Non-binary'),
        ('prefer not to say', 'Prefer not to say'),
    ])
    username = models.CharField(max_length=30, unique=True)  # 사용자명
    phone_number = models.CharField(max_length=20, unique=True, null=True, blank=True)  # 전화번호
    provider = models.CharField(max_length=50, default='local')  # 로그인 제공자
    profile_image = models.TextField(null=True, blank=True)  # 프로필 이미지 URL
    created_at = models.DateTimeField(auto_now_add=True)  # 계정 생성일

    last_login = models.DateTimeField(null=True, blank=True)  # 마지막 로그인
    is_superuser = models.BooleanField(default=False)  # 슈퍼유저 여부
    is_staff = models.BooleanField(default=False)  # 관리자 여부
    is_active = models.BooleanField(default=True)  # 계정 활성화 여부
    date_joined = models.DateTimeField(auto_now_add=True)  # 가입일
    
    rank = models.IntegerField(default=1)  # 사용자 랭크
    feed_count = models.IntegerField(default=0)  # 피드 개수

    def update_rank(self):
        """피드 수에 따른 랭크 업데이트"""
        if self.feed_count < 10:
            self.rank = 1
        elif self.feed_count < 50:
            self.rank = 2
        elif self.feed_count < 100:
            self.rank = 3
        elif self.feed_count < 200:
            self.rank = 4
        elif self.feed_count < 500:
            self.rank = 5
        else:
            self.rank = 6
        
        self.save()

    class Meta:
        db_table = 'users'


class CustomToken(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="custom_auth_token")  # 토큰 소유자
    key = models.CharField(max_length=40, unique=True)  # 토큰 키
    created = models.DateTimeField(auto_now_add=True)  # 토큰 생성일

    def save(self, *args, **kwargs):
        if not self.key:
            self.key = uuid.uuid4().hex
        return super().save(*args, **kwargs)