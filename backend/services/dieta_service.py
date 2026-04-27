"""
ShapePro - Serviço de Geração de Dieta Personalizada
Calcula calorias e macronutrientes baseado na fórmula de Harris-Benedict
e gera planos de refeição completos.
"""

import json
import os
import random
from database import db
from models.food_price import FoodPrice


class DietaService:

    def __init__(self, lang='pt', user=None):
        self.lang = lang if lang in ['pt', 'en'] else 'pt'
        self.user = user
        suffix = '_en' if self.lang == 'en' else ''
        self.foods_path = os.path.join(
            os.path.dirname(os.path.dirname(__file__)),
            'data', f'foods{suffix}.json'
        )
        self._alimentos = None
        self._custo_diario_acumulado = 0
        self._orcamento_diario_limite = 999999
        
        if self.user and self.user.orcamento_dieta:
            self._orcamento_diario_limite = self.user.orcamento_dieta / 30
        elif self.user and self.user.renda_mensal:
            # Estimativa: 15% da renda para dieta se não definido
            self._orcamento_diario_limite = (self.user.renda_mensal * 0.15) / 30

    @property
    def alimentos(self):
        if self._alimentos is None:
            if not os.path.exists(self.foods_path):
                fallback_path = os.path.join(
                    os.path.dirname(os.path.dirname(__file__)),
                    'data', 'foods.json'
                )
                with open(fallback_path, 'r', encoding='utf-8') as f:
                    self._alimentos = json.load(f)
            else:
                with open(self.foods_path, 'r', encoding='utf-8') as f:
                    self._alimentos = json.load(f)
        return self._alimentos

    def calcular_tmb(self, sexo, idade, altura, peso):
        """
        Calcula a Taxa Metabólica Basal usando a fórmula de Harris-Benedict revisada.
        sexo: 'M' ou 'F'
        idade: em anos
        altura: em cm
        peso: em kg
        """
        if sexo.upper() == 'M':
            tmb = 88.362 + (13.397 * peso) + (4.799 * altura) - (5.677 * idade)
        else:
            tmb = 447.593 + (9.247 * peso) + (3.098 * altura) - (4.330 * idade)
        return round(tmb, 0)

    def calcular_tdee(self, tmb, nivel_atividade):
        """Calcula o TDEE (Total Daily Energy Expenditure)."""
        fatores = {
            'sedentario': 1.2,
            'leve': 1.375,
            'moderado': 1.55,
            'intenso': 1.725,
            'muito_intenso': 1.9,
        }
        fator = fatores.get(nivel_atividade, 1.55)
        return round(tmb * fator, 0)

    def calcular_macros(self, calorias, objetivo, ritmo_meta='padrao'):
        """
        Distribui macronutrientes baseado no objetivo e ritmo (agressividade).
        Retorna proteinas, carboidratos e gorduras em gramas.
        """
        ajustes_ritmo = {
            'perder_peso': {
                'leve': -300,
                'padrao': -500,
                'agressivo': -1000
            },
            'ganhar_massa': {
                'leve': 300,
                'padrao': 500,
                'agressivo': 1000
            },
            'manter': {
                'leve': 0, 'padrao': 0, 'agressivo': 0
            }
        }

        if objetivo == 'perder_peso':
            if ritmo_meta == 'agressivo':
                macros = {'proteina_pct': 0.45, 'carbo_pct': 0.20, 'gordura_pct': 0.35} # Low carb extremo
            elif ritmo_meta == 'leve':
                macros = {'proteina_pct': 0.30, 'carbo_pct': 0.45, 'gordura_pct': 0.25}
            else:
                macros = {'proteina_pct': 0.35, 'carbo_pct': 0.35, 'gordura_pct': 0.30}
        elif objetivo == 'ganhar_massa':
            if ritmo_meta == 'agressivo':
                macros = {'proteina_pct': 0.25, 'carbo_pct': 0.55, 'gordura_pct': 0.20} # High carb e calorias absurdas
            else:
                macros = {'proteina_pct': 0.30, 'carbo_pct': 0.50, 'gordura_pct': 0.20}
        else:
            macros = {'proteina_pct': 0.30, 'carbo_pct': 0.45, 'gordura_pct': 0.25}

        ajuste = ajustes_ritmo.get(objetivo, ajustes_ritmo['manter']).get(ritmo_meta, 0)
        calorias_finais = calorias + ajuste

        # Trava de segurança
        if calorias_finais < 1200:
            calorias_finais = 1200

        proteinas_g = round((calorias_finais * macros['proteina_pct']) / 4, 0)  # 4 cal/g
        carboidratos_g = round((calorias_finais * macros['carbo_pct']) / 4, 0)  # 4 cal/g
        gorduras_g = round((calorias_finais * macros['gordura_pct']) / 9, 0)    # 9 cal/g

        return {
            'calorias_totais': calorias_finais,
            'proteinas_g': proteinas_g,
            'carboidratos_g': carboidratos_g,
            'gorduras_g': gorduras_g,
        }

    def _selecionar_alimento(self, categoria, usados=None, orcamento='padrao'):
        """Select a random food item from category, avoiding repeats and respecting budget."""
        opcoes = self.alimentos.get(categoria, [])
        if usados:
            opcoes = [a for a in opcoes if a['nome'] not in usados]

        # Lógica de Orçamento em Tempo Real:
        # Se já gastamos mais de 80% do limite diário, força alimentos de baixo custo
        orcamento_forcado = orcamento
        if self._custo_diario_acumulado > (self._orcamento_diario_limite * 0.8):
            orcamento_forcado = 'economico'

        if orcamento_forcado == 'economico':
            # Prefer low cost, then medium. Avoid high cost.
            filtradas = [a for a in opcoes if a.get('custo') == 'baixo']
            if not filtradas:
                filtradas = [a for a in opcoes if a.get('custo') == 'medio']
            if filtradas:
                opcoes = filtradas
        elif orcamento_forcado == 'premium':
            # Prioritize high cost items for a premium experience
            alto = [a for a in opcoes if a.get('custo') == 'alto']
            medio = [a for a in opcoes if a.get('custo') == 'medio']
            if alto:
                # 70% chance of high cost if available
                if random.random() < 0.7:
                    opcoes = alto
                else:
                    opcoes = medio or alto
            elif medio:
                opcoes = medio

        if not opcoes:
            opcoes = self.alimentos.get(categoria, [])

        return random.choice(opcoes) if opcoes else None

    def _get_food_price(self, alimento_nome):
        """
        Calcula o preço real ou estimado para o alimento.
        Prioridade: 1. BD (Cidade/País), 2. BD (País), 3. Estimativa Base
        """
        cidade = self.user.cidade if self.user else None
        pais = self.user.pais if self.user else 'BR'
        moeda = self.user.moeda if self.user else 'BRL'

        # Busca no banco de dados (com proteção contra tabela inexistente)
        try:
            # Tenta cidade específica
            if cidade:
                price_rec = FoodPrice.query.filter(
                    FoodPrice.alimento.ilike(alimento_nome),
                    FoodPrice.cidade == cidade,
                    FoodPrice.pais == pais
                ).first()
                if price_rec:
                    return price_rec.preco

            # Tenta país
            price_rec = FoodPrice.query.filter(
                FoodPrice.alimento.ilike(alimento_nome),
                FoodPrice.pais == pais
            ).first()
            if price_rec:
                return price_rec.preco
        except Exception as e:
            print(f"[DietaService] DB price lookup failed (table may not exist): {e}")

        # Fallback: Estimativa Baseada no Custo e Moeda
        # Heurística de preços médios por categoria de custo
        base_prices = {'baixo': 2.50, 'medio': 7.00, 'alto': 18.00}
        
        # Encontra o custo do alimento no json
        custo_categoria = 'medio'
        for cat, list_f in self.alimentos.items():
            for f in list_f:
                if f['nome'] == alimento_nome:
                    custo_categoria = f.get('custo', 'medio')
                    break
        
        price_val = base_prices.get(custo_categoria, 7.0)
        
        # Multiplicadores de câmbio aproximados se não for USD
        multipliers = {'BRL': 5.2, 'EUR': 0.92, 'GBP': 0.79, 'CAD': 1.37, 'USD': 1.0}
        final_price = price_val * multipliers.get(moeda, 1.0)
        
        return round(final_price, 2)

    def _format_currency(self, value):
        moeda = self.user.moeda if self.user else 'BRL'
        symbols = {'BRL': 'R$', 'USD': '$', 'EUR': '€', 'GBP': '£', 'CAD': 'C$'}
        symbol = symbols.get(moeda, '$')
        
        if moeda == 'BRL':
            return f"{symbol} {value:.2f}".replace('.', ',')
        return f"{symbol}{value:.2f}"

    def _calcular_macros_alimento(self, alimento):
        """Calculate actual macros and PRICE for the food portion."""
        fator = alimento['porcao'] / 100
        
        # Calcula preço
        preco_base = self._get_food_price(alimento['nome'])
        
        # Se for unidade, o preço no fallback costuma ser por "unidade/pacote"
        # Para unidades individuais (ovo, banana), o preço base deve ser menor
        if 'unidade' in alimento:
             # Heurística: se for unidade, o preço base do fallback (7.0, 18.0) é dividido 
             # para representar o valor de uma única unidade.
             preco_porcao = preco_base / 5.0 
        else:
             preco_porcao = preco_base * (alimento['porcao'] / 1000) # Preço por kg
        
        self._custo_diario_acumulado += preco_porcao
        
        price_str = self._format_currency(preco_porcao)
        
        return {
            'nome': alimento['nome'],
            'porcao': f"{alimento['porcao']}g • {price_str}" if 'unidade' not in alimento else f"{alimento['unidade']} • {price_str}",
            'calorias': round(alimento['calorias'] * fator),
            'proteina': round(alimento['proteina'] * fator, 1),
            'carboidrato': round(alimento['carbo'] * fator, 1),
            'gordura': round(alimento['gordura'] * fator, 1),
            'preco_num': round(preco_porcao, 2)
        }

    def gerar_refeicoes(self, macros, orcamento='padrao'):
        """Generate 6 meals for the day."""
        from services.i18n import t
        usados = set()
        self._custo_diario_acumulado = 0 # Reset para o dia

        refeicoes = [
            self._gerar_cafe_da_manha(macros, usados, orcamento),
            self._gerar_lanche(macros, usados, t('meal_morning_snack'), orcamento),
            self._gerar_almoco(macros, usados, orcamento),
            self._gerar_lanche(macros, usados, t('meal_afternoon_snack'), orcamento),
            self._gerar_jantar(macros, usados, orcamento),
            self._gerar_ceia(macros, usados, orcamento),
        ]

        return refeicoes

    def _gerar_cafe_da_manha(self, macros, usados, orcamento='padrao'):
        """Generate breakfast - ~25% of daily calories."""
        from services.i18n import t
        alimentos = []
        proteina = self._selecionar_alimento('proteinas', usados, orcamento)
        carbo = self._selecionar_alimento('carboidratos', usados, orcamento)
        fruta = self._selecionar_alimento('frutas', usados, orcamento)

        for a in [proteina, carbo, fruta]:
            if a:
                usados.add(a['nome'])
                alimentos.append(self._calcular_macros_alimento(a))

        total_cal = sum(a['calorias'] for a in alimentos)
        return {
            'nome': t('meal_breakfast'),
            'horario': '07:00',
            'alimentos': alimentos,
            'total_calorias': total_cal,
        }

    def _gerar_lanche(self, macros, usados, nome, orcamento='padrao'):
        """Generate snack - ~10% of daily calories."""
        alimentos = []
        fruta = self._selecionar_alimento('frutas', usados, orcamento)
        gordura = self._selecionar_alimento('gorduras', usados, orcamento)

        for a in [fruta, gordura]:
            if a:
                usados.add(a['nome'])
                alimentos.append(self._calcular_macros_alimento(a))

        # Determination of time based on Portuguese or English names
        nome_lower = nome.lower()
        if 'manhã' in nome_lower or 'morning' in nome_lower:
            horario = '10:00'
        else:
            horario = '15:30'

        total_cal = sum(a['calorias'] for a in alimentos)
        return {
            'nome': nome,
            'horario': horario,
            'alimentos': alimentos,
            'total_calorias': total_cal,
        }

    def _gerar_almoco(self, macros, usados, orcamento='padrao'):
        """Generate lunch - ~30% of daily calories."""
        from services.i18n import t
        alimentos = []
        proteina = self._selecionar_alimento('proteinas', usados, orcamento)
        carbo = self._selecionar_alimento('carboidratos', usados, orcamento)
        gordura = self._selecionar_alimento('gorduras', usados, orcamento)
        verdura = self._selecionar_alimento('verduras_legumes', usados, orcamento)

        for a in [proteina, carbo, gordura, verdura]:
            if a:
                usados.add(a['nome'])
                alimentos.append(self._calcular_macros_alimento(a))

        total_cal = sum(a['calorias'] for a in alimentos)
        return {
            'nome': t('meal_lunch'),
            'horario': '12:30',
            'alimentos': alimentos,
            'total_calorias': total_cal,
        }

    def _gerar_jantar(self, macros, usados, orcamento='padrao'):
        """Generate dinner - ~25% of daily calories."""
        from services.i18n import t
        alimentos = []
        proteina = self._selecionar_alimento('proteinas', usados, orcamento)
        carbo = self._selecionar_alimento('carboidratos', usados, orcamento)
        verdura = self._selecionar_alimento('verduras_legumes', usados, orcamento)

        for a in [proteina, carbo, verdura]:
            if a:
                usados.add(a['nome'])
                alimentos.append(self._calcular_macros_alimento(a))

        total_cal = sum(a['calorias'] for a in alimentos)
        return {
            'nome': t('meal_dinner'),
            'horario': '19:00',
            'alimentos': alimentos,
            'total_calorias': total_cal,
        }

    def _gerar_ceia(self, macros, usados, orcamento='padrao'):
        """Generate late snack - ~10% of daily calories."""
        from services.i18n import t
        alimentos = []
        proteina = self._selecionar_alimento('proteinas', usados, orcamento)

        if proteina:
            usados.add(proteina['nome'])
            alimentos.append(self._calcular_macros_alimento(proteina))

        total_cal = sum(a['calorias'] for a in alimentos)
        return {
            'nome': t('meal_late_snack'),
            'horario': '21:30',
            'alimentos': alimentos,
            'total_calorias': total_cal,
        }

    def translate_meals(self, meals_data, target_lang='pt'):
        """
        Translates a list of meals (or a weekly plan) on-the-fly.
        Used for translating persisted data in the DB when the UI language changes.
        """
        if target_lang == self.lang:
            return meals_data

        try:
            # Load the target language foods for mapping
            target_service = DietaService(lang=target_lang)
            target_foods = target_service.alimentos
            
            # Create a name-based mapping from source language to target language
            # This works because PT and EN reference files are categorized identically
            mapping = {}
            for category, target_list in target_foods.items():
                orig_list = self.alimentos.get(category, [])
                for i in range(min(len(orig_list), len(target_list))):
                    orig_name = orig_list[i]['nome']
                    mapping[orig_name] = target_list[i]

            def translate_refeicao(refeicao):
                new_ref = refeicao.copy()
                try:
                    from services.i18n import t
                except (ImportError, ModuleNotFoundError):
                    t = lambda x: x # Fallback for standalone tests
                
                # Translate meal names (Breakfast, Lunch, etc.)
                meal_key_map = {
                    'Café da Manhã': 'meal_breakfast', 'Breakfast': 'meal_breakfast',
                    'Lanche da Manhã': 'meal_morning_snack', 'Morning Snack': 'meal_morning_snack',
                    'Almoço': 'meal_lunch', 'Lunch': 'meal_lunch',
                    'Lanche da Tarde': 'meal_afternoon_snack', 'Afternoon Snack': 'meal_afternoon_snack',
                    'Jantar': 'meal_dinner', 'Dinner': 'meal_dinner',
                    'Ceia': 'meal_late_snack', 'Late Snack': 'meal_late_snack'
                }
                orig_meal_name = refeicao.get('nome')
                if orig_meal_name in meal_key_map:
                    # Note: We use t() but we need the context of target_lang
                    # For simplicity, we hardcode the common ones if t() doesn't support forcing lang easily
                    # but TreinoService/DietaService are initialized with the target lang usually.
                    # Since this is a shim, we rely on the mapping or a simple dict.
                    pass 

                new_alimentos = []
                for al in refeicao.get('alimentos', []):
                    new_al = al.copy()
                    orig_food_name = al.get('nome')
                    if orig_food_name in mapping:
                        target_food = mapping[orig_food_name]
                        new_al['nome'] = target_food['nome']
                        if 'unidade' in target_food:
                            new_al['unidade'] = target_food['unidade']
                    new_alimentos.append(new_al)
                new_ref['alimentos'] = new_alimentos
                return new_ref

            translated_meals = []
            for meal in meals_data:
                if 'refeicoes' in meal:
                    # 7-day plan structure: each item has a 'refeicoes' list
                    new_day = meal.copy()
                    new_day['refeicoes'] = [translate_refeicao(r) for r in meal['refeicoes']]
                    translated_meals.append(new_day)
                else:
                    # 1-day plan structure: each item is a meal
                    translated_meals.append(translate_refeicao(meal))
            return translated_meals
        except Exception as e:
            print(f"[DietaService] Translation error: {e}")
            return meals_data

    def gerar_plano(self, sexo, idade, altura, peso, nivel_atividade='moderado', objetivo='manter', ritmo_meta='padrao', dias=1, orcamento='padrao'):
        """
        Generate a complete diet plan (1 or 7 days).
        Returns dict with calories, macros, and meals.
        """
        tmb = self.calcular_tmb(sexo, idade, altura, peso)
        tdee = self.calcular_tdee(tmb, nivel_atividade)
        macros = self.calcular_macros(tdee, objetivo, ritmo_meta)

        if dias == 7:
            # Generate 7 different daily plans
            plano_semanal = []
            for i in range(7):
                plano_semanal.append({
                    'dia': i + 1,
                    'refeicoes': self.gerar_refeicoes(macros, orcamento)
                })
            refeicoes_data = plano_semanal
        else:
            # Standard 1 day plan
            refeicoes_data = self.gerar_refeicoes(macros, orcamento)

        return {
            'tmb': tmb,
            'tdee': tdee,
            'calorias_totais': macros['calorias_totais'],
            'proteinas_g': macros['proteinas_g'],
            'carboidratos_g': macros['carboidratos_g'],
            'gorduras_g': macros['gorduras_g'],
            'refeicoes': refeicoes_data,
            'objetivo': objetivo,
            'duracao': dias
        }
