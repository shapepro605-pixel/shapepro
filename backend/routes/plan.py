from flask import Blueprint, request, jsonify
from flask_jwt_extended import jwt_required, get_jwt_identity
from database import db
from models.user import User, DietPlan, TrainingPlan
from services.dieta_service import DietaService
from services.treino_service import TreinoService
from services.i18n import t

plan_bp = Blueprint('plan', __name__, url_prefix='/api/plan')


@plan_bp.route('/dieta', methods=['POST'])
@jwt_required()
def gerar_dieta():
    """Generate a personalized diet plan for the user."""
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))

    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    # Check if user has necessary data
    if not all([user.idade, user.altura, user.peso, user.sexo]):
        return jsonify({
            'error': t('complete_profile_diet')
        }), 400

    # Deactivate previous diet plans
    DietPlan.query.filter_by(user_id=int(user_id), ativa=True).update({'ativa': False})

    # Generate new diet
    from services.i18n import get_locale
    lang = get_locale()
    dieta_service = DietaService(lang=lang)
    
    dias = request.json.get('dias', 1)
    if dias not in [1, 7]:
        dias = 1

    orcamento = request.json.get('orcamento', 'padrao')
        
    plano = dieta_service.gerar_plano(
        sexo=user.sexo,
        idade=user.idade,
        altura=user.altura,
        peso=user.peso,
        nivel_atividade=user.nivel_atividade or 'moderado',
        objetivo=request.json.get('objetivo', user.objetivo or 'manter'),
        ritmo_meta=request.json.get('ritmo', 'padrao'),
        dias=dias,
        orcamento=orcamento
    )

    # Save to database
    import json
    diet_plan = DietPlan(
        user_id=int(user_id),
        calorias_totais=plano['calorias_totais'],
        proteinas_g=plano['proteinas_g'],
        carboidratos_g=plano['carboidratos_g'],
        gorduras_g=plano['gorduras_g'],
        refeicoes=json.dumps(plano['refeicoes']),
        objetivo=plano['objetivo'],
        duracao=dias,
        ativa=True,
    )

    db.session.add(diet_plan)
    
    # AI Personal Trainer: Coordinated Workout Generation
    try:
        # Get level from user activity
        nivel = 'intermediario'
        if user.nivel_atividade in ['sedentario', 'leve']:
            nivel = 'iniciante'
        elif user.nivel_atividade in ['intenso', 'muito_intenso']:
            nivel = 'avancado'
            
        # Deactivate old plans
        TrainingPlan.query.filter_by(user_id=int(user_id), ativo=True).update({'ativo': False})
        
        # Access TreinoService
        treino_service = TreinoService(lang=lang)
        programa = treino_service.get_programa_completo(nivel=nivel, objetivo=diet_plan.objetivo)
        
        # Save all 5 training days
        for day in programa:
            tp = TrainingPlan(
                user_id=int(user_id),
                nome=day['nome'],
                tipo_treino=day['tipo'],
                grupo_muscular=', '.join(set(ex['grupo_muscular'] for ex in day['exercicios'])),
                exercicios=json.dumps(day['exercicios']),
                nivel=nivel,
                ativo=True
            )
            db.session.add(tp)
    except Exception as e:
        print(f"[ShapePro AI] Coordinated workout error: {e}")

    db.session.commit()

    return jsonify({
        'message': t('diet_generated') + " & Treinos coordenados!",
        'dieta': diet_plan.to_dict(),
        'treino_sincronizado': True,
        'objetivo': diet_plan.objetivo
    }), 201


