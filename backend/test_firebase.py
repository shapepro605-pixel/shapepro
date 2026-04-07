import os
from dotenv import load_dotenv
from firebase_init import init_firebase, is_firebase_initialized

def test():
    load_dotenv()
    print("Iniciando teste de conexão Firebase...")
    app = init_firebase()
    if is_firebase_initialized():
        print("✅ SUCESSO: Firebase foi inicializado corretamente com a nova chave!")
    else:
        print("❌ ERRO: Falha ao inicializar Firebase. Verifique o arquivo .env")

if __name__ == "__main__":
    test()
