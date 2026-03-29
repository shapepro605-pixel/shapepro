"""
ShapePro - Serviço de IA para Geração de Dietas Personalizadas
Integra com Google Gemini API para gerar planos nutricionais avançados.
Possui fallback local quando a API não está disponível.
"""

import os
import json


class AIService:
    """AI-powered diet and training plan generation."""

    def __init__(self):
        self.api_key = os.getenv('GEMINI_API_KEY', '')
        self._model = None

    @property
    def is_available(self):
        """Check if AI service is available."""
        return bool(self.api_key)

    def _get_model(self):
        """Lazy-load the Gemini model."""
        if self._model is None and self.is_available:
            try:
                import google.generativeai as genai
                genai.configure(api_key=self.api_key)
                self._model = genai.GenerativeModel('gemini-2.0-flash')
            except Exception as e:
                print(f"[ShapePro AI] Erro ao inicializar modelo: {e}")
                self._model = None
        return self._model

    def gerar_dieta_ia(self, perfil_usuario):
        """
        Generate a personalized diet using Gemini AI.
        Falls back to local algorithm if AI is unavailable.
        """
        model = self._get_model()
        if not model:
            return None  # Caller should use local fallback

        prompt = self._criar_prompt_dieta(perfil_usuario)

        try:
            response = model.generate_content(prompt)
            plano = self._parse_resposta_dieta(response.text)
            return plano
        except Exception as e:
            print(f"[ShapePro AI] Erro na geração de dieta: {e}")
            return None

    def _criar_prompt_dieta(self, perfil):
        """Create a detailed prompt for diet generation."""
        objetivo_map = {
            'perder_peso': 'perder gordura corporal mantendo massa muscular',
            'manter': 'manter o peso atual e melhorar a composição corporal',
            'ganhar_massa': 'ganhar massa muscular de forma limpa (lean bulk)',
        }

        objetivo_desc = objetivo_map.get(perfil.get('objetivo', 'manter'), 'manter o peso')

        ritmo_map = {
            'leve': 'ritmo leve e gradual (foco em saude e reeducacao)',
            'padrao': 'ritmo padrao e saudavel',
            'agressivo': 'RITMO AGRESSIVO / DESAFIO (Se perder peso: dieta extrema Low Carb max 20% e proteina alta. Se ganhar massa: hipercalorico insano com surplus de 1000kcal+).'
        }
        ritmo_desc = ritmo_map.get(perfil.get('ritmo_meta', 'padrao'), 'ritmo padrao')

        prompt = f"""Você é um nutricionista esportivo experiente. Crie um plano alimentar diário completo para o seguinte perfil:

- Sexo: {'Masculino' if perfil.get('sexo', 'M') == 'M' else 'Feminino'}
- Idade: {perfil.get('idade', 25)} anos
- Altura: {perfil.get('altura', 170)} cm
- Peso: {perfil.get('peso', 70)} kg
- Nível de atividade: {perfil.get('nivel_atividade', 'moderado')}
- Objetivo: {objetivo_desc}
- Ritmo/Agressividade: {ritmo_desc}

Regras:
1. Use a fórmula de Harris-Benedict para calcular TMB e TDEE
2. Distribua macronutrientes adequadamente ao objetivo
3. Crie EXATAMENTE 6 refeições: café da manhã, lanche manhã, almoço, lanche tarde, jantar, ceia
4. Use alimentos brasileiros comuns e acessíveis
5. Especifique porções em gramas ou unidades claras
6. Inclua calorias e macros por alimento

Responda APENAS com um JSON válido no formato:
{{
    "calorias_totais": number,
    "proteinas_g": number,
    "carboidratos_g": number,
    "gorduras_g": number,
    "refeicoes": [
        {{
            "nome": "Café da manhã",
            "horario": "07:00",
            "alimentos": [
                {{"nome": "...", "porcao": "150g", "calorias": 200, "proteina": 30, "carboidrato": 5, "gordura": 8}}
            ],
            "total_calorias": number
        }}
    ]
}}"""
        return prompt

    def _parse_resposta_dieta(self, response_text):
        """Parse Gemini's response into a structured diet plan."""
        try:
            # Try to extract JSON from response
            text = response_text.strip()
            # Remove markdown code block if present
            if text.startswith('```'):
                text = text.split('```')[1]
                if text.startswith('json'):
                    text = text[4:]
            if text.endswith('```'):
                text = text[:-3]

            plano = json.loads(text.strip())
            return plano
        except (json.JSONDecodeError, IndexError) as e:
            print(f"[ShapePro AI] Erro ao fazer parse da resposta: {e}")
            return None

    def gerar_dicas_treino(self, exercicio, nivel):
        """Generate AI-powered training tips for an exercise."""
        model = self._get_model()
        if not model:
            return None

        prompt = f"""Dê 3 dicas curtas e profissionais para executar o exercício "{exercicio}" 
        para alguém de nível {nivel}. Responda em formato JSON:
        {{"dicas": ["dica 1", "dica 2", "dica 3"]}}"""

        try:
            response = model.generate_content(prompt)
            text = response.text.strip()
            if text.startswith('```'):
                text = text.split('```')[1]
                if text.startswith('json'):
                    text = text[4:]
            if text.endswith('```'):
                text = text[:-3]
            result = json.loads(text.strip())
            return result.get('dicas', [])
        except Exception:
            return None
