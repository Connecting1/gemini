from django.urls import path
from .views import (
    model3d_list_view,
    model3d_detail_view,
    artifact_models_view,
    create_model_request_view,
    update_model_status_view,
)

urlpatterns = [
    path('', model3d_list_view, name='model3d-list'),  # 3D 모델 목록 조회
    path('<uuid:model_id>/', model3d_detail_view, name='model3d-detail'),  # 3D 모델 상세 조회
    path('artifacts/<uuid:artifact_id>/', artifact_models_view, name='artifact-models'),  # 특정 유물의 3D 모델 조회
    path('artifacts/<uuid:artifact_id>/create/', create_model_request_view, name='create-model-request'),  # 3D 모델 생성 요청
    path('<uuid:model_id>/update-status/', update_model_status_view, name='update-model-status'),  # 3D 모델 상태 업데이트
]