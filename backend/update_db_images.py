import json
import os
from app import create_app
from database import db
from models.user import TrainingPlan

def update_images():
    app = create_app()
    with app.app_context():
        # 1. Carregar exercicios.json e achatar para busca rápida por nome
        base_dir = os.path.dirname(os.path.abspath(__file__))
        path_pt = os.path.join(base_dir, 'data', 'exercises.json')
        path_en = os.path.join(base_dir, 'data', 'exercises_en.json')
        
        lookup = {}
        if os.path.exists(path_pt):
            with open(path_pt, 'r', encoding='utf-8') as f:
                data = json.load(f)
                for grupo, exs in data.items():
                    for ex in exs:
                        lookup[ex['nome']] = ex.get('imagem')
        
        if os.path.exists(path_en):
            with open(path_en, 'r', encoding='utf-8') as f:
                data = json.load(f)
                for grupo, exs in data.items():
                    for ex in exs:
                        lookup[ex['nome']] = ex.get('imagem')

        # 2. Buscar todos os planos de treino ativos
        plans = TrainingPlan.query.all()
        updated_count = 0
        
        for plan in plans:
            try:
                exercicios = json.loads(plan.exercicios)
                changed = False
                for ex in exercicios:
                    # Se o nome existe no lookup e a imagem é diferente da atual (ou vazia)
                    new_img = lookup.get(ex['nome'])
                    if new_img and ex.get('imagem') != new_img:
                        ex['imagem'] = new_img
                        changed = True
                
                if changed:
                    plan.exercicios = json.dumps(exercicios, ensure_ascii=False)
                    updated_count += 1
            except Exception as e:
                print(f"Erro ao atualizar plano {plan.id}: {e}")

        db.session.commit()
        print(f"Sucesso! {updated_count} planos de treino foram atualizados com novas imagens.")

if __name__ == '__main__':
    update_images()
