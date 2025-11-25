from rest_framework.authentication import BaseAuthentication, get_authorization_header
from rest_framework import exceptions
from .models import CustomToken


class CustomTokenAuthentication(BaseAuthentication):
    """커스텀 토큰 인증"""
    keyword = 'Token'
    model = CustomToken

    def authenticate(self, request):
        auth = get_authorization_header(request).split()

        if not auth or auth[0].lower() != self.keyword.lower().encode():
            return None

        if len(auth) == 1:
            msg = '유효하지 않은 토큰 헤더입니다. 자격 증명이 제공되지 않았습니다.'
            raise exceptions.AuthenticationFailed(msg)
        elif len(auth) > 2:
            msg = '유효하지 않은 토큰 헤더입니다. 토큰 문자열에 공백이 포함되어서는 안 됩니다.'
            raise exceptions.AuthenticationFailed(msg)

        try:
            token = auth[1].decode()
        except UnicodeError:
            msg = '유효하지 않은 토큰 헤더입니다. 토큰 문자열에 잘못된 문자가 포함되어 있습니다.'
            raise exceptions.AuthenticationFailed(msg)

        return self.authenticate_credentials(token)

    def authenticate_credentials(self, key):
        try:
            token = self.model.objects.select_related('user').get(key=key)
        except self.model.DoesNotExist:
            raise exceptions.AuthenticationFailed('유효하지 않은 토큰입니다.')

        if not token.user.is_active:
            raise exceptions.AuthenticationFailed('사용자가 비활성화되었거나 삭제되었습니다.')

        return (token.user, token)

    def authenticate_header(self, request):
        return self.keyword