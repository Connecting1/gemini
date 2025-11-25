import os
from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include
from django.views.static import serve
from django.http import HttpResponse

# CORS 헤더를 추가하는 미디어 파일 서빙 함수
def serve_with_cors(request, path, document_root=None, show_indexes=False):
    response = serve(request, path, document_root, show_indexes)
    response['Access-Control-Allow-Origin'] = '*'
    response['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response['Access-Control-Allow-Headers'] = 'Origin, Content-Type, Accept'
    return response

urlpatterns = [
    path('admin/', admin.site.urls),
    
    # API URL 패턴들
    path('api/users/', include('users.urls')),
    path('api/feeds/', include('feeds.urls')),
    path('api/artifacts/', include('artifacts.urls')),
    path('api/models/', include('model3d.urls')),
]

# DEBUG=True일 때 미디어 파일 서빙 (CORS 헤더 추가)
if settings.DEBUG:
    urlpatterns += [
        path('media/<path:path>', serve_with_cors, {'document_root': settings.MEDIA_ROOT}),
        path('models/<path:path>', serve_with_cors, {'document_root': os.path.join(settings.MEDIA_ROOT, 'models')}),

    ]