import requests
import json
import secrets
import string
import sys

def debug_email_flow():
    print("\n" + "="*50)
    print("      SHAPEPRO - DIAGNÓSTICO DE E-MAIL (OTP)      ")
    print("="*50)

    # 1. Configurações
    email_teste = "shapepro605@gmail.com"
    nome_teste = "Atleta de Teste"
    code_teste = ''.join(secrets.choice(string.digits) for _ in range(6))
    
    # URL da Cloud Function
    cf_url = "https://us-central1-shapepro-d6801.cloudfunctions.net/sendVerificationCode"
    
    print(f"\n[1/3] Preparando teste para: {email_teste}")
    print(f"      Código Gerado: {code_teste}")

    # 2. Testando a Cloud Function diretamente
    print(f"\n[2/3] Testando Conexão com o Google (Cloud Function)...")
    print(f"      Destino: {cf_url}")
    
    try:
        response = requests.post(
            cf_url,
            json={
                "email": email_teste,
                "nome": nome_teste,
                "code": code_teste
            },
            timeout=10
        )
        
        if response.status_code == 200:
            print(f"      [OK] SUCESSO: A Cloud Function respondeu corretamente!")
            print(f"      Mensagem: {response.text}")
        elif response.status_code == 404:
            print(f"      [ERRO] ERRO 404: A função ainda não existe no Google.")
            print(f"      DICA: Você precisa rodar 'firebase deploy --only functions' com sucesso primeiro.")
        else:
            print(f"      [ERRO] ERRO {response.status_code}: O Google retornou um erro.")
            print(f"      Detalhes: {response.text}")
            
    except requests.exceptions.Timeout:
        print(f"      [ERRO] Tempo de resposta excedido (Timeout).")
    except requests.exceptions.ConnectionError:
        print(f"      [ERRO] Não foi possível conectar ao servidor do Google.")
    except Exception as e:
        print(f"      [ERRO] ERRO INESPERADO: {str(e)}")

    # 3. Verificando Logs do Firebase (Dica)
    print("\n[3/3] Próximos Passos para o Reparo:")
    print("      1. Se o erro for 404, o deploy falhou ou o nome do projeto está errado.")
    print("      2. Se o erro for 500, o problema está dentro do código index.js.")
    print("      3. Execute 'firebase functions:log' no terminal para ver o erro real no Google.")
    print("\n" + "="*50 + "\n")

if __name__ == "__main__":
    debug_email_flow()
