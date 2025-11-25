from rest_framework import serializers
from .models import User


class UserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, allow_null=True, required=False)

    class Meta:
        model = User
        fields = '__all__'

    def create(self, validated_data):
        # create_user 메서드로 사용자 생성
        user = User.objects.create_user(**validated_data)
        return user