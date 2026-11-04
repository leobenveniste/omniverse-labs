import 'package:flutter/material.dart';
import '../../models/user_model.dart';
import '../../theme/app_theme.dart';
import '../../widgets/async_feedback_components.dart';
import '../../l10n/app_localizations.dart';

class DiscoveryFiltersSheet extends StatefulWidget {
  final String? initialRegion;
  final RangeValues initialAgeRange;
  final ValueChanged<DiscoveryFilterResult> onApply;

  const DiscoveryFiltersSheet({
    super.key,
    this.initialRegion,
    this.initialAgeRange = const RangeValues(18, 55),
    required this.onApply,
  });

  @override
  State<DiscoveryFiltersSheet> createState() => _DiscoveryFiltersSheetState();
}

class DiscoveryFilterResult {
  final String? region;
  final int minAge;
  final int maxAge;

  const DiscoveryFilterResult({
    this.region,
    required this.minAge,
    required this.maxAge,
  });
}

class _DiscoveryFiltersSheetState extends State<DiscoveryFiltersSheet> {
  late String _region;
  late RangeValues _ageRange;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _region = widget.initialRegion ?? AppRegions.allRegions;
    _ageRange = widget.initialAgeRange;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final textPrimary = AppTheme.textPrimaryColor(context);

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Filtros de Búsqueda',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Región
          Text(
            l10n.get('regionLabel'),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _region,
            decoration: const InputDecoration(),
            items: [
              DropdownMenuItem(
                value: AppRegions.allRegions,
                child: Text(l10n.get('allRegions')),
              ),
              ...AppRegions.all.map((r) {
                return DropdownMenuItem(value: r, child: Text(r));
              }),
            ],
            onChanged: (val) {
              if (val != null) setState(() => _region = val);
            },
          ),
          const SizedBox(height: 20),

          // Rango de Edad
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Rango de edad:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Text(
                '${_ageRange.start.round()} - ${_ageRange.end.round()} años',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor(context),
                ),
              ),
            ],
          ),
          RangeSlider(
            values: _ageRange,
            min: 18,
            max: 65,
            divisions: 47,
            activeColor: AppTheme.primaryColor(context),
            onChanged: (vals) => setState(() => _ageRange = vals),
          ),
          const SizedBox(height: 24),

          LoadingPrimaryButton(
            label: 'Aplicar filtros',
            isLoading: _isSaving,
            onPressed: () {
              setState(() => _isSaving = true);
              widget.onApply(DiscoveryFilterResult(
                region: _region == AppRegions.allRegions ? null : _region,
                minAge: _ageRange.start.round(),
                maxAge: _ageRange.end.round(),
              ));
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}
