import 'package:flutter/material.dart';

class ScenarioSelector extends StatefulWidget {
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
  State<ScenarioSelector> createState() => _ScenarioSelectorState();
}

class _ScenarioSelectorState extends State<ScenarioSelector> {
  final TextEditingController _customScenarioController = TextEditingController();
  static const String customScenarioKey = "Custom";

  @override
  void dispose() {
    _customScenarioController.dispose();
    super.dispose();
  }

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
            children: [
              ...widget.scenarios.map((scenario) {
                final selected = widget.selectedScenario == scenario;
                return GestureDetector(
                  onTap: () {
                    widget.onScenarioChanged(selected ? null : scenario);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                    decoration: BoxDecoration(
                      color: selected
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(8.0),
                      border: Border.all(
                        color: selected
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey,
                      ),
                    ),
                    child: Text(
                      scenario,
                      softWrap: true,
                      maxLines: null,
                      style: TextStyle(
                        color: selected
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ),
                );
              }).toList(),
              // Custom scenario option
              GestureDetector(
                onTap: () {
                  final isCustomSelected = widget.selectedScenario == customScenarioKey;
                  widget.onScenarioChanged(isCustomSelected ? null : customScenarioKey);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                  decoration: BoxDecoration(
                    color: widget.selectedScenario == customScenarioKey
                        ? Theme.of(context).colorScheme.primaryContainer
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(8.0),
                    border: Border.all(
                      color: widget.selectedScenario == customScenarioKey
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey,
                    ),
                  ),
                  child: Text(
                    customScenarioKey,
                    softWrap: true,
                    maxLines: null,
                    style: TextStyle(
                      color: widget.selectedScenario == customScenarioKey
                          ? Theme.of(context).colorScheme.onPrimaryContainer
                          : Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
          ),
          // Custom scenario input field
          if (widget.selectedScenario == customScenarioKey) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _customScenarioController,
              decoration: const InputDecoration(
                labelText: "Enter your custom scenario",
                hintText: "Describe your negotiation scenario...",
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 8),
            ElevatedButton(
              onPressed: () {
                final customText = _customScenarioController.text.trim();
                if (customText.isNotEmpty) {
                  widget.onContextChanged(customText);
                }
              },
              child: const Text("Use This Scenario"),
            ),
          ],
          const SizedBox(height: 16),
        ],
      ),
    );
  }
} 