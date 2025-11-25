from django.urls import path
from .views import (
    feed_list_create_view,
    feed_detail_view,
    feed_update_view,
    feed_delete_view,
    my_feeds_view,
    upload_feed_images
)

urlpatterns = [
    path('', feed_list_create_view, name='feed-list-create'),  # 피드 목록 조회 및 생성
    path('<uuid:feed_id>/', feed_detail_view, name='feed-detail'),  # 피드 상세 조회
    path('<uuid:feed_id>/update/', feed_update_view, name='feed-update'),  # 피드 업데이트
    path('<uuid:feed_id>/delete/', feed_delete_view, name='feed-delete'),  # 피드 삭제
    path('my-feeds/', my_feeds_view, name='my-feeds'),  # 자신의 피드 목록 조회
    path('<uuid:feed_id>/upload-images/', upload_feed_images, name='upload-feed-images'),  # 피드 이미지 업로드
]