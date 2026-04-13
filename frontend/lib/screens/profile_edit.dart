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
    };

    final result = await api.updateProfile(data);

    if (mounted) {
      setState(() => _isSubmitting = false);
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil atualizado com sucesso!'),
            backgroundColor: Color(0xFF2ED573),
          ),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['error'] ?? 'Erro ao atualizar perfil'),
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
        title: const Text('Editar Perfil'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FormSectionHeader(
                title: 'Informações Pessoais', // Use l10n if available, or keep if consistent
                subtitle: 'Mantenha seus dados atualizados para melhores resultados.',
              ),

              // Nome
              CustomLabel(label: l10n.fullName),
              TextFormField(
                controller: _nomeController,
                decoration: const InputDecoration(hintText: 'Ex: João Silva'),
                validator: (v) => v == null || v.isEmpty ? 'Informe seu nome' : null,
              ),
              const SizedBox(height: 20),

              // Idade
              CustomLabel(label: l10n.age),
              TextFormField(
                controller: _idadeController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ex: 25'),
                validator: (v) => v == null || v.isEmpty ? 'Informe sua idade' : null,
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
                          decoration: const InputDecoration(hintText: 'Ex: 175'),
                          validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
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
                          decoration: const InputDecoration(hintText: 'Ex: 70.5'),
                          validator: (v) => v == null || v.isEmpty ? 'Obrigatório' : null,
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
                title: 'Localização e Finanças',
                subtitle: 'Esses dados ajudam a IA a sugerir alimentos com melhor custo-benefício na sua região.',
              ),

              Row(
                children: [
                   Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CustomLabel(label: l10n.state),
                        TextFormField(
                          controller: _estadoController,
                          decoration: const InputDecoration(hintText: 'Ex: SP'),
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
                          decoration: const InputDecoration(hintText: 'Ex: São Paulo'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              CustomLabel(label: l10n.monthlyIncome),
              TextFormField(
                controller: _rendaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Ex: 3500.00'),
              ),
              const SizedBox(height: 20),
              CustomLabel(label: l10n.dietBudget),
              TextFormField(
                controller: _orcamentoDietaController,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(hintText: 'Quanto pode gastar com a dieta?'),
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
                    : const Text('SALVAR ALTERAÇÕES'),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
