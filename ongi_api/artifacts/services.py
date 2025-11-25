# artifacts/services.py

import httpx
import json
from typing import Generator, Dict, Any
from django.conf import settings

class OllamaService:
    """Ollama AI 서비스"""
    
    OLLAMA_BASE_URL = getattr(settings, 'OLLAMA_BASE_URL', 'http://localhost:11434')
    DEFAULT_MODEL = getattr(settings, 'OLLAMA_MODEL', 'llama3.1:8b')
    
    @classmethod
    def generate_artifact_description(
        cls, 
        artifact_name: str,
        time_period: str = None,
        estimated_year: str = None,
        origin_location: str = None,
        stream: bool = True
    ) -> Generator[Dict[str, Any], None, None]:
        """
        유물 설명 생성 (스트리밍)
        
        Args:
            artifact_name: 유물명
            time_period: 시대
            estimated_year: 추정 연도
            origin_location: 출토지
            stream: 스트리밍 여부
        
        Yields:
            {'chunk': '텍스트'} 또는 {'done': True} 또는 {'error': '에러메시지'}
        """
        
        # ✨ 프롬프트 생성
        prompt = cls._create_prompt(
            artifact_name=artifact_name,
            time_period=time_period,
            estimated_year=estimated_year,
            origin_location=origin_location,
        )
        
        try:
            with httpx.stream(
                'POST',
                f'{cls.OLLAMA_BASE_URL}/api/generate',
                json={
                    'model': cls.DEFAULT_MODEL,
                    'prompt': prompt,
                    'stream': stream,
                    'options': {
                        'temperature': 0.7,  # 창의성 조절
                        'top_p': 0.9,
                        'max_tokens': 500,   # 최대 토큰 수
                    }
                },
                timeout=60.0
            ) as response:
                
                if response.status_code != 200:
                    yield {'error': f'Ollama API error: {response.status_code}'}
                    return
                
                for line in response.iter_lines():
                    if line.strip():
                        try:
                            data = json.loads(line)
                            
                            if 'response' in data:
                                yield {'chunk': data['response']}
                            
                            if data.get('done', False):
                                yield {'done': True}
                                break
                                
                        except json.JSONDecodeError as e:
                            yield {'error': f'JSON decode error: {str(e)}'}
                            continue
                            
        except httpx.TimeoutException:
            yield {'error': 'Ollama API timeout'}
        except httpx.ConnectError:
            yield {'error': 'Cannot connect to Ollama. Is it running?'}
        except Exception as e:
            yield {'error': f'Unexpected error: {str(e)}'}
    
    @classmethod
    def _create_prompt(
        cls,
        artifact_name: str,
        time_period: str = None,
        estimated_year: str = None,
        origin_location: str = None,
    ) -> str:
        """유물 설명 생성 프롬프트"""
        
        prompt = f"""당신은 한국 문화재 전문가입니다. 다음 유물에 대해 자세하고 흥미롭게 설명해주세요.

📌 유물 정보:
- 유물명: {artifact_name}"""
        
        if time_period:
            prompt += f"\n• 시대: {time_period}"
        if estimated_year:
            prompt += f"\n• 추정 연도: {estimated_year}"
        if origin_location:
            prompt += f"\n• 출토지: {origin_location}"
        
        prompt += """

📝 설명 작성 가이드:
1. 역사적 배경과 시대적 맥락 (2-3문장)
2. 유물의 특징과 제작 기법 (2-3문장)
3. 문화적/예술적 가치와 의의 (1-2문장)

⚠️ 주의사항:
- 자연스럽고 이해하기 쉬운 한국어로 작성
- 전문 용어는 쉽게 풀어서 설명
- 흥미로운 이야기나 에피소드 포함
- 총 200-300자 내외로 작성
- 존댓말 사용하지 않고 평서문으로 작성

설명:"""
        
        return prompt
    
    @classmethod
    def generate_simple(cls, artifact_name: str) -> str:
        """
        간단한 동기식 생성 (스트리밍 없음)
        """
        full_text = ""
        
        for chunk in cls.generate_artifact_description(
            artifact_name=artifact_name,
            stream=True
        ):
            if 'chunk' in chunk:
                full_text += chunk['chunk']
            elif 'error' in chunk:
                raise Exception(chunk['error'])
            elif chunk.get('done'):
                break
        
        return full_text