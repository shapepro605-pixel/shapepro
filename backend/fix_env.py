import json
import os

def update_env_from_file():
    # Caminho do arquivo baixado pelo usuário
    json_path = r'c:\Users\mae12\Downloads\shapepro-d6801-firebase-adminsdk-fbsvc-fc422f8b5a.json'
    # Caminho do arquivo .env
    env_path = r'c:\Users\mae12\.gemini\antigravity\scratch\shapepro\backend\.env'
    
    if not os.path.exists(json_path):
        print(f"❌ ERRO: Arquivo não encontrado em {json_path}")
        return

    # Lê o JSON original
    with open(json_path, 'r', encoding='utf-8') as f:
        creds = json.load(f)

    # Converte para string JSON compacta (uma linha)
    creds_str = json.dumps(creds)

    # Lê as linhas atuais do .env
    with open(env_path, 'r', encoding='utf-8') as f:
        lines = f.readlines()

    # Atualiza a linha específica
    new_lines = []
    found = False
    for line in lines:
        if line.strip().startswith('FIREBASE_CREDENTIALS_JSON='):
            new_lines.append(f"FIREBASE_CREDENTIALS_JSON='{creds_str}'\n")
            found = True
        else:
            new_lines.append(line)
    
    if not found:
        new_lines.append(f"FIREBASE_CREDENTIALS_JSON='{creds_str}'\n")

    # Escreve de volta
    with open(env_path, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
    
    print("✅ SUCESSO: Arquivo .env atualizado com a chave real extraída do arquivo original.")

if __name__ == "__main__":
    update_env_from_file()
