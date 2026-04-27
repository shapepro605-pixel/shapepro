"""
ShapePro - Script de Teste de Verificacao (Email + SMS)
Testa os endpoints de producao no Railway sem precisar do app.
"""
import sys
import os
os.environ["PYTHONIOENCODING"] = "utf-8"
sys.stdout.reconfigure(encoding='utf-8')

import requests
import json
import time

# -- Configuracao --
BASE_URL = "https://shapepro-production.up.railway.app/api"

def print_header(text):
    print(f"\n{'='*60}")
    print(f"  >>> {text}")
    print(f"{'='*60}")

def print_ok(text):
    print(f"  [OK] {text}")

def print_fail(text):
    print(f"  [FALHA] {text}")

def print_info(text):
    print(f"  [INFO] {text}")

def print_warn(text):
    print(f"  [AVISO] {text}")

# -- Teste 1: Health Check --
def test_health():
    print_header("TESTE 1: Health Check do Servidor")
    try:
        r = requests.get(f"{BASE_URL.replace('/api','')}/health", timeout=10)
        data = r.json()
        if data.get('status') == 'healthy':
            print_ok(f"Servidor ONLINE - versao {data.get('version')}")
            return True
        else:
            print_fail(f"Resposta inesperada: {data}")
            return False
    except Exception as e:
        print_fail(f"Servidor OFFLINE: {e}")
        return False

# -- Teste 2: Firebase Status --
def test_firebase():
    print_header("TESTE 2: Status do Firebase")
    try:
        r = requests.get(f"{BASE_URL}/auth/debug_firebase", timeout=10)
        data = r.json()
        
        if data.get('initialized'):
            print_ok(f"Firebase INICIALIZADO")
        else:
            print_fail("Firebase NAO inicializado")
        
        if data.get('has_creds'):
            print_ok(f"Credenciais presentes (tamanho: {data.get('creds_len')} chars)")
        else:
            print_fail("Credenciais AUSENTES")
        
        env_keys = data.get('env_keys', [])
        mail_keys = [k for k in env_keys if 'MAIL' in k]
        print_info(f"Variaveis de email: {mail_keys}")
        
        return data.get('initialized', False)
    except Exception as e:
        print_fail(f"Erro: {e}")
        return False

# -- Teste 3: Registro + Verificacao Email --
def test_register_and_email():
    print_header("TESTE 3: Registro de Novo Usuario + Email de Verificacao")
    
    test_email = input("\n  >> Digite o EMAIL para receber o codigo (ex: seuemail@gmail.com): ").strip()
    
    if not test_email:
        print_fail("Email nao fornecido. Pulando teste.")
        return None, None
    
    timestamp = int(time.time())
    test_data = {
        "email": test_email,
        "password": "teste123456",
        "nome": "Teste Verificacao",
        "telefone": f"+5511999{timestamp % 100000:05d}",
    }
    
    print_info(f"Registrando: {test_data['email']}")
    
    try:
        r = requests.post(f"{BASE_URL}/auth/register", json=test_data, timeout=15)
        data = r.json()
        
        if r.status_code == 201 and data.get('success'):
            print_ok(f"Conta criada com sucesso!")
            print_ok(f"ID do usuario: {data['user'].get('id')}")
            print_ok(f"Email verificado: {data['user'].get('email_verificado', False)}")
            print_info(f"Um email de verificacao foi enviado automaticamente no registro.")
            
            token = data.get('access_token')
            return token, test_email
            
        elif r.status_code == 409:
            print_warn(f"Usuario ja existe: {data.get('error')}")
            print_info("Tentando fazer login...")
            return test_login(test_email, "teste123456")
        else:
            print_fail(f"Erro {r.status_code}: {data.get('error')}")
            if "email" in str(data.get('error', '')).lower():
                print_info("Tentando fazer login com a conta existente...")
                return test_login(test_email, None)
            return None, None
            
    except Exception as e:
        print_fail(f"Erro na requisicao: {e}")
        return None, None

def test_login(email, password):
    """Faz login com uma conta existente."""
    if not password:
        password = input(f"  >> Digite a senha da conta {email}: ").strip()
    
    try:
        r = requests.post(f"{BASE_URL}/auth/login", json={
            "email": email,
            "password": password
        }, timeout=10)
        data = r.json()
        
        if r.status_code == 200 and data.get('success'):
            print_ok(f"Login realizado com sucesso!")
            print_info(f"Email verificado: {data['user'].get('email_verificado', False)}")
            return data.get('access_token'), email
        else:
            print_fail(f"Login falhou: {data.get('error')}")
            return None, None
    except Exception as e:
        print_fail(f"Erro: {e}")
        return None, None

# -- Teste 4: Enviar Email de Verificacao --
def test_send_verification_email(token):
    print_header("TESTE 4: Envio de Email de Verificacao (Codigo 6 digitos)")
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    try:
        print_info("Enviando email de verificacao...")
        r = requests.post(f"{BASE_URL}/auth/send_verification_email", headers=headers, timeout=30)
        data = r.json()
        
        if r.status_code == 200 and data.get('success'):
            print_ok(f"EMAIL ENVIADO COM SUCESSO!")
            print_ok(f"Mensagem: {data.get('message')}")
            return True
        else:
            print_fail(f"Falha no envio: {data.get('error', data)}")
            return False
    except requests.exceptions.Timeout:
        print_fail("TIMEOUT - o servidor demorou mais de 30s para responder")
        return False
    except Exception as e:
        print_fail(f"Erro: {e}")
        return False

