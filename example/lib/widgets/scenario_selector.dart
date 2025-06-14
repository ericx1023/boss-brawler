import 'package:flutter/material.dart';

class ScenarioSelector extends StatelessWidget {
  final List<String> scenarios;
  final String? selectedScenario;
  final ValueChanged<String?> onScenarioChanged;
  final ValueChanged<String> onContextChanged;

  const ScenarioSelector({
    Key? key,
    required this.scenarios,
    this.selectedScenario,
    required this.onScenarioChanged,
    required this.onContextChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Select a negotiation scenario:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            runSpacing: 4.0,
            children: scenarios.map((scenario) {
              final selected = selectedScenario == scenario;
              return ChoiceChip(
                label: Text(scenario, softWrap: true, overflow: TextOverflow.visible),
                selected: selected,
                onSelected: (newSelected) {
                  onScenarioChanged(newSelected ? scenario : null);
                },
                labelPadding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                selectedColor: Theme.of(context).colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  color: selected
                      ? Theme.of(context).colorScheme.onPrimaryContainer
                      : Theme.of(context).colorScheme.onSurface,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8.0),
                  side: BorderSide(
                    color: selected
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 