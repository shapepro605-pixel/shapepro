import smtplib
from email.mime.text import MIMEText

MAIL_SERVER = 'smtp.gmail.com'
MAIL_PORT = 465
MAIL_USERNAME = 'shapepro605@gmail.com'
MAIL_PASSWORD = 'xhqncucedyvjpucu'

def test_email():
    print(f"Tentando conectar ao Gmail SMTP {MAIL_SERVER}:{MAIL_PORT} (SSL)...")
    try:
        # Tenta modo SSL direto (porta 465)
        server = smtplib.SMTP_SSL(MAIL_SERVER, MAIL_PORT, timeout=15)
        server.set_debuglevel(1)
        print("Logando...")
        server.login(MAIL_USERNAME, MAIL_PASSWORD)
        print("Login com sucesso!!")
        
        msg = MIMEText("Teste de envio de e-mail.")
        msg['Subject'] = "Teste ShapePro SMTP"
        msg['From'] = MAIL_USERNAME
        msg['To'] = MAIL_USERNAME
        
        print("Enviando e-mail...")
        server.send_message(msg)
        print("E-mail finalizado com sucesso!")
        server.quit()
        
    except Exception as e:
        print(f"\n[FALHA] Erro com SSL {MAIL_PORT}: {e}")
        
        print("\nTentando fallback para porta 587 (TLS)...")
        try:
            server_tls = smtplib.SMTP(MAIL_SERVER, 587, timeout=15)
            server_tls.set_debuglevel(1)
            server_tls.starttls()
            server_tls.login(MAIL_USERNAME, MAIL_PASSWORD)
            print("Login TLS com sucesso!!")
            server_tls.quit()
        except Exception as e2:
            print(f"[FALHA] Erro com TLS 587: {e2}")

if __name__ == '__main__':
    test_email()
