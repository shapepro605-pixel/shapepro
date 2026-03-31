import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';
import '../widgets/form_fields.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  int _currentStep = 0;
  final TextEditingController _pesoController = TextEditingController();
  
  bool _isLoading = false;
  String? _errorMessage;

  // Step 1: Conta
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nomeController = TextEditingController();
  bool _obscurePassword = true;

  // Step 2: Dados pessoais
  final _idadeController = TextEditingController();
  String _sexo = 'M';

  // Step 3: Medidas
  final _alturaController = TextEditingController();

  // Step 5: Telefone (inserted as Step 1)
  final _telefoneController = TextEditingController();


  // Step 4: Objetivo
  String _objetivo = 'perder_peso';
  String _nivelAtividade = 'moderado';
  final String _ritmoMeta = 'padrao';

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _nomeController.dispose();
    _idadeController.dispose();
    _alturaController.dispose();
    _pesoController.dispose();
    _telefoneController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final l10n = AppLocalizations.of(context)!;
    final api = Provider.of<ApiService>(context, listen: false);
    final result = await api.register(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      nome: _nomeController.text.trim(),
      idade: int.tryParse(_idadeController.text),
      altura: double.tryParse(_alturaController.text),
      peso: double.tryParse(_pesoController.text),
      sexo: _sexo,
      objetivo: _objetivo,
      nivelAtividade: _nivelAtividade,
      ritmoMeta: _ritmoMeta,
      telefone: _telefoneController.text.trim(),
    );

    if (mounted) {
      setState(() {
        _isLoading = false;
        if (result['success'] == true) {
          _errorMessage = null;
          // Redirect to the dedicated VerifySmsScreen after successful registration
          Navigator.pushNamedAndRemoveUntil(context, '/verify-sms', (route) => false);
        } else {
          _errorMessage = result['error'] ?? l10n.fillAllFields;
        }
      });
    }
  }

  void _nextStep() {
    if (_currentStep == 0) {
      if (_nomeController.text.isEmpty || _emailController.text.isEmpty || _passwordController.text.length < 6) {
        setState(() => _errorMessage = AppLocalizations.of(context)!.fillAllFields);
        return;
      }
    }
    if (_currentStep == 1) {
      if (_telefoneController.text.isEmpty) {
        setState(() => _errorMessage = AppLocalizations.of(context)!.phoneRequired);
        return;
      }
    }
    setState(() {
      _errorMessage = null;
      _currentStep++;
    });
  }


  void _previousStep() {
    setState(() {
      _errorMessage = null;
      _currentStep--;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0A0A1A), Color(0xFF12122A), Color(0xFF0A0A1A)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Header ──────────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Row(
                  children: [
                    if (_currentStep > 0)
                      GestureDetector(
                        onTap: _previousStep,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E38),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.arrow_back_ios_new, color: Colors.white70, size: 18),
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1E1E38),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.close, color: Colors.white70, size: 18),
                        ),
                      ),
                    const Spacer(),
                    Text(
                      AppLocalizations.of(context)!.step(_currentStep + 1, 5),
                      style: GoogleFonts.inter(color: Colors.white54, fontSize: 14),
                    ),
                  ],
                ),
              ),

              // ── Progress bar ────────────────────────────────
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Row(
                  children: List.generate(5, (i) => Expanded(
                    child: Container(
                      height: 4,
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(2),
                        color: i <= _currentStep
                            ? const Color(0xFF6C5CE7)
                            : const Color(0xFF2A2A4A),
                      ),
                    ),
                  )),
                ),
              ),

              // ── Content ─────────────────────────────────────
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 28),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 400),
                    child: _currentStep == 0
                      ? _buildStep1()
                      : (_currentStep == 1
                          ? _buildStepPhone()
                          : (_currentStep == 2
                              ? _buildStep2()
                              : (_currentStep == 3
                                  ? _buildStep3()
                                  : _buildStep4()))),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }






  // ── Step 1: Conta ───────────────────────────────────────────────────────

  Widget _buildStep1() {
    return Column(
      key: const ValueKey('step1'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 35),
        Text(AppLocalizations.of(context)!.createAccount, style: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
        )),
        const SizedBox(height: 8),
        Text(AppLocalizations.of(context)!.startJourney, style: GoogleFonts.inter(
          fontSize: 15, color: Colors.white54,
        )),
        const SizedBox(height: 35),
        if (_errorMessage != null) _buildError(),
        CustomLabel(label: AppLocalizations.of(context)!.fullName),
        const SizedBox(height: 8),
        TextFormField(
          controller: _nomeController,
          textCapitalization: TextCapitalization.words,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.yourName,
            prefixIcon: const Icon(Icons.person_outline, color: Color(0xFF6C5CE7)),
          ),
        ),
        const SizedBox(height: 20),
        CustomLabel(label: AppLocalizations.of(context)!.email),
        const SizedBox(height: 8),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.emailHint,
            prefixIcon: const Icon(Icons.email_outlined, color: Color(0xFF6C5CE7)),
          ),
        ),
        const SizedBox(height: 20),
        CustomLabel(label: AppLocalizations.of(context)!.password),
        const SizedBox(height: 8),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.passwordMinLength,
            prefixIcon: const Icon(Icons.lock_outline, color: Color(0xFF6C5CE7)),
            suffixIcon: IconButton(
              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility, color: Colors.white38),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
        const SizedBox(height: 35),
        _buildNextButton(AppLocalizations.of(context)!.continueBtn, _nextStep),
        const SizedBox(height: 30),
      ],
    );
  }

  // ── Step Phone: novo ───────────────────────────────────────────────────

  Widget _buildStepPhone() {
    return Column(
      key: const ValueKey('stepPhone'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionHeader(
          title: AppLocalizations.of(context)!.verifyPhone,
          subtitle: "Precisamos verificar seu número para segurança da sua conta.",
        ),
        const SizedBox(height: 20),
        if (_errorMessage != null) _buildError(),
        CustomLabel(label: AppLocalizations.of(context)!.phoneNumber),
        const SizedBox(height: 8),
        TextFormField(
          controller: _telefoneController,
          keyboardType: TextInputType.phone,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: AppLocalizations.of(context)!.phoneHint,
            prefixIcon: const Icon(Icons.phone_android_outlined, color: Color(0xFF6C5CE7)),
          ),
        ),
        const SizedBox(height: 40),
        _buildNextButton(AppLocalizations.of(context)!.continueBtn, _nextStep),
        const SizedBox(height: 30),
      ],
    );
  }

  // ── Step 2: Dados Pessoais ──────────────────────────────────────────────


  Widget _buildStep2() {
    return Column(
      key: const ValueKey('step2'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionHeader(
          title: AppLocalizations.of(context)!.aboutYou,
          subtitle: AppLocalizations.of(context)!.needData,
        ),
        CustomLabel(label: AppLocalizations.of(context)!.age),
        const SizedBox(height: 8),
        TextFormField(
          controller: _idadeController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: InputDecoration(
            hintText: '25',
            prefixIcon: const Icon(Icons.cake_outlined, color: Color(0xFF6C5CE7)),
            suffixText: AppLocalizations.of(context)!.years,
          ),
        ),
        const SizedBox(height: 25),
        CustomLabel(label: AppLocalizations.of(context)!.biologicalSex),
        const SizedBox(height: 12),
        Row(
          children: [
            SexOptionWidget(
              value: 'M',
              label: AppLocalizations.of(context)!.male,
              icon: Icons.male,
              isSelected: _sexo == 'M',
              onTap: () => setState(() => _sexo = 'M'),
            ),
            const SizedBox(width: 14),
            SexOptionWidget(
              value: 'F',
              label: AppLocalizations.of(context)!.female,
              icon: Icons.female,
              isSelected: _sexo == 'F',
              onTap: () => setState(() => _sexo = 'F'),
            ),
          ],
        ),
        const SizedBox(height: 35),
        _buildNextButton(AppLocalizations.of(context)!.continueBtn, _nextStep),
        const SizedBox(height: 30),
      ],
    );
  }

  // Step 3 will be handled next

  Widget _buildStep3() {
    return Column(
      key: const ValueKey('step3'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionHeader(
          title: AppLocalizations.of(context)!.yourMeasures,
          subtitle: AppLocalizations.of(context)!.measuresSubtitle,
        ),
        CustomLabel(label: AppLocalizations.of(context)!.altura),
        const SizedBox(height: 8),
        TextFormField(
          controller: _alturaController,
          keyboardType: TextInputType.number,
          style: GoogleFonts.inter(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '175',
            prefixIcon: Icon(Icons.height, color: Color(0xFF6C5CE7)),
            suffixText: 'cm',
          ),
        ),
        const SizedBox(height: 25),
        CustomLabel(label: AppLocalizations.of(context)!.currentWeight),
        const SizedBox(height: 8),
        TextFormField(
          controller: _pesoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          style: GoogleFonts.inter(color: Colors.white),
          decoration: const InputDecoration(
            hintText: '75.0',
            prefixIcon: Icon(Icons.monitor_weight_outlined, color: Color(0xFF6C5CE7)),
            suffixText: 'kg',
          ),
        ),
        const SizedBox(height: 35),
        _buildNextButton(AppLocalizations.of(context)!.continueBtn, _nextStep),
        const SizedBox(height: 30),
      ],
    );
  }

  // ── Step 4: Objetivo ────────────────────────────────────────────────────

  Widget _buildStep4() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      key: const ValueKey('step4'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FormSectionHeader(
          title: AppLocalizations.of(context)!.yourObjective,
          subtitle: AppLocalizations.of(context)!.objectiveSubtitle,
        ),
        const SizedBox(height: 30),
        if (_errorMessage != null) _buildError(),
        GoalOptionWidget(
          value: 'perder_peso',
          title: l10n.loseWeight,
          subtitle: l10n.loseWeightDesc,
          icon: Icons.trending_down,
          isSelected: _objetivo == 'perder_peso',
          onTap: () => setState(() => _objetivo = 'perder_peso'),
        ),
        const SizedBox(height: 12),
        GoalOptionWidget(
          value: 'manter',
          title: l10n.maintainWeight,
          subtitle: l10n.maintainWeightDesc,
          icon: Icons.balance,
          isSelected: _objetivo == 'manter',
          onTap: () => setState(() => _objetivo = 'manter'),
        ),
        const SizedBox(height: 12),
        GoalOptionWidget(
          value: 'ganhar_massa',
          title: l10n.gainMass,
          subtitle: l10n.gainMassDesc,
          icon: Icons.trending_up,
          isSelected: _objetivo == 'ganhar_massa',
          onTap: () => setState(() => _objetivo = 'ganhar_massa'),
        ),
        const SizedBox(height: 30),
        CustomLabel(label: l10n.activityLevel),
        const SizedBox(height: 12),
        ActivityLevelSelector(
          currentValue: _nivelAtividade,
          onSelected: (v) => setState(() => _nivelAtividade = v),
        ),
        const SizedBox(height: 35),
        _buildNextButton(
          _isLoading ? l10n.creatingAccount : l10n.createMyAccount,
          _isLoading ? null : _register,
          isPrimary: true,
        ),
        const SizedBox(height: 30),
      ],
    );
  }

  // Helpers

  Widget _buildError() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFD4556).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFD4556).withValues(alpha: 0.3)),
      ),
      child: Text(_errorMessage!, style: GoogleFonts.inter(
        color: const Color(0xFFFD4556), fontSize: 13,
      )),
    );
  }

  Widget _buildNextButton(String label, VoidCallback? onTap, {bool isPrimary = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary
              ? const Color(0xFF6C5CE7)
              : const Color(0xFF6C5CE7).withValues(alpha: 0.8),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: isPrimary ? 4 : 0,
        ),
        child: Text(label, style: GoogleFonts.inter(
          fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white,
        )),
      ),
    );
  }
}