@plan_bp.route('/dieta', methods=['GET'])
@jwt_required()
def get_dieta():
    """Get the user's active diet plan."""
    user_id = get_jwt_identity()
    diet_plan = DietPlan.query.filter_by(
        user_id=int(user_id), ativa=True
    ).order_by(DietPlan.data_criacao.desc()).first()

    if not diet_plan:
        return jsonify({'error': t('no_active_diet_found')}), 404

    # Translate meal names on the fly for the current language
    plan_dict = diet_plan.to_dict()
    from services.i18n import get_locale, t
    lang = get_locale()
    
    # Map of meal name translations to ensure consistency
    meal_map = {
        'Café da manhã': t('meal_breakfast'),
        'Breakfast': t('meal_breakfast'),
        'Lanche da manhã': t('meal_morning_snack'),
        'Morning Snack': t('meal_morning_snack'),
        'Almoço': t('meal_lunch'),
        'Lunch': t('meal_lunch'),
        'Lanche da tarde': t('meal_afternoon_snack'),
        'Afternoon Snack': t('meal_afternoon_snack'),
        'Jantar': t('meal_dinner'),
        'Dinner': t('meal_dinner'),
        'Ceia': t('meal_late_snack'),
        'Late Snack': t('meal_late_snack')
    }
    
    for r in plan_dict['refeicoes']:
        if 'refeicoes' in r: # 7-day plan (list of days)
            for refeicao in r['refeicoes']:
                curr_name = refeicao.get('nome')
                if curr_name in meal_map:
                    refeicao['nome'] = meal_map[curr_name]
        else: # 1-day plan (list of meals)
            curr_name = r.get('nome')
            if curr_name in meal_map:
                r['nome'] = meal_map[curr_name]

    # FREE TRIAL LOGIC (PAYWALL)
    user = User.query.get(int(user_id))
    is_free = not getattr(user, 'assinatura_ativa', False) or getattr(user, 'plano_assinatura', 'free') == 'free'
    
    # Conditional Trial: 3 days with card, 2 days without
    has_card = getattr(user, 'cartao_cadastrado', False)
    trial_days = 3 if has_card else 2
    
    from datetime import datetime
    days_active = (datetime.utcnow() - user.data_criacao).days
    trial_active = days_active < trial_days
            
    if is_free:
        # Full access during trial IF card is registered. 
        # Content locks ONLY if trial is expired OR if it's the basic (no-card) trial.
        if (not trial_active) or (not has_card):
            if 'refeicoes' in plan_dict['refeicoes'][0]: 
                # 7-day plan structure
                for day in plan_dict['refeicoes']:
                    for i, refeicao in enumerate(day['refeicoes']):
                        # Basic trial (no card) only shows first 2 meals. Expired trial shows 0.
                        limit = 2 if trial_active else -1
                        if i > limit:
                            refeicao['alimentos'] = []
                            refeicao['is_locked'] = True
            else:
                # 1-day plan structure
                for i, refeicao in enumerate(plan_dict['refeicoes']):
                    limit = 2 if trial_active else -1
                    if i > limit:
                        refeicao['alimentos'] = []
                        refeicao['is_locked'] = True

    return jsonify({'dieta': plan_dict}), 200


@plan_bp.route('/dieta/historico', methods=['GET'])
@jwt_required()
def get_dieta_historico():
    """Get diet history."""
    user_id = get_jwt_identity()
    plans = DietPlan.query.filter_by(
        user_id=int(user_id)
    ).order_by(DietPlan.data_criacao.desc()).limit(10).all()

    return jsonify({'historico': [p.to_dict() for p in plans]}), 200


