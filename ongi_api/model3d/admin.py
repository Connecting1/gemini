from django.contrib import admin
from django.utils.html import format_html
from django.urls import reverse
from .models import Model3D, SourceImage

class SourceImageInline(admin.TabularInline):
    model = SourceImage
    extra = 1  # 기본적으로 보여줄 빈 폼 개수
    fields = ('image_url', 'order')

@admin.register(Model3D)
class Model3DAdmin(admin.ModelAdmin):
    list_display = ('id', 'artifact_link', 'file_format', 'status', 'created_at')
    list_filter = ('status', 'file_format')
    search_fields = ('artifact__name', 'description')
    readonly_fields = ('id', 'created_at', 'updated_at')
    inlines = [SourceImageInline]
    
    fieldsets = (
        ('기본 정보', {
            'fields': ('id', 'artifact', 'description')
        }),
        ('모델 파일', {
            'fields': ('model_url', 'thumbnail_url', 'file_format')
        }),
        ('상태 정보', {
            'fields': ('status', 'poly_count', 'file_size', 'processing_time')
        }),
        ('Meshroom 정보', {
            'fields': ('meshroom_settings',),
            'classes': ('collapse',),  # 접을 수 있는 섹션
        }),
        ('시간 정보', {
            'fields': ('created_at', 'updated_at'),
            'classes': ('collapse',),
        }),
    )
    
    def artifact_link(self, obj):
        """유물 이름에 링크 추가"""
        if obj.artifact:
            url = reverse('admin:artifacts_artifact_change', args=[obj.artifact.id])
            return format_html('<a href="{}">{}</a>', url, obj.artifact.name)
        return "-"
    artifact_link.short_description = '유물'

@admin.register(SourceImage)
class SourceImageAdmin(admin.ModelAdmin):
    list_display = ('id', 'model_link', 'order', 'created_at')
    list_filter = ('created_at',)
    search_fields = ('model__artifact__name',)
    
    def model_link(self, obj):
        """모델 ID에 링크 추가"""
        if obj.model:
            url = reverse('admin:model3d_model3d_change', args=[obj.model.id])
            return format_html('<a href="{}">{}</a>', url, obj.model.id)
        return "-"
    model_link.short_description = '모델'