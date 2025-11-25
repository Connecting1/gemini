from django.urls import path
from .views import (
    user_create_view,
    user_login_view,
    get_user_info,
    update_user_info,
    update_profile_image
)

urlpatterns = [
    path('create/', user_create_view, name='user-create'),  # 회원가입 API
    path('login/', user_login_view, name='user-login'),  # 로그인 API
    path('<uuid:user_id>/', get_user_info, name='get_user_info'),  # 유저 정보 조회 (GET)
    path('<uuid:user_id>/update/', update_user_info, name='update_user_info'),  # 유저 정보 업데이트 (PATCH)
    path('<str:user_id>/update-profile-image/', update_profile_image, name='update_profile_image'),
]