@plan_bp.route('/treino', methods=['GET'])
@jwt_required()
def get_treinos():
    """Get all available training programs."""
    from services.i18n import get_locale
    lang = get_locale()
    treino_service = TreinoService(lang=lang)
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    nivel = 'intermediario'
    if user and user.nivel_atividade:
        if user.nivel_atividade in ['sedentario', 'leve']:
            nivel = 'iniciante'
        elif user.nivel_atividade in ['intenso', 'muito_intenso']:
            nivel = 'avancado'

    # AI Trainer: Prefer database plans if active
    db_plans = TrainingPlan.query.filter_by(user_id=int(user_id), ativo=True).all()
    
    if db_plans:
        # Re-map DB result to TreinoService format
        from services.i18n import t
        treinos = []
        # Sort by type A->E
        db_plans.sort(key=lambda x: x.tipo_treino)
        for p in db_plans:
            t_dict = p.to_dict()
            t_dict['tipo'] = p.tipo_treino
            # Estimate time from exercicios count
            t_dict['tempo_estimado'] = f"{len(t_dict['exercicios']) * 6} min"
            treinos.append(t_dict)
            
        # FREE TRIAL LOGIC (PAYWALL)
        is_free = not getattr(user, 'assinatura_ativa', False) or getattr(user, 'plano_assinatura', 'free') == 'free'
        has_card = getattr(user, 'cartao_cadastrado', False)
        trial_days = 3 if has_card else 2
        
        from datetime import datetime
        days_active = (datetime.utcnow() - user.data_criacao).days
        trial_active = days_active < trial_days
                
        if is_free:
            # If trial with card, full access (is_locked=False). 
            # If no card or trial expired, only Treino A (index 0) is available during trial.
            if (not trial_active) or (not has_card):
                for i, t_dict in enumerate(treinos):
                    limit = 0 if trial_active else -1 # One workout during trial. None after.
                    if i > limit:
                        t_dict['exercicios'] = []
                        t_dict['is_locked'] = True

        return jsonify({'treinos': treinos, 'custom': True}), 200

    # Fallback to defaults
    treinos = treino_service.get_programa_completo(nivel)
    return jsonify({'treinos': treinos, 'custom': False}), 200


@plan_bp.route('/treino/<tipo>', methods=['GET'])
@jwt_required()
def get_treino_por_tipo(tipo):
    """Get a specific training by type (A, B, C, D, E)."""
    from services.i18n import get_locale
    lang = get_locale()
    treino_service = TreinoService(lang=lang)
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))
    nivel = 'intermediario'
    if user and user.nivel_atividade:
        if user.nivel_atividade in ['sedentario', 'leve']:
            nivel = 'iniciante'
        elif user.nivel_atividade in ['intenso', 'muito_intenso']:
            nivel = 'avancado'

    treino = treino_service.get_treino_por_tipo(tipo.upper(), nivel)
    if not treino:
        return jsonify({'error': t('workout_type_not_found', tipo=tipo)}), 404

    return jsonify({'treino': treino}), 200


@plan_bp.route('/treino/concluir', methods=['POST'])
@jwt_required()
def concluir_treino():
    """Conclude a workout session and update the streaks."""
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))

    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    user.treinos_concluidos = (user.treinos_concluidos or 0) + 1

    # Update streak
    from services.streak_service import StreakService
    streak = StreakService.atualizar_streak(user)

    # Check & unlock achievements
    novas_conquistas = StreakService.verificar_conquistas(user)

    # Auto-update training challenges
    try:
        from models.challenge import UserChallenge, Challenge
        active = UserChallenge.query.join(Challenge).filter(
            UserChallenge.user_id == int(user_id),
            UserChallenge.status == 'ativo',
            Challenge.categoria == 'treino'
        ).all()
        from datetime import datetime
        for uc in active:
            uc.progresso = (uc.progresso or 0) + 1
            if uc.progresso >= uc.challenge.meta_valor:
                uc.status = 'concluido'
                uc.data_conclusao = datetime.utcnow()
                user.pontos_xp = (user.pontos_xp or 0) + uc.challenge.pontos_xp
    except Exception as e:
        print(f'[ShapePro] Challenge update error: {e}')

    db.session.commit()

    return jsonify({
        'message': t('workout_concluded'),
        'treinos_concluidos': user.treinos_concluidos,
        'streak_atual': streak,
        'melhor_streak': user.melhor_streak or 0,
        'pontos_xp': user.pontos_xp or 0,
        'novas_conquistas': [a.to_dict() for a in novas_conquistas],
    }), 200


@plan_bp.route('/achievements', methods=['GET'])
@jwt_required()
def get_achievements():
    """Get all achievements and user's unlocked ones."""
    from models.challenge import Achievement, UserAchievement

    user_id = int(get_jwt_identity())
    all_achievements = Achievement.query.all()
    unlocked = {ua.achievement_id for ua in UserAchievement.query.filter_by(user_id=user_id).all()}

    result = []
    for ach in all_achievements:
        d = ach.to_dict()
        d['desbloqueado'] = ach.id in unlocked
        result.append(d)

    return jsonify({'achievements': result}), 200


@plan_bp.route('/exercicios', methods=['GET'])
@jwt_required()
def get_exercicios():
    """Get all exercises, optionally filtered by muscle group."""
    from services.i18n import get_locale
    lang = get_locale()
    treino_service = TreinoService(lang=lang)
    grupo = request.args.get('grupo', None)

    if grupo:
        exercicios = treino_service.get_exercicios_por_grupo(grupo)
    else:
        exercicios = treino_service.get_todos_exercicios()

    return jsonify({'exercicios': exercicios}), 200


@plan_bp.route('/progresso', methods=['GET'])
@jwt_required()
def get_progresso():
    """Get user's overall progress data."""
    from models.user import WeightLog

    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))

    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    # Weight history
    weight_logs = WeightLog.query.filter_by(
        user_id=int(user_id)
    ).order_by(WeightLog.data.asc()).limit(30).all()

    # Active diet
    dieta_ativa = DietPlan.query.filter_by(
        user_id=int(user_id), ativa=True
    ).first()

    # Count completed plans
    total_dietas = DietPlan.query.filter_by(user_id=int(user_id)).count()

    # Streak & XP
    streak_data = {
        'streak_atual': user.streak_atual or 0,
        'melhor_streak': user.melhor_streak or 0,
        'pontos_xp': user.pontos_xp or 0,
    }

    # Active challenges
    from models.challenge import UserChallenge, UserAchievement, SleepLog, JournalEntry
    from datetime import timedelta
    now_dt = __import__('datetime').datetime.utcnow()

    desafios_ativos = UserChallenge.query.filter_by(
        user_id=int(user_id), status='ativo'
    ).limit(5).all()

    # Achievements count
    total_conquistas = UserAchievement.query.filter_by(user_id=int(user_id)).count()

    # Sleep average (7 days)
    week_sleep = SleepLog.query.filter(
        SleepLog.user_id == int(user_id),
        SleepLog.data >= now_dt - timedelta(days=7)
    ).all()
    media_sono = round(sum(s.duracao_horas for s in week_sleep) / len(week_sleep), 1) if week_sleep else 0

    # Journal average mood (7 days)
    week_journal = JournalEntry.query.filter(
        JournalEntry.user_id == int(user_id),
        JournalEntry.data >= now_dt - timedelta(days=7)
    ).all()
    media_humor = round(sum(j.humor for j in week_journal) / len(week_journal), 1) if week_journal else 0

    progresso = {
        'usuario': user.to_dict(),
        'imc': user.calcular_imc(),
        'classificacao_imc': user.classificar_imc(),
        'historico_peso': [log.to_dict() for log in weight_logs],
        'dieta_ativa': dieta_ativa.to_dict() if dieta_ativa else None,
        'total_dietas_geradas': total_dietas,
        # New BetFit-inspired data
        **streak_data,
        'desafios_ativos': [d.to_dict() for d in desafios_ativos],
        'total_conquistas': total_conquistas,
        'media_sono_7d': media_sono,
        'media_humor_7d': media_humor,
    }

    return jsonify({'progresso': progresso}), 200


@plan_bp.route('/assinatura', methods=['POST'])
@jwt_required()
def update_assinatura():
    """Update user subscription status."""
    user_id = get_jwt_identity()
    user = User.query.get(int(user_id))

    if not user:
        return jsonify({'error': t('user_not_found')}), 404

    data = request.get_json()
    if not data or 'plano' not in data:
        return jsonify({'error': t('subscription_required')}), 400

    plano = data['plano']
    if plano not in ['free', 'mensal', 'anual']:
        return jsonify({'error': t('invalid_plan')}), 400

    user.plano_assinatura = plano
    user.assinatura_ativa = plano != 'free'
    db.session.commit()

    return jsonify({
        'message': t('subscription_updated', plano=plano),
        'user': user.to_dict(),
    }), 200
