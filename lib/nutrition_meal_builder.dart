import 'package:flutter/material.dart';
import 'stitch_design_system.dart';

class NutritionMealBuilderDialog extends StatefulWidget {
  const NutritionMealBuilderDialog({
    super.key,
    required this.foods,
    required this.searchFoods,
  });
  final List<Map<String, dynamic>> foods;
  final Future<List<Map<String, dynamic>>> Function(String) searchFoods;

  @override
  State<NutritionMealBuilderDialog> createState() =>
      _NutritionMealBuilderDialogState();
}

class _NutritionMealBuilderDialogState
    extends State<NutritionMealBuilderDialog> {
  final _query = TextEditingController();
  final Map<String, Map<String, dynamic>> _selected = {};
  final List<Map<String, dynamic>> _customFoods = [];
  late List<Map<String, dynamic>> _results = widget.foods;
  bool _loading = false;

  String _normalize(String value) {
    var text = value.toLowerCase();
    const replacements = <int, String>{
      0xe1: 'a',
      0xe0: 'a',
      0xe3: 'a',
      0xe2: 'a',
      0xe4: 'a',
      0xe9: 'e',
      0xe8: 'e',
      0xea: 'e',
      0xeb: 'e',
      0xed: 'i',
      0xec: 'i',
      0xee: 'i',
      0xef: 'i',
      0xf3: 'o',
      0xf2: 'o',
      0xf5: 'o',
      0xf4: 'o',
      0xf6: 'o',
      0xfa: 'u',
      0xf9: 'u',
      0xfb: 'u',
      0xfc: 'u',
      0xe7: 'c',
    };
    for (final entry in replacements.entries) {
      text = text.replaceAll(String.fromCharCode(entry.key), entry.value);
    }
    return text;
  }

  double _n(dynamic value) =>
      value is num ? value.toDouble() : double.tryParse(value.toString()) ?? 0;

  String _id(Map<String, dynamic> food) =>
      (food['id'] ?? food['_localId'] ?? food['name'] ?? '').toString();

  String _unit(Map<String, dynamic> food) {
    final value = (food['servingUnit'] ?? 'g').toString().trim().toLowerCase();
    return switch (value) {
      'unit' || 'units' || 'un' || 'un.' || 'unidade' => 'unidade',
      'ml' || 'milliliter' || 'milliliters' => 'ml',
      'kg' => 'kg',
      'portion' || 'porcao' || 'porção' => 'porção',
      '' => 'g',
      _ => value,
    };
  }

  String _formatNumber(double value, {int decimals = 1}) =>
      value.toStringAsFixed(decimals).replaceFirst(RegExp(r'\.0+$'), '');

  String _portionLabel(double amount) =>
      '${_formatNumber(amount, decimals: 2)} ${amount == 1 ? 'porção' : 'porções'}';

  void _filter(String value) {
    final query = _normalize(value.trim());
    final local = [...widget.foods, ..._customFoods].where((food) {
      final name = _normalize((food['name'] ?? '').toString());
      final aliases = _normalize((food['aliases'] ?? '').toString());
      final category = _normalize((food['category'] ?? '').toString());
      return query.isEmpty ||
          name.contains(query) ||
          aliases.contains(query) ||
          category.contains(query);
    }).toList();
    setState(() {
      _results = local;
      _loading = query.isNotEmpty && local.isEmpty;
    });
    if (query.isNotEmpty && local.isEmpty) {
      widget
          .searchFoods(value.trim())
          .then((items) {
            if (!mounted || _normalize(_query.text.trim()) != query) return;
            setState(() {
              _results = items;
              _loading = false;
            });
          })
          .catchError((_) {
            if (mounted) setState(() => _loading = false);
          });
    }
  }

  Future<void> _createCustomFood() async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final serving = TextEditingController(text: '100');
    final calories = TextEditingController(text: '0');
    final protein = TextEditingController(text: '0');
    final carbs = TextEditingController(text: '0');
    final fat = TextEditingController(text: '0');
    var unit = 'g';
    var category = 'other';
    final food = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (dialogContext, updateDialog) => AlertDialog(
          backgroundColor: stitchSurface,
          title: const Text('Adicionar outro alimento'),
          content: SizedBox(
            width: 440,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: name,
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Nome do alimento',
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? 'Informe o nome do alimento.'
                          : null,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _numberInput(
                            'Porção',
                            serving,
                            positive: true,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: unit,
                            decoration: const InputDecoration(
                              labelText: 'Unidade',
                            ),
                            items: const [
                              DropdownMenuItem(value: 'g', child: Text('g')),
                              DropdownMenuItem(value: 'ml', child: Text('ml')),
                              DropdownMenuItem(
                                value: 'unit',
                                child: Text('unidade'),
                              ),
                            ],
                            onChanged: (value) =>
                                updateDialog(() => unit = value ?? 'g'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: const [
                        DropdownMenuItem(value: 'other', child: Text('Outro')),
                        DropdownMenuItem(
                          value: 'meat',
                          child: Text('Carne ou proteína'),
                        ),
                        DropdownMenuItem(
                          value: 'grain',
                          child: Text('Grãos e cereais'),
                        ),
                        DropdownMenuItem(
                          value: 'vegetable',
                          child: Text('Verduras e legumes'),
                        ),
                        DropdownMenuItem(value: 'fruit', child: Text('Fruta')),
                        DropdownMenuItem(
                          value: 'dairy',
                          child: Text('Laticínios'),
                        ),
                      ],
                      onChanged: (value) =>
                          updateDialog(() => category = value ?? 'other'),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: _numberInput('Calorias (kcal)', calories),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _numberInput('Proteína (g)', protein)),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: _numberInput('Carboidratos (g)', carbs),
                        ),
                        const SizedBox(width: 8),
                        Expanded(child: _numberInput('Gorduras (g)', fat)),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton.icon(
              onPressed: () {
                if (formKey.currentState?.validate() != true) return;
                double number(TextEditingController controller) =>
                    double.parse(controller.text.replaceAll(',', '.'));
                Navigator.pop(dialogContext, {
                  '_localId': 'custom-${DateTime.now().microsecondsSinceEpoch}',
                  'name': name.text.trim(),
                  'servingSize': number(serving),
                  'servingUnit': unit,
                  'category': category,
                  'calories': number(calories),
                  'proteinG': number(protein),
                  'carbsG': number(carbs),
                  'fatG': number(fat),
                });
              },
              icon: const Icon(Icons.add),
              label: const Text('Adicionar ao prato'),
            ),
          ],
        ),
      ),
    );
    for (final controller in [name, serving, calories, protein, carbs, fat]) {
      controller.dispose();
    }
    if (food == null || !mounted) return;
    final id = _id(food);
    setState(() {
      _customFoods.insert(0, food);
      _results = [..._customFoods, ...widget.foods];
      _selected[id] = {'food': food, 'amount': 1.0};
      _query.clear();
    });
  }

  Widget _numberInput(
    String label,
    TextEditingController controller, {
    bool positive = false,
  }) => TextFormField(
    controller: controller,
    keyboardType: const TextInputType.numberWithOptions(decimal: true),
    decoration: InputDecoration(labelText: label),
    validator: (value) {
      final number = double.tryParse((value ?? '').replaceAll(',', '.'));
      return number == null || (positive ? number <= 0 : number < 0)
          ? positive
                ? 'Use um valor acima de zero.'
                : 'Informe zero ou mais.'
          : null;
    },
  );

  void _toggle(Map<String, dynamic> food) {
    final id = _id(food);
    setState(() {
      if (_selected.containsKey(id)) {
        _selected.remove(id);
      } else {
        _selected[id] = {'food': food, 'amount': 1.0};
      }
    });
  }

  void _changeAmount(String id, double delta) {
    final row = _selected[id];
    if (row == null) return;
    final next = (_n(row['amount']) + delta).clamp(0.25, 30.0);
    setState(() => row['amount'] = next);
  }

  double _total(String key) => _selected.values.fold<double>(0, (sum, row) {
    final food = Map<String, dynamic>.from(row['food'] as Map);
    return sum + _n(food[key]) * _n(row['amount']);
  });

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return Dialog(
      backgroundColor: stitchSurface,
      insetPadding: const EdgeInsets.all(16),
      child: SizedBox(
        width: size.width > 1000 ? 920 : size.width - 32,
        height: size.height > 760 ? 680 : size.height - 32,
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Icon(Icons.restaurant_menu, color: stitchOrange),
                  const SizedBox(width: 8),
                  const Expanded(
                    child: Text(
                      'Monte seu prato',
                      style: TextStyle(
                        color: stitchText,
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const Text(
                'Busque vários alimentos, ajuste as porções e acompanhe os nutrientes.',
                style: TextStyle(color: stitchMuted, fontSize: 12),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _query,
                onChanged: _filter,
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search),
                  hintText: 'Ex.: carne, feijão, arroz, tomate',
                  suffixIcon: _query.text.isEmpty
                      ? null
                      : IconButton(
                          onPressed: () {
                            _query.clear();
                            _filter('');
                          },
                          icon: const Icon(Icons.clear),
                        ),
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final list = _foodList();
                    final plate = _plateList();
                    if (constraints.maxWidth < 600) {
                      return Column(
                        children: [
                          Expanded(flex: 6, child: list),
                          const SizedBox(height: 10),
                          Expanded(flex: 5, child: plate),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(flex: 6, child: list),
                        const SizedBox(width: 12),
                        Expanded(flex: 5, child: plate),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _macro('Energia', _total('calories'), 'kcal'),
                  _macro('Proteínas', _total('proteinG'), 'g'),
                  _macro('Carboidratos', _total('carbsG'), 'g'),
                  _macro('Gorduras', _total('fatG'), 'g'),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _selected.isEmpty
                        ? null
                        : () => Navigator.pop(
                            context,
                            _selected.values
                                .map(
                                  (row) => <String, dynamic>{
                                    'food': row['food'],
                                    'amount': row['amount'],
                                  },
                                )
                                .toList(),
                          ),
                    icon: const Icon(Icons.check),
                    label: Text('Adicionar ' + _selected.length.toString()),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _foodList() => _panel(
    'Alimentos sugeridos',
    Column(
      children: [
        Expanded(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: stitchOrange),
                )
              : _results.isEmpty
              ? const Center(
                  child: Text(
                    'Nenhum alimento encontrado. Adicione uma alternativa.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: stitchMuted),
                  ),
                )
              : ListView.builder(
                  itemCount: _results.length,
                  itemBuilder: (context, index) {
                    final food = _results[index];
                    final id = _id(food);
                    final selected = _selected.containsKey(id);
                    final serving = _n(food['servingSize']);
                    final servingText = _formatNumber(serving);
                    return ListTile(
                      dense: true,
                      title: Text(
                        (food['name'] ?? '').toString(),
                        style: const TextStyle(
                          color: stitchText,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        'Porção: $servingText ${_unit(food)} • ${_n(food['calories']).round()} kcal',
                        style: const TextStyle(
                          color: stitchMuted,
                          fontSize: 11,
                        ),
                      ),
                      trailing: Icon(
                        selected
                            ? Icons.check_circle
                            : Icons.add_circle_outline,
                        color: stitchOrange,
                      ),
                      onTap: () => _toggle(food),
                    );
                  },
                ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(10, 0, 10, 10),
          child: OutlinedButton.icon(
            onPressed: _createCustomFood,
            icon: const Icon(Icons.add, size: 17),
            label: const Text('ADICIONAR OUTRO ALIMENTO'),
          ),
        ),
      ],
    ),
  );

  Widget _plateList() => _panel(
    'No prato (' + _selected.length.toString() + ')',
    _selected.isEmpty
        ? const Center(
            child: Text(
              'Toque nos alimentos para montar a refeição.',
              style: TextStyle(color: stitchMuted),
            ),
          )
        : ListView(
            children: _selected.entries.map((entry) {
              final food = Map<String, dynamic>.from(
                entry.value['food'] as Map,
              );
              final amount = _n(entry.value['amount']);
              final serving = _n(food['servingSize']) * amount;
              final calories = (_n(food['calories']) * amount).round();
              final portionDetails = <String>[
                _portionLabel(amount),
                if (serving > 0)
                  '${_formatNumber(serving, decimals: 2)} ${_unit(food)}',
                '$calories kcal',
              ];
              return ListTile(
                dense: true,
                title: Text(
                  (food['name'] ?? '').toString(),
                  style: const TextStyle(color: stitchText, fontSize: 12),
                ),
                subtitle: Text(
                  portionDetails.join(' • '),
                  style: const TextStyle(color: stitchMuted, fontSize: 11),
                ),
                leading: IconButton(
                  onPressed: () => _changeAmount(entry.key, -0.25),
                  icon: const Icon(
                    Icons.remove_circle_outline,
                    color: stitchOrange,
                  ),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      onPressed: () => _changeAmount(entry.key, 0.25),
                      icon: const Icon(
                        Icons.add_circle_outline,
                        color: stitchOrange,
                      ),
                    ),
                    IconButton(
                      onPressed: () => _toggle(food),
                      icon: const Icon(
                        Icons.delete_outline,
                        color: stitchMuted,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
  );

  Widget _panel(String title, Widget child) => Container(
    decoration: BoxDecoration(
      color: stitchSurfaceLow,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            title,
            style: const TextStyle(
              color: stitchText,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        Expanded(child: child),
      ],
    ),
  );

  Widget _macro(String label, double value, String unit) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
    decoration: BoxDecoration(
      color: stitchSurfaceLow,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(
      label + ': ' + value.round().toString() + ' ' + unit,
      style: const TextStyle(color: stitchText, fontSize: 11),
    ),
  );
}
