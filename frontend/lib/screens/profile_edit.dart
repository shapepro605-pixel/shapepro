import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shapepro/l10n/app_localizations.dart';
import '../services/api.dart';
import '../widgets/form_fields.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nomeController;
  late TextEditingController _idadeController;
  late TextEditingController _alturaController;
  late TextEditingController _pesoController;
  String? _sexo;
  String? _objetivo;
  String? _nivelAtividade;
  late TextEditingController _estadoController;
  late TextEditingController _cidadeController;
  late TextEditingController _rendaController;
  late TextEditingController _orcamentoDietaController;
  String? _pais;
  String? _moeda;

  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    final user = Provider.of<ApiService>(context, listen: false).currentUser ?? {};
    _nomeController = TextEditingController(text: user['nome'] ?? '');
    _idadeController = TextEditingController(text: user['idade']?.toString() ?? '');
    _alturaController = TextEditingController(text: user['altura']?.toString() ?? '');
    _pesoController = TextEditingController(text: user['peso']?.toString() ?? '');
    _sexo = user['sexo'];
    _objetivo = user['objetivo'];
    _nivelAtividade = user['nivel_atividade'];
    _estadoController = TextEditingController(text: user['estado'] ?? '');
    _cidadeController = TextEditingController(text: user['cidade'] ?? '');
    _rendaController = TextEditingController(text: user['renda_mensal']?.toString() ?? '');
    _orcamentoDietaController = TextEditingController(text: user['orcamento_dieta']?.toString() ?? '');
    _pais = user['pais'] ?? 'BR';
    _moeda = user['moeda'] ?? 'BRL';
  }

  @override
  void dispose() {
    _nomeController.dispose();
    _idadeController.dispose();
    _alturaController.dispose();
    _pesoController.dispose();
    _estadoController.dispose();
    _cidadeController.dispose();
    _rendaController.dispose();
    _orcamentoDietaController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final l10n = AppLocalizations.of(context)!;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final api = Provider.of<ApiService>(context, listen: false);
    final data = {
      'nome': _nomeController.text.trim(),
      'idade': int.tryParse(_idadeController.text),
      'altura': double.tryParse(_alturaController.text),
      'peso': double.tryParse(_pesoController.text),
      'sexo': _sexo,
      'objetivo': _objetivo,
      'nivel_atividade': _nivelAtividade,
      'estado': _estadoController.text.trim(),
      'cidade': _cidadeController.text.trim(),
      'renda_mensal': double.tryParse(_rendaController.text.trim()),
      'orcamento_dieta': double.tryParse(_orcamentoDietaController.text.trim()),
      'pais': _pais,
      'moeda': _moeda,
      'estado': _estadoController.text.trim(),
      'cidade': _cidadeController.text.trim(),
    };

    final result = await api.updateProfile(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(l10n.profileUpdateSuccess),
            backgroundColor: const Color(0xFF2ED573),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? l10n.profileUpdateError),
            backgroundColor: const Color(0xFFFD4556),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.editProfile),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormSectionHeader(
                title: l10n.personalInfo,
                subtitle: l10n.profileIncompleteDesc,
              ),

              // Nome
              CustomLabel(label: l10n.fullName),
              TextFormField(
                controller: _nomeController,
                decoration: InputDecoration(hintText: l10n.yourName),
                validator: (v) => v == null || v.isEmpty ? l10n.fillAllFields : null,
              ),
              const SizedBox(height: 20),

              // Idade
              CustomLabel(label: l10n.age),
              TextFormField(
                controller: _idadeController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: l10n.ageHint),
                validator: (v) => v == null || v.isEmpty ? l10n.fillAllFields : null,
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                  // Altura
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomLabel(label: '${l10n.altura} (cm)'),
                        TextFormField(
                          controller: _alturaController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: l10n.heightHint),
                          validator: (v) => v == null || v.isEmpty ? l10n.mandatory : null,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Peso
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomLabel(label: '${l10n.peso} (kg)'),
                        TextFormField(
                          controller: _pesoController,
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(hintText: l10n.weightHint),
                          validator: (v) => v == null || v.isEmpty ? l10n.mandatory : null,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomLabel(label: l10n.biologicalSex),
              const SizedBox(height: 12),
              Row(
                children: [
                  SexOptionWidget(
                    value: 'M',
                    label: l10n.male,
                    icon: Icons.male,
                    isSelected: _sexo == 'M',
                    onTap: () => setState(() => _sexo = 'M'),
                  ),
                  const SizedBox(width: 14),
                  SexOptionWidget(
                    value: 'F',
                    label: l10n.female,
                    icon: Icons.female,
                    isSelected: _sexo == 'F',
                    onTap: () => setState(() => _sexo = 'F'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Objetivo
              const SizedBox(height: 20),
              CustomLabel(label: l10n.yourObjective),
              const SizedBox(height: 12),
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

              const SizedBox(height: 32),
              FormSectionHeader(
                title: l10n.locationAndFinance,
                subtitle: l10n.locationAndFinanceSubtitle,              ),

              // País
              CustomLabel(label: l10n.country),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _pais,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                items: [
                  DropdownMenuItem(value: 'BR', child: Text('🇧🇷 ${l10n.brazil}')),
                  DropdownMenuItem(value: 'US', child: Text('🇺🇸 ${l10n.usa}')),
                  DropdownMenuItem(value: 'CA', child: Text('🇨🇦 ${l10n.canada}')),
                  DropdownMenuItem(value: 'GB', child: Text('🇬🇧 ${l10n.uk}')),
                ],
                onChanged: (val) {
                  if (val != null) {
                    setState(() {
                      _pais = val;
                      // Atualiza moeda automaticamente
                      if (val == 'BR') _moeda = 'BRL';
                      else if (val == 'US') _moeda = 'USD';
                      else if (val == 'CA') _moeda = 'CAD';
                      else if (val == 'GB') _moeda = 'GBP';
                    });
                  }
                },
              ),
              const SizedBox(height: 20),

              Row(
                children: [
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomLabel(label: l10n.state),
                        TextFormField(
                          controller: _estadoController,
                          decoration: InputDecoration(hintText: l10n.stateHint),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomLabel(label: l10n.city),
                        TextFormField(
                          controller: _cidadeController,
                          decoration: InputDecoration(hintText: l10n.cityHint),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomLabel(label: l10n.monthlyIncome(_moeda ?? 'BRL')),
              TextFormField(
                controller: _rendaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: l10n.incomeHint),
              ),
              const SizedBox(height: 20),
              CustomLabel(label: l10n.dietBudget(_moeda ?? 'BRL')),
              TextFormField(
                controller: _orcamentoDietaController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(hintText: l10n.budgetHint),
              ),
              const SizedBox(height: 20),
              const SizedBox(height: 20),

              // Nível de Atividade
              const SizedBox(height: 20),
              CustomLabel(label: l10n.activityLevel),
              const SizedBox(height: 12),
              ActivityLevelSelector(
                currentValue: _nivelAtividade ?? 'moderado',
                onSelected: (v) => setState(() => _nivelAtividade = v),
              ),
              const SizedBox(height: 40),

              // Botão Salvar
              ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                child: _isSubmitting
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(l10n.saveChanges),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