# -- Teste 5: Verificar Codigo OTP --
def test_verify_code(token):
    print_header("TESTE 5: Verificacao do Codigo OTP")
    
    code = input("\n  >> Digite o codigo de 6 digitos recebido no email: ").strip()
    
    if not code or len(code) != 6:
        print_fail("Codigo deve ter 6 digitos.")
        return False
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    try:
        r = requests.post(f"{BASE_URL}/auth/verify_email_code", 
                         headers=headers, 
                         json={"code": code}, 
                         timeout=10)
        data = r.json()
        
        if r.status_code == 200 and data.get('success'):
            print_ok(f"EMAIL VERIFICADO COM SUCESSO!")
            print_ok(f"email_verificado: {data.get('user', {}).get('email_verificado')}")
            return True
        else:
            print_fail(f"Codigo invalido: {data.get('error')}")
            return False
    except Exception as e:
        print_fail(f"Erro: {e}")
        return False

# -- Teste 6: Reset de Senha --
def test_reset_password():
    print_header("TESTE 6: Reset de Senha (Email)")
    
    email = input("\n  >> Digite o email para resetar a senha: ").strip()
    
    if not email:
        print_warn("Pulando teste de reset.")
        return
    
    try:
        r = requests.post(f"{BASE_URL}/auth/reset_password", 
                         json={"email": email}, 
                         timeout=15)
        data = r.json()
        
        if data.get('success'):
            print_ok(f"Solicitacao de reset enviada!")
            print_info("Verifique o email para a senha temporaria.")
        else:
            print_fail(f"Erro: {data.get('error')}")
    except Exception as e:
        print_fail(f"Erro: {e}")

# -- Teste 7: Verificar Perfil --
def test_profile(token):
    print_header("TESTE 7: Verificar Status do Perfil")
    
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    
    try:
        r = requests.get(f"{BASE_URL}/auth/profile", headers=headers, timeout=10)
        data = r.json()
        
        if data.get('user'):
            user = data['user']
            print_ok(f"Nome: {user.get('nome')}")
            print_ok(f"Email: {user.get('email')}")
            print_ok(f"Telefone: {user.get('telefone')}")
            ev = "SIM" if user.get('email_verificado') else "NAO"
            tv = "SIM" if user.get('telefone_verificado') else "NAO"
            print_info(f"Email verificado: {ev}")
            print_info(f"Telefone verificado: {tv}")
            print_info(f"Plano: {user.get('plano', 'free')}")
            return user
        else:
            print_fail(f"Erro: {data.get('error')}")
            return None
    except Exception as e:
        print_fail(f"Erro: {e}")
        return None

# -- Menu Principal --
def main():
    print("""
============================================================
     ShapePro - Teste de Verificacao Completo
     Email + SMS + Firebase + Perfil
============================================================
""")
    print(f"  Servidor: {BASE_URL}")
    print()

    # 1. Health check
    if not test_health():
        print_fail("Servidor offline. Abortando.")
        return

    # 2. Firebase
    test_firebase()

    # 3. Menu
    token = None
    email = None
    
    while True:
        print(f"""
-- MENU --------------------------------------------------
  1 -> Registrar novo usuario + receber email
  2 -> Login com conta existente
  3 -> Enviar email de verificacao (requer login)
  4 -> Digitar codigo OTP recebido (requer login)
  5 -> Ver perfil completo (requer login)
  6 -> Reset de senha (email)
  7 -> Fluxo completo automatico (registro -> email -> codigo)
  0 -> Sair
-----------------------------------------------------------
""")
        
        choice = input("  Escolha: ").strip()
        
        if choice == "1":
            token, email = test_register_and_email()
            
        elif choice == "2":
            email_input = input("  Email: ").strip()
            password_input = input("  Senha: ").strip()
            token, email = test_login(email_input, password_input)
            
        elif choice == "3":
            if not token:
                print_fail("Faca login primeiro (opcao 1 ou 2).")
            else:
                test_send_verification_email(token)
                
        elif choice == "4":
            if not token:
                print_fail("Faca login primeiro (opcao 1 ou 2).")
            else:
                test_verify_code(token)
                
        elif choice == "5":
            if not token:
                print_fail("Faca login primeiro (opcao 1 ou 2).")
            else:
                test_profile(token)
                
        elif choice == "6":
            test_reset_password()
            
        elif choice == "7":
            # Fluxo completo
            print_header("FLUXO COMPLETO: Registro -> Email -> Verificacao")
            
            token, email = test_register_and_email()
            if not token:
                print_fail("Nao foi possivel obter token. Abortando fluxo.")
                continue
            
            # Enviar email
            sent = test_send_verification_email(token)
            if not sent:
                print_warn("Email pode nao ter sido enviado. Tentando verificar mesmo assim...")
            
            print("\n  >> Aguarde o email chegar na caixa de entrada (ou spam)...")
            print("     Quando receber, volte aqui e digite o codigo.\n")
            
            input("  Pressione ENTER quando estiver pronto para digitar o codigo...")
            
            # Verificar codigo
            test_verify_code(token)
            
            # Mostrar perfil final
            test_profile(token)
            
        elif choice == "0":
            print("\n  Ate mais!\n")
            break
        else:
            print_warn("Opcao invalida.")

if __name__ == "__main__":
    main()
