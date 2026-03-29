"""
ShapePro - Serviço de Geração de Treinos de Academia
Gera programas de treino completos por grupo muscular e nível.
"""

import json
import os


class TreinoService:

    def __init__(self, lang='pt'):
        self.lang = lang if lang in ['pt', 'en'] else 'pt'
        suffix = '_en' if self.lang == 'en' else ''
        self.exercises_path = os.path.join(
            os.path.dirname(os.path.dirname(__file__)),
            'data', f'exercises{suffix}.json'
        )
        self._exercises = None

    @property
    def exercises(self):
        if self._exercises is None:
            if not os.path.exists(self.exercises_path):
                # Fallback to PT if EN file is missing
                fallback_path = os.path.join(
                    os.path.dirname(os.path.dirname(__file__)),
                    'data', 'exercises.json'
                )
                with open(fallback_path, 'r', encoding='utf-8') as f:
                    self._exercises = json.load(f)
            else:
                with open(self.exercises_path, 'r', encoding='utf-8') as f:
                    self._exercises = json.load(f)
        return self._exercises

    def get_todos_exercicios(self):
        """Return all exercises."""
        todos = []
        for grupo, exercicios in self.exercises.items():
            for ex in exercicios:
                ex_copy = ex.copy()
                ex_copy['grupo_muscular'] = grupo
                todos.append(ex_copy)
        return todos

    def get_exercicios_por_grupo(self, grupo):
        """Return exercises for a specific muscle group."""
        grupo_lower = grupo.lower().strip()
        # Map common names (normalized to keys in exercises.json)
        mapeamento = {
            'peito': 'peito', 'chest': 'peito',
            'costas': 'costas', 'back': 'costas',
            'ombros': 'ombros', 'shoulders': 'ombros',
            'biceps': 'biceps', 'bíceps': 'biceps',
            'triceps': 'triceps', 'tríceps': 'triceps',
            'pernas': 'pernas', 'legs': 'pernas',
            'abdomen': 'abdomen', 'abdômen': 'abdomen', 'abs': 'abdomen',
            'gluteos': 'gluteos', 'glúteos': 'gluteos', 'glutes': 'gluteos'
        }
        grupo_key = mapeamento.get(grupo_lower, grupo_lower)
        return self.exercises.get(grupo_key, [])

    def get_programa_completo(self, nivel='intermediario', objetivo='manter'):
        """
        Generate a complete 5-day training program (A/B/C/D/E split).
        """
        from services.i18n import t
        programa = [
            self._gerar_treino('A', t('train_a'), ['peito', 'triceps'], nivel, objetivo),
            self._gerar_treino('B', t('train_b'), ['costas', 'biceps'], nivel, objetivo),
            self._gerar_treino('C', t('train_c'), ['pernas', 'gluteos'], nivel, objetivo),
            self._gerar_treino('D', t('train_d'), ['ombros', 'abdomen'], nivel, objetivo),
            self._gerar_treino('E', t('train_e'), ['peito', 'costas', 'pernas', 'ombros'], nivel, objetivo),
        ]
        return programa

    def get_treino_por_tipo(self, tipo, nivel='intermediario', objetivo='manter'):
        """Get a specific training day by type (A, B, C, D, E)."""
        programa = self.get_programa_completo(nivel, objetivo)
        for treino in programa:
            if treino['tipo'] == tipo.upper():
                return treino
        return None

    def _gerar_treino(self, tipo, nome, grupos, nivel, objetivo='manter'):
        """Generate a training day with exercises from specified muscle groups."""
        exercicios_treino = []

        # Base config by level
        config_nivel = {
            'iniciante': {'series': 3, 'reps': '12-15', 'descanso': '60s'},
            'intermediario': {'series': 4, 'reps': '8-12', 'descanso': '90s'},
            'avancado': {'series': 5, 'reps': '6-10', 'descanso': '120s'},
        }

        # Adjust based on goal/objective
        if objetivo == 'perder_peso':
            # Focus on volume/metabolic stress
            config = {
                'series': 3 if nivel == 'iniciante' else 4,
                'reps': '15-20',
                'descanso': '45-60s'
            }
        elif objetivo == 'ganhar_massa':
            # Focus on strength/hypertrophy
            config = {
                'series': 4 if nivel == 'iniciante' else 5,
                'reps': '6-8' if nivel == 'avancado' else '8-10',
                'descanso': '90-120s'
            }
        else:
            config = config_nivel.get(nivel, config_nivel['intermediario'])

        exercicios_por_grupo = 3 if nivel == 'iniciante' else (5 if nivel == 'avancado' else 4)

        for grupo in grupos:
            grupo_exercises = self.exercises.get(grupo, [])
            # Select exercises based on level
            n = min(exercicios_por_grupo, len(grupo_exercises))
            selected = grupo_exercises[:n]

            for ex in selected:
                exercicios_treino.append({
                    'nome': ex['nome'],
                    'grupo_muscular': grupo,
                    'series': ex.get('series', config['series']),
                    'repeticoes': ex.get('repeticoes', config['reps']),
                    'descanso': ex.get('descanso', config['descanso']),
                    'dicas': ex.get('dicas', ''),
                    'equipamento': ex.get('equipamento', 'Not specified' if self.lang == 'en' else 'Não especificado'),
                    'dificuldade': ex.get('dificuldade', nivel),
                    'imagem': ex.get('imagem', ''),
                    'musculos_trabalhados': ex.get('musculos_trabalhados', []),
                })

        return {
            'tipo': tipo,
            'nome': nome,
            'nivel': nivel,
            'total_exercicios': len(exercicios_treino),
            'tempo_estimado': f'{len(exercicios_treino) * 5 + 10} min',
            'exercicios': exercicios_treino,
        }

    def get_grupos_musculares(self):
        """Return list of available muscle groups."""
        from services.i18n import t
        grupos = [
            {'id': 'peito', 'nome': t('muscle_peito'), 'icone': '💪'},
            {'id': 'costas', 'nome': t('muscle_costas'), 'icone': '🔙'},
            {'id': 'ombros', 'nome': t('muscle_ombros'), 'icone': '🏋️'},
            {'id': 'biceps', 'nome': t('muscle_biceps'), 'icone': '💪'},
            {'id': 'triceps', 'nome': t('muscle_triceps'), 'icone': '💪'},
            {'id': 'pernas', 'nome': t('muscle_pernas'), 'icone': '🦵'},
            {'id': 'abdomen', 'nome': t('muscle_abdomen'), 'icone': '🏆'},
            {'id': 'gluteos', 'nome': t('muscle_gluteos'), 'icone': '🍑'},
        ]
        return grupos
