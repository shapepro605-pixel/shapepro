const functions = require('firebase-functions');
const admin = require('firebase-admin');
const nodemailer = require('nodemailer');

admin.initializeApp();

// Configuração do transportador de e-mail (usando seu Gmail profissional)
const transporter = nodemailer.createTransport({
    service: 'gmail',
    auth: {
        user: 'shapepro605@gmail.com',
        pass: 'xhqncucedyvjpucu' // Sua senha de app já configurada
    }
});

/**
 * Cloud Function para enviar o código de verificação de 6 dígitos.
 * Chamada via HTTPS pelo seu backend na Railway.
 */
exports.sendVerificationCode = functions.https.onRequest(async (req, res) => {
    // Segurança: Verificar se a requisição veio do nosso servidor (opcional mas recomendado)
    // const authHeader = req.headers.authorization;
    // if (authHeader !== 'Bearer SEU_TOKEN_DE_SEGURANCA') return res.status(403).send('Unauthorized');

    const { email, nome, code } = req.body;

    if (!email || !code) {
        return res.status(400).send('E-mail e código são obrigatórios.');
    }

    const mailOptions = {
        from: '"ShapePro Support" <shapepro605@gmail.com>',
        to: email,
        subject: `${code} é o seu código de verificação ShapePro`,
        html: `
            <div style="font-family: sans-serif; max-width: 600px; margin: 0 auto; background-color: #0A0A1A; color: white; padding: 40px; border-radius: 20px;">
                <div style="text-align: center; margin-bottom: 30px;">
                    <h1 style="color: #6C5CE7; font-size: 32px; margin: 0;">ShapePro</h1>
                    <p style="color: #aaa; font-size: 14px;">Sua jornada fitness começa aqui</p>
                </div>
                
                <h2 style="font-size: 24px; text-align: center;">Olá, ${nome || 'Atleta'}!</h2>
                <p style="font-size: 16px; line-height: 1.6; text-align: center; color: #ccc;">
                    Obrigado por se juntar à nossa comunidade. Use o código abaixo para validar sua conta e começar agora mesmo:
                </p>
                
                <div style="background-color: #16162A; border: 2px solid #6C5CE7; border-radius: 15px; padding: 20px; margin: 30px 0; text-align: center;">
                    <span style="font-size: 42px; font-weight: bold; letter-spacing: 10px; color: white;">${code}</span>
                </div>
                
                <p style="font-size: 14px; text-align: center; color: #777; margin-top: 40px;">
                    Este código expira em 30 minutos.<br>
                    Se você não solicitou este cadastro, pode ignorar este e-mail com segurança.
                </p>
                
                <hr style="border: 0; border-top: 1px solid #222; margin: 40px 0;">
                
                <p style="font-size: 12px; text-align: center; color: #555;">
                    © 2026 ShapePro Fitness. Todos os direitos reservados.
                </p>
            </div>
        `
    };

    try {
        await transporter.sendMail(mailOptions);
        console.log(`[SUCCESS] E-mail enviado para ${email}`);
        return res.status(200).json({ success: true, message: 'E-mail enviado com sucesso.' });
    } catch (error) {
        console.error('[ERROR] Falha ao enviar e-mail:', error);
        return res.status(500).json({ success: false, error: error.message });
    }
});
