import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shapepro/l10n/app_localizations.dart';

class FormSectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;

  const FormSectionHeader({
    super.key,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 35),
        Text(title, style: GoogleFonts.inter(
          fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white,
        )),
        const SizedBox(height: 8),
        Text(subtitle, style: GoogleFonts.inter(
          fontSize: 15, color: Colors.white54,
        )),
        const SizedBox(height: 35),
      ],
    );
  }
}

class CustomLabel extends StatelessWidget {
  final String label;
  const CustomLabel({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 8),
      child: Text(label, style: GoogleFonts.inter(
        fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white70,
      )),
    );
  }
}

class SexOptionWidget extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const SexOptionWidget({
    super.key,
    required this.value,
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.15) : const Color(0xFF1E1E38),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF2A2A4A),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF6C5CE7) : Colors.white54, size: 30),
              const SizedBox(height: 8),
              Text(label, style: GoogleFonts.inter(
                color: isSelected ? Colors.white : Colors.white54,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              )),
            ],
          ),
        ),
      ),
    );
  }
}

class GoalOptionWidget extends StatelessWidget {
  final String value;
  final String title;
  final String subtitle;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const GoalOptionWidget({
    super.key,
    required this.value,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.12) : const Color(0xFF1E1E38),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? const Color(0xFF6C5CE7) : const Color(0xFF2A2A4A),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF6C5CE7).withValues(alpha: 0.2) : const Color(0xFF2A2A4A),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: isSelected ? const Color(0xFF6C5CE7) : Colors.white54),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: isSelected ? Colors.white : Colors.white70,
                    fontSize: 15,
                  )),
                  const SizedBox(height: 3),
                  Text(subtitle, style: GoogleFonts.inter(
                    color: Colors.white38, fontSize: 12,
                  )),
                ],
              ),
            ),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF6C5CE7)),
          ],
        ),
      ),
    );
  }
}

class ActivityLevelSelector extends StatelessWidget {
  final String currentValue;
  final Function(String) onSelected;

  const ActivityLevelSelector({
    super.key,
    required this.currentValue,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final niveis = [
      {'value': 'sedentario', 'label': l10n.sedentary, 'desc': l10n.sedentaryDesc},
      {'value': 'leve', 'label': l10n.light, 'desc': l10n.lightDesc},
      {'value': 'moderado', 'label': l10n.moderate, 'desc': l10n.moderateDesc},
      {'value': 'intenso', 'label': l10n.intense, 'desc': l10n.intenseDesc},
      {'value': 'muito_intenso', 'label': l10n.veryIntense, 'desc': l10n.veryIntenseDesc},
    ];

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: niveis.map((n) {
        final selected = currentValue == n['value'];
        return GestureDetector(
          onTap: () => onSelected(n['value']!),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: selected ? const Color(0xFF6C5CE7).withValues(alpha: 0.15) : const Color(0xFF1E1E38),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected ? const Color(0xFF6C5CE7) : const Color(0xFF2A2A4A),
              ),
            ),
            child: Column(
              children: [
                Text(n['label']!, style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  color: selected ? Colors.white : Colors.white60,
                )),
                Text(n['desc']!, style: GoogleFonts.inter(
                  fontSize: 10, color: Colors.white30,
                )),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class CountryCodeSelector extends StatelessWidget {
  final String selectedCountryId;
  final Function(String) onChanged;

  const CountryCodeSelector({
    super.key,
    required this.selectedCountryId,
    required this.onChanged,
  });

  static final List<Map<String, String>> countries = [
    {'id': 'BR', 'code': '+55', 'flag': '🇧🇷', 'name': 'Brasil'},
    {'id': 'US', 'code': '+1', 'flag': '🇺🇸', 'name': 'Estados Unidos'},
    {'id': 'CA', 'code': '+1', 'flag': '🇨🇦', 'name': 'Canadá'},
    {'id': 'UK', 'code': '+44', 'flag': '🇬🇧', 'name': 'Reino Unido'},
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E38),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF2A2A4A)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedCountryId,
          dropdownColor: const Color(0xFF1E1E38),
          icon: const Icon(Icons.arrow_drop_down, color: Colors.white54),
          onChanged: (String? newValue) {
            if (newValue != null) {
              onChanged(newValue);
            }
          },
          items: countries.map<DropdownMenuItem<String>>((Map<String, String> country) {
            return DropdownMenuItem<String>(
              value: country['id'],
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(country['flag']!, style: const TextStyle(fontSize: 20)),
                  const SizedBox(width: 8),
                  Text(country['code']!, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
