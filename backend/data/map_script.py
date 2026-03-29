import json
import os
import difflib

def main():
    base_dir = os.path.dirname(os.path.abspath(__file__))
    en_path = os.path.join(base_dir, 'exercises_en.json')
    pt_path = os.path.join(base_dir, 'exercises.json')
    db_path = os.path.join(base_dir, 'free_exercises_db.json')

    # Load open source database
    with open(db_path, 'r', encoding='utf-8') as f:
        free_db = json.load(f)

    # Create a quick dictionary mapping names to image URLs
    db_names = []
    db_map = {}
    for ex in free_db:
        name = ex['name']
        db_names.append(name)
        if ex.get('images'):
            img_path = ex['images'][0]  # Take the first image (start position), or try to take [1] for end position.
            # Using 1.jpg is usually the flexed position which is cooler, let's use 1 if len > 1 else 0
            img_index = 1 if len(ex['images']) > 1 else 0
            selected_img = ex['images'][img_index]
            raw_url = f"https://raw.githubusercontent.com/yuhonas/free-exercise-db/main/exercises/{selected_img}"
            # Se quiser podemos retornar uma string contendo ambas as imagens para o Frontend iterar
            # Mas o mais compatível agora é retornar apenas uma.
            db_map[name] = raw_url

    # Load our datasets
    with open(en_path, 'r', encoding='utf-8') as f:
        data_en = json.load(f)
        
    with open(pt_path, 'r', encoding='utf-8') as f:
        data_pt = json.load(f)

    # Manually override certain tricky exercises to ensure perfection
    # because difflib might miss some obvious translations
    manual_overrides = {
        "Cable Crossover": "Cable Crossover",
        "Dumbbell Pullover": "Bent-Arm Dumbbell Pullover",
        "Barbell Squat": "Barbell Squat",
        "Sumo Squat": "Plie Dumbbell Squat",
        "Leg Extension": "Leg Extensions",
        "Leg Curl": "Seated Leg Curl",
        "Calf Raise": "Standing Calf Raises",
        "Barbell Curl": "Barbell Curl",
        "Hammer Curl": "Alternate Hammer Curl",
        "Triceps Pushdown": "Triceps Pushdown",
        "Triceps Extension": "Standing Dumbbell Triceps Extension",
        "Military Press": "Standing Military Press",
        "Lateral Raise": "Side Lateral Raise",
        "Front Raise": "Front Dumbbell Raise",
        "Crunch": "Crunch - Hands Over Head",
        "Leg Raise": "Hanging Leg Raise"
    }

    matched_count = 0
    total_count = 0

    for group_key in data_en.keys():
        for i, ex_en in enumerate(data_en[group_key]):
            total_count += 1
            ex_pt = data_pt[group_key][i]
            
            search_name = manual_overrides.get(ex_en['nome'], ex_en['nome'])
            matches = difflib.get_close_matches(search_name, db_names, n=1, cutoff=0.5)
            
            if matches:
                best_match = matches[0]
                img_url = db_map[best_match]
                
                # Update both english and portuguese datasets
                ex_en['imagem'] = img_url
                ex_pt['imagem'] = img_url
                matched_count += 1
                r_status = f"✅ MATCH: {ex_en['nome']} -> {best_match}"
            else:
                r_status = f"❌ MISS: {ex_en['nome']}"
            
            print(r_status)

    # Save back
    with open(en_path, 'w', encoding='utf-8') as f:
        json.dump(data_en, f, indent=4, ensure_ascii=False)
        
    with open(pt_path, 'w', encoding='utf-8') as f:
        json.dump(data_pt, f, indent=4, ensure_ascii=False)

    print(f"\nCompleted: {matched_count}/{total_count} exercises updated successfully!")
    
    # Let's also run an update on training_plans table inside database
    import sys
    sys.path.append(os.path.dirname(base_dir))
    from app import create_app
    from database import db
    from models.user import TrainingPlan
    
    app = create_app()
    with app.app_context():
        plans = TrainingPlan.query.all()
        u_count = 0
        pt_lookup = {ex['nome']: ex['imagem'] for group in data_pt.values() for ex in group}
        en_lookup = {ex['nome']: ex['imagem'] for group in data_en.values() for ex in group}
        
        for p in plans:
            ex_list = json.loads(p.exercicios)
            c = False
            for ex in ex_list:
                n = ex.get('nome')
                new_img = pt_lookup.get(n) or en_lookup.get(n)
                if new_img and ex.get('imagem') != new_img:
                    ex['imagem'] = new_img
                    c = True
            if c:
                p.exercicios = json.dumps(ex_list, ensure_ascii=False)
                u_count += 1
                
        db.session.commit()
        print(f"Database updated: {u_count} plans refreshed with new images.")

if __name__ == '__main__':
    main()